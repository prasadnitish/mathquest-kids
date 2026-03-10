import SwiftUI

enum VisualTheme: String, CaseIterable, Identifiable {
    case candyland
    case axolotl
    case rainbowUnicorn
    case starsSpace

    static let storageKey = "mathquest.selectedTheme"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .candyland: return "Candyland"
        case .axolotl: return "Axolotl Lagoon"
        case .rainbowUnicorn: return "Rainbow Unicorn"
        case .starsSpace: return "Stars and Space"
        }
    }

    var primary: Color {
        switch self {
        case .candyland: return Color(red: 0.86, green: 0.28, blue: 0.57)
        case .axolotl: return Color(red: 0.16, green: 0.54, blue: 0.63)
        case .rainbowUnicorn: return Color(red: 0.56, green: 0.34, blue: 0.88)
        case .starsSpace: return Color(red: 0.25, green: 0.30, blue: 0.74)
        }
    }

    var accent: Color {
        switch self {
        case .candyland: return Color(red: 1.00, green: 0.77, blue: 0.36)
        case .axolotl: return Color(red: 1.00, green: 0.58, blue: 0.72)
        case .rainbowUnicorn: return Color(red: 0.97, green: 0.51, blue: 0.70)
        case .starsSpace: return Color(red: 0.48, green: 0.90, blue: 0.94)
        }
    }

    var onPrimaryText: Color {
        switch self {
        case .candyland:
            return AppTheme.textPrimary
        case .axolotl, .rainbowUnicorn, .starsSpace:
            return .white
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .candyland:
            return LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.77, blue: 0.89),
                    Color(red: 1.00, green: 0.87, blue: 0.67),
                    Color(red: 1.00, green: 0.68, blue: 0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .axolotl:
            return LinearGradient(
                colors: [
                    Color(red: 0.73, green: 0.93, blue: 0.97),
                    Color(red: 0.62, green: 0.85, blue: 0.94),
                    Color(red: 0.49, green: 0.74, blue: 0.89)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .rainbowUnicorn:
            return LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.82, blue: 0.92),
                    Color(red: 0.78, green: 0.90, blue: 1.00),
                    Color(red: 0.93, green: 0.83, blue: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .starsSpace:
            return LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.13, blue: 0.40),
                    Color(red: 0.23, green: 0.24, blue: 0.57),
                    Color(red: 0.38, green: 0.28, blue: 0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var heroSymbol: String {
        switch self {
        case .candyland: return "birthday.cake.fill"
        case .axolotl: return "drop.fill"
        case .rainbowUnicorn: return "rainbow"
        case .starsSpace: return "moon.stars.fill"
        }
    }

    var decorativeSymbols: [String] {
        switch self {
        case .candyland: return ["heart.fill", "sparkles", "star.fill"]
        case .axolotl: return ["fish.fill", "drop.fill", "leaf.fill"]
        case .rainbowUnicorn: return ["star.fill", "sparkles", "cloud.fill"]
        case .starsSpace: return ["star.fill", "sparkles", "moon.fill"]
        }
    }

    var backgroundAssetName: String {
        switch self {
        case .candyland: return "CandylandBackground"
        case .axolotl: return "AxolotlBackground"
        case .rainbowUnicorn: return "RainbowUnicornBackground"
        case .starsSpace: return "StarsSpaceBackground"
        }
    }

    static func loadPersisted() -> VisualTheme {
        guard
            let raw = UserDefaults.standard.string(forKey: storageKey),
            let theme = VisualTheme(rawValue: raw)
        else {
            return .candyland
        }
        return theme
    }

    static func persist(_ theme: VisualTheme) {
        UserDefaults.standard.set(theme.rawValue, forKey: storageKey)
    }
}

enum AppTheme {
    static var card: Color { Color.white.opacity(0.96) }
    static var primary: Color { VisualTheme.loadPersisted().primary }
    static var accent: Color { VisualTheme.loadPersisted().accent }
    static var onPrimaryText: Color { VisualTheme.loadPersisted().onPrimaryText }
    static let error = Color(red: 0.75, green: 0.23, blue: 0.20)
    static let textPrimary = Color(red: 0.08, green: 0.12, blue: 0.15)
    static let textSecondary = Color(red: 0.28, green: 0.32, blue: 0.37)
}
