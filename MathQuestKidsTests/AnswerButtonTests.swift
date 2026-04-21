import Testing
@testable import MathQuestKids

struct AnswerButtonTests {
    @Test
    func numberingIsOneBased() {
        #expect(AnswerButtonModel.numberLabel(forIndex: 0) == "1")
        #expect(AnswerButtonModel.numberLabel(forIndex: 3) == "4")
    }

    @Test
    func idkStateUsesQuestionMark() {
        #expect(AnswerButtonModel.numberLabel(forState: .idk) == "?")
    }

    @Test
    func neverUsesLetters() {
        // Safety net: the function must never return A/B/C/D.
        for i in 0..<10 {
            let label = AnswerButtonModel.numberLabel(forIndex: i)
            #expect(!["A","B","C","D","E","F","G","H","I","J"].contains(label))
        }
    }
}
