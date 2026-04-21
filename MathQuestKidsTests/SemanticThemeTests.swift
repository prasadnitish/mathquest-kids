import SwiftUI
import Testing
@testable import MathQuestKids

struct SemanticThemeTests {
    @Test
    func everyWorldExposesEverySemanticRole() {
        for theme in VisualTheme.allCases {
            // Must not trap; each role returns a non-nil Color.
            _ = theme.bg1
            _ = theme.bg2
            _ = theme.primary
            _ = theme.primary2
            _ = theme.accent
            _ = theme.accent2
            _ = theme.cta
            _ = theme.ctaText
            _ = theme.cardSurface
        }
    }

    @Test
    func ctaDiffersFromPrimaryForAtLeastFiveWorlds() {
        // Rule of thumb: CTA should stand out from primary; allow one world to alias.
        let aliasCount = VisualTheme.allCases.filter { $0.primary == $0.cta }.count
        #expect(aliasCount <= 1)
    }

    @Test
    func ctaTextHasReadableContrastOnCTA() {
        // ctaText is either .white (saturated CTA) or AppTheme.textPrimary (light CTA
        // needing dark text). Color == is unreliable for UIColor-backed adaptive colors,
        // so verify the semantic intent via per-theme expectations.
        for theme in VisualTheme.allCases {
            let text = theme.ctaText
            switch theme {
            case .axolotl, .rainbowUnicorn:
                #expect(text == Color.white)
            case .candyland, .turboCars, .starsSpace, .superhero:
                #expect(text != Color.white)
            }
        }
    }
}
