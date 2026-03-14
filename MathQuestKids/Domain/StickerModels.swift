import Foundation
import SwiftUI

struct Sticker: Identifiable, Equatable {
    let unitType: UnitType
    let dateEarned: Date?   // nil = locked

    var id: String { unitType.rawValue }
    var isUnlocked: Bool { dateEarned != nil }

    var title: String { unitType.title + " Sticker" }

    /// Returns the asset catalog name for this sticker in the given theme.
    func imageName(for theme: VisualTheme) -> String {
        let prefix = theme.stickerPrefix
        let index = stickerIndex(for: unitType)
        return String(format: "%@Sticker%02d", prefix, index)
    }
}

// MARK: - Theme → asset prefix mapping

private extension VisualTheme {
    var stickerPrefix: String {
        switch self {
        case .candyland:      return "Candy"
        case .axolotl:        return "Ocean"
        case .rainbowUnicorn: return "Rainbow"
        case .starsSpace:     return "Space"
        case .superhero:      return "Hero"
        case .turboCars:      return "Turbo"
        }
    }
}

// MARK: - Unit → sticker index (1-based, matching asset catalog)
// Each unit gets a unique sticker image from its theme's sheet.

private func stickerIndex(for unit: UnitType) -> Int {
    switch unit {
    case .kCountObjects:        return 1
    case .kComposeDecompose:    return 2
    case .kAddWithin5:          return 3
    case .kAddWithin10:         return 4
    case .g1AddWithin20:        return 5
    case .g1FactFamilies:       return 6
    case .g2AddWithin100:       return 7
    case .g2SubWithin100:       return 8
    case .subtractionStories:   return 9
    case .teenPlaceValue:       return 10
    case .twoDigitComparison:   return 11
    case .threeDigitComparison: return 12
    case .multiplicationArrays: return 13
    case .fractionComparison:   return 14
    case .fractionOfWhole:      return 15
    case .volumeAndDecimals:    return 16
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
