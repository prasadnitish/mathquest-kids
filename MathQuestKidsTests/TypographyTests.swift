import SwiftUI
import Testing
@testable import MathQuestKids

struct TypographyTests {
    @Test
    func kidTextDisplayMatchesSpec() {
        let spec = KidText.display.spec
        #expect(spec.familyName == "Nunito")
        #expect(spec.weight == .black)
        #expect(spec.size == 36)
    }

    @Test
    func kidTextQuestionHasRequiredLineHeight() {
        #expect(KidText.question.spec.lineHeight == 1.3)
    }

    @Test
    func kidTextBodyMinimumSize16() {
        #expect(KidText.body.spec.size >= 16)
    }

    @Test
    func parentTextDataUsesDMSans() {
        #expect(ParentText.data.spec.familyName == "DM Sans")
    }

    @Test
    func everyKidTextSizeIsAtLeast13() {
        // Caption is 13px per spec; nothing below that.
        for style in KidText.allCases {
            #expect(style.spec.size >= 13)
        }
    }
}
