import Foundation
import SwiftUI
import Testing
@testable import MathQuestKids

struct DesignTokensTests {
    @Test
    func fixedSemanticColorsMatchSpec() {
        #expect(DesignTokens.correct == Color(red: 0x16/255, green: 0xa3/255, blue: 0x4a/255))
        #expect(DesignTokens.incorrect == Color(red: 0xdc/255, green: 0x26/255, blue: 0x26/255))
        #expect(DesignTokens.streakWarning == Color(red: 0xf5/255, green: 0x9e/255, blue: 0x0b/255))
        #expect(DesignTokens.parentSlate == Color(red: 0x1e/255, green: 0x29/255, blue: 0x3b/255))
    }

    @Test
    func spacingScaleMatchesSpec() {
        #expect(DesignTokens.Spacing.sp1 == 4)
        #expect(DesignTokens.Spacing.sp2 == 8)
        #expect(DesignTokens.Spacing.sp3 == 12)
        #expect(DesignTokens.Spacing.sp4 == 16)
        #expect(DesignTokens.Spacing.sp6 == 24)
        #expect(DesignTokens.Spacing.sp8 == 32)
        #expect(DesignTokens.Spacing.sp12 == 48)
    }

    @Test
    func radiusScaleMatchesSpec() {
        #expect(DesignTokens.Radius.sm == 6)
        #expect(DesignTokens.Radius.md == 14)
        #expect(DesignTokens.Radius.lg == 20)
        #expect(DesignTokens.Radius.pill == 999)
    }

    @Test
    func minimumTapTargetIs48() {
        #expect(DesignTokens.Layout.minTapTarget == 48)
    }
}
