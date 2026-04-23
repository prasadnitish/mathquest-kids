import SwiftUI

// Maps each existing VisualTheme to the Sproutmath Design System semantic roles.
// See: Sproutmath-handoff/sproutmath/project/Sproutmath Design System.html §Color System.
extension VisualTheme {
    /// Top of the background gradient.
    var bg1: Color {
        switch self {
        case .candyland:      return Color(red: 1.00, green: 0.77, blue: 0.89)
        case .axolotl:        return Color(red: 0.49, green: 0.74, blue: 0.89)
        case .rainbowUnicorn: return Color(red: 0.79, green: 0.70, blue: 0.91)
        case .starsSpace:     return Color(red: 0.12, green: 0.11, blue: 0.29)
        case .superhero:      return Color(red: 0.15, green: 0.15, blue: 0.30)
        case .turboCars:      return Color(red: 0.12, green: 0.12, blue: 0.14)
        }
    }

    /// Bottom of the background gradient.
    var bg2: Color {
        switch self {
        case .candyland:      return Color(red: 1.00, green: 0.68, blue: 0.82)
        case .axolotl:        return Color(red: 0.73, green: 0.93, blue: 0.97)
        case .rainbowUnicorn: return Color(red: 0.91, green: 0.78, blue: 0.94)
        case .starsSpace:     return Color(red: 0.19, green: 0.18, blue: 0.50)
        case .superhero:      return Color(red: 0.60, green: 0.12, blue: 0.12)
        case .turboCars:      return Color(red: 0.78, green: 0.38, blue: 0.04)
        }
    }

    /// Secondary tint of primary; used for subtle highlights.
    var primary2: Color {
        primary.opacity(0.75)
    }

    /// Secondary accent (complements accent). Derived: lift accent toward white.
    var accent2: Color {
        switch self {
        case .candyland:      return Color(red: 0.98, green: 0.57, blue: 0.31)
        case .axolotl:        return Color(red: 0.20, green: 0.83, blue: 0.60)
        case .rainbowUnicorn: return Color(red: 0.98, green: 0.57, blue: 0.19)
        case .starsSpace:     return Color(red: 0.20, green: 0.83, blue: 0.60)
        case .superhero:      return Color(red: 0.98, green: 0.75, blue: 0.14)
        case .turboCars:      return Color(red: 0.20, green: 0.83, blue: 0.60)
        }
    }

    /// Primary action button. Exactly ONE per screen.
    /// Design rule: CTA should contrast with primary. For most worlds we use accent;
    /// for worlds where accent is too close to primary we pick a complementary hue.
    var cta: Color {
        switch self {
        case .candyland, .axolotl, .rainbowUnicorn, .turboCars:
            return accent
        case .starsSpace:
            return Color(red: 0.98, green: 0.75, blue: 0.14)   // warm amber on dark bg
        case .superhero:
            return Color(red: 0.98, green: 0.75, blue: 0.14)
        }
    }

    /// Text color that reads on top of `cta`.
    var ctaText: Color {
        switch self {
        // Light CTAs → dark text.
        case .candyland, .turboCars, .starsSpace, .superhero:
            return AppTheme.textPrimary
        // Saturated CTAs → white.
        case .axolotl, .rainbowUnicorn:
            return .white
        }
    }

    /// Frosted-glass card background over the themed gradient.
    var cardSurface: Color {
        switch self {
        case .starsSpace:
            // Keep the space world atmospheric, but use a much stronger surface so child text stays readable.
            return Color(red: 0.96, green: 0.98, blue: 1.0).opacity(0.92)
        default:
            return Color.white.opacity(0.96)
        }
    }
}
