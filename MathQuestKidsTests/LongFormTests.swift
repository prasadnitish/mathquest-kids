import Testing
@testable import MathQuestKids

/// Two-digit problems are shown in long form, read from the prompt. The format doesn't say
/// which operation it is, so check that every such prompt reads back as the right problem.
struct LongFormTests {
    @Test @MainActor
    func everyTwoDigitPromptReadsAsItsProblem() throws {
        let pack = try ContentLoader.loadDefaultPack()
        var longForm = 0
        for template in pack.itemTemplates where [.addTwoDigit, .subTwoDigit].contains(template.format) {
            let problem = try #require(WrittenProblem.parse(template.prompt), "\(template.id): \(template.prompt)")
            let answer = Int(template.answer)
            switch problem.operation {
            case .add: #expect(answer == problem.top + problem.bottom, "\(template.id)")
            case .subtract: #expect(answer == problem.top - problem.bottom, "\(template.id)")
            case .multiply: #expect(answer == problem.top * problem.bottom, "\(template.id)")
            case .divide: #expect(answer == problem.top / problem.bottom, "\(template.id)")
            }
            if problem.suitsLongForm {
                longForm += 1
            }
        }
        #expect(longForm > 150)
    }

    @Test @MainActor
    func readsSymbolsAndSkipsStories() {
        #expect(WrittenProblem.parse("47 + 36 = ?") == WrittenProblem(top: 47, bottom: 36, operation: .add))
        #expect(WrittenProblem.parse("72 - 45 = ?")?.operation == .subtract)
        #expect(WrittenProblem.parse("29 × 9 = ?")?.operation == .multiply)
        #expect(WrittenProblem.parse("80 ÷ 8 = ?")?.suitsLongForm == false)
        #expect(WrittenProblem.parse("2 + 1 = ?")?.suitsLongForm == false)
        #expect(WrittenProblem.parse("6 + ? = 9") == nil)
        #expect(WrittenProblem.parse("Sam has 24 apples. He gets 17 more.") == nil)
    }

    @Test @MainActor
    func digitsLineUpOnTheRight() {
        #expect(LongFormProblemView.digits(of: "7", in: 3) == ["", "", "7"])
        #expect(LongFormProblemView.digits(of: "83", in: 2) == ["8", "3"])
        #expect(LongFormProblemView.digits(of: "", in: 2) == ["", ""])
        #expect(LongFormProblemView.placeName(forColumn: 1, of: 2) == "ones")
        #expect(LongFormProblemView.placeName(forColumn: 0, of: 3) == "hundreds")
    }
}
