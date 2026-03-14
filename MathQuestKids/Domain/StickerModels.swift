import Foundation
import SwiftUI

struct Sticker: Identifiable, Equatable {
    let unitType: UnitType
    let dateEarned: Date?   // nil = locked

    var id: String { unitType.rawValue }
    var isUnlocked: Bool { dateEarned != nil }

    var title: String { unitType.title + " Sticker" }

    func icon(for theme: VisualTheme) -> StickerIcon {
        StickerIcon.icon(for: unitType, theme: theme)
    }
}

struct StickerIcon: Equatable {
    /// Asset catalog image name (e.g. "CandySticker01", "OceanSticker12")
    let imageName: String

    /// Maps a unit + theme to the correct HD sticker asset.
    /// Sticker number = unit's position in the learning path (1-based).
    /// Theme determines the asset prefix.
    static func icon(for unit: UnitType, theme: VisualTheme) -> StickerIcon {
        let index = UnitType.learningPath.firstIndex(of: unit) ?? 0
        let number = String(format: "%02d", index + 1)
        let prefix = theme.stickerPrefix
        return StickerIcon(imageName: "\(prefix)\(number)")
    }
}

extension VisualTheme {
    /// Asset catalog prefix for each theme's HD sticker pack.
    var stickerPrefix: String {
        switch self {
        case .candyland:      return "CandySticker"
        case .axolotl:        return "OceanSticker"
        case .rainbowUnicorn: return "RainbowSticker"
        case .starsSpace:     return "SpaceSticker"
        case .superhero:      return "HeroSticker"
        case .turboCars:      return "TurboSticker"
        }
    }
}

struct StickerCollection: Equatable {
    let stickers: [Sticker]

    static func build(from records: [CDStickerRecord]) -> StickerCollection {
        let earnedByUnit = Dictionary(
            uniqueKeysWithValues: records.map { ($0.unitRaw, $0.dateEarned) }
        )
        let stickers = UnitType.learningPath.map { unit in
            Sticker(unitType: unit, dateEarned: earnedByUnit[unit.rawValue])
        }
        return StickerCollection(stickers: stickers)
    }

    var earnedCount: Int { stickers.filter(\.isUnlocked).count }
    var totalCount: Int { stickers.count }
}
