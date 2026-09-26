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

    // MARK: Column work

    @Test @MainActor
    func everyColumnProblemCanBeWrittenOut() throws {
        let pack = try ContentLoader.loadDefaultPack()
        var checked = 0
        for template in pack.itemTemplates {
            let item = PracticeItem(
                id: template.id, templateID: template.id, unit: template.unit, skillID: template.skill,
                format: template.format, prompt: template.prompt, spokenForm: template.spokenForm,
                answer: template.answer, supports: template.supports, payload: template.payload,
                options: template.choices ?? [template.answer], isReview: false
            )
            guard let problem = item.columnProblem else { continue }
            var work = ColumnWork(problem: problem, answer: template.answer)
            let digits = LongFormProblemView.digits(of: template.answer, in: work.columnCount)
            for column in 0..<work.columnCount {
                // Columns of the numbers always get a digit, 0 when nothing is left.
                let required = column >= work.firstOperandColumn
                work.answer[column] = Int(digits[column]) ?? (required ? 0 : nil)
            }
            #expect(work.writtenAnswer == template.answer, "\(template.id): \(template.prompt)")
            #expect(work.wrongColumns(comparedTo: template.answer).isEmpty, "\(template.id)")
            checked += 1
        }
        #expect(checked > 150)
    }

    @Test @MainActor
    func withinTwentyStoriesKeepTheirDots() {
        let item = PracticeItem(
            id: "t", templateID: "t", unit: .g1AddWithin20, skillID: "add_within_20",
            format: .additionStory, prompt: "7 + 11 = ?", spokenForm: nil,
            answer: "18", supports: [], payload: ItemPayload(target: 18), options: ["18"], isReview: false
        )
        #expect(item.columnProblem == nil)
    }

    @Test @MainActor
    func addingAndMultiplyingGetASpareColumn() {
        let add = ColumnWork(problem: WrittenProblem(top: 47, bottom: 36, operation: .add), answer: "83")
        #expect(add.columnCount == 3)
        #expect(add.firstOperandColumn == 1)
        #expect(add.spareColumn == 0)
        let times = ColumnWork(problem: WrittenProblem(top: 10, bottom: 4, operation: .multiply), answer: "40")
        #expect(times.columnCount == 3)
        let minus = ColumnWork(problem: WrittenProblem(top: 50, bottom: 42, operation: .subtract), answer: "8")
        #expect(minus.columnCount == 2)
        #expect(minus.spareColumn == nil)
    }

    @Test @MainActor
    func theAnswerWaitsForEveryColumn() {
        var work = ColumnWork(problem: WrittenProblem(top: 47, bottom: 36, operation: .add), answer: "83")
        #expect(work.writtenAnswer == "")
        #expect(work.nextColumnToWrite == 2)
        work.answer[2] = 3
        #expect(work.writtenAnswer == "")
        #expect(work.nextColumnToWrite == 1)
        work.answer[1] = 8
        #expect(work.writtenAnswer == "83")
        #expect(work.nextColumnToWrite == nil)
        work.answer[0] = 0
        #expect(work.writtenAnswer == "83")

        var gap = ColumnWork(problem: WrittenProblem(top: 57, bottom: 45, operation: .add), answer: "102")
        gap.answer = [1, nil, 2]
        #expect(gap.writtenAnswer == "")
        gap.answer = [1, 0, 2]
        #expect(gap.writtenAnswer == "102")

        var zero = ColumnWork(problem: WrittenProblem(top: 18, bottom: 18, operation: .subtract), answer: "0")
        zero.answer = [0, 0]
        #expect(zero.writtenAnswer == "0")
    }

    @Test @MainActor
    func wrongColumnsSkipLeadingZeros() {
        var minus = ColumnWork(problem: WrittenProblem(top: 50, bottom: 42, operation: .subtract), answer: "8")
        minus.answer = [0, 8]
        #expect(minus.wrongColumns(comparedTo: "8").isEmpty)
        minus.answer = [1, 2]
        #expect(minus.wrongColumns(comparedTo: "8") == [0, 1])

        var add = ColumnWork(problem: WrittenProblem(top: 47, bottom: 36, operation: .add), answer: "83")
        add.answer = [nil, 7, 3]
        #expect(add.wrongColumns(comparedTo: "83") == [1])
    }

    @Test @MainActor
    func regroupingFollowsThePaperMethod() {
        let add = ColumnWork(problem: WrittenProblem(top: 57, bottom: 45, operation: .add), answer: "102")
        #expect(add.regrouping(into: 2) == 0)
        #expect(add.regrouping(into: 1) == 1)
        #expect(add.regrouping(into: 0) == 1)
        let noCarry = ColumnWork(problem: WrittenProblem(top: 23, bottom: 14, operation: .add), answer: "37")
        #expect(noCarry.regrouping(into: 1) == 0)
        let times = ColumnWork(problem: WrittenProblem(top: 29, bottom: 9, operation: .multiply), answer: "261")
        #expect(times.regrouping(into: 1) == 8)
        #expect(times.regrouping(into: 0) == 2)
        let minus = ColumnWork(problem: WrittenProblem(top: 72, bottom: 45, operation: .subtract), answer: "27")
        #expect(minus.regrouping(into: 0) == -1)
        let noTrade = ColumnWork(problem: WrittenProblem(top: 67, bottom: 34, operation: .subtract), answer: "33")
        #expect(noTrade.regrouping(into: 0) == 0)
    }

    @Test @MainActor
    func onlySubtractionTradesAndOnlyAddingAndMultiplyingCarry() {
        var minus = ColumnWork(problem: WrittenProblem(top: 30, bottom: 27, operation: .subtract), answer: "3")
        #expect(minus.canTrade(0))
        #expect(!minus.canTrade(1))
        #expect(!minus.takesCarry(0))
        minus.traded.insert(0)
        #expect(minus.tradedTopValue(0) == 2)
        #expect(minus.tradedTopValue(1) == 10)

        // Trading across a zero: the tens have nothing to give until the hundreds trade.
        var across = ColumnWork(problem: WrittenProblem(top: 100, bottom: 17, operation: .subtract), answer: "83")
        #expect(!across.canTrade(1))
        across.traded.insert(0)
        #expect(across.canTrade(1))
        across.traded.insert(1)
        #expect(across.tradedTopValue(1) == 9)
        #expect(across.tradedTopValue(2) == 10)

        let add = ColumnWork(problem: WrittenProblem(top: 47, bottom: 36, operation: .add), answer: "83")
        #expect(!add.canTrade(1))
        #expect(add.takesCarry(0) && add.takesCarry(1) && !add.takesCarry(2))
    }

    @Test @MainActor
    func coachingNamesTheUsualSlip() {
        // Forgot the carried 1: 47 + 36 written as 73.
        var add = ColumnWork(problem: WrittenProblem(top: 47, bottom: 36, operation: .add), answer: "83")
        add.answer = [nil, 7, 3]
        #expect(add.coaching(for: 1, correct: "83") == "Did you add the 1 you carried into the tens?")
        // A slip with no pattern gets the plain "check this column".
        add.answer = [nil, 5, 3]
        #expect(add.coaching(for: 1, correct: "83") == nil)

        // Left out the final carry: 57 + 45 written as 02.
        var final = ColumnWork(problem: WrittenProblem(top: 57, bottom: 45, operation: .add), answer: "102")
        final.answer = [nil, 0, 2]
        #expect(final.coaching(for: 0, correct: "102") == "Write the 1 you carried in the hundreds.")

        // Took the smaller digit from the bigger one: 72 − 45 with 3 in the ones.
        var minus = ColumnWork(problem: WrittenProblem(top: 72, bottom: 45, operation: .subtract), answer: "27")
        minus.answer = [3, 3]
        #expect(minus.coaching(for: 1, correct: "27") == "5 is more than 2. Trade 1 ten for 10 ones first.")
        // Traded, but still counted the ten that was traded away.
        minus.answer = [3, 7]
        #expect(minus.coaching(for: 0, correct: "27") == "You traded 1 ten away, so there's one less ten now.")

        // 29 × 9: the tens left out the 8 carried from 9 × 9.
        var times = ColumnWork(problem: WrittenProblem(top: 29, bottom: 9, operation: .multiply), answer: "261")
        times.answer = [nil, 8, 1]
        #expect(times.coaching(for: 1, correct: "261") == "Did you add the 8 you carried into the tens?")
    }
}
