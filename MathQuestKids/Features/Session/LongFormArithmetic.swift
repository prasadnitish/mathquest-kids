import Foundation
import SwiftUI

/// A written "A op B = ?" problem, read from the prompt. The format alone doesn't say which
/// operation it is: the two-digit addition format also carries subtraction, multiplication
/// and division questions.
struct WrittenProblem: Equatable {
    enum Operation: Equatable {
        case add, subtract, multiply, divide

        var symbol: String {
            switch self {
            case .add: return "+"
            case .subtract: return "−"
            case .multiply: return "×"
            case .divide: return "÷"
            }
        }

        var spoken: String {
            switch self {
            case .add: return "plus"
            case .subtract: return "minus"
            case .multiply: return "times"
            case .divide: return "divided by"
            }
        }
    }

    let top: Int
    let bottom: Int
    let operation: Operation

    static func parse(_ prompt: String) -> WrittenProblem? {
        let pattern = #"^\s*(\d+)\s*([+\-−×÷])\s*(\d+)\s*=\s*\?\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: prompt, range: NSRange(prompt.startIndex..., in: prompt)),
              let topRange = Range(match.range(at: 1), in: prompt),
              let symbolRange = Range(match.range(at: 2), in: prompt),
              let bottomRange = Range(match.range(at: 3), in: prompt),
              let top = Int(prompt[topRange]),
              let bottom = Int(prompt[bottomRange]) else {
            return nil
        }
        let operation: Operation
        switch String(prompt[symbolRange]) {
        case "+": operation = .add
        case "-", "−": operation = .subtract
        case "×": operation = .multiply
        case "÷": operation = .divide
        default: return nil
        }
        return WrittenProblem(top: top, bottom: bottom, operation: operation)
    }

    /// Worth writing in columns: a number with two or more digits, and not division.
    var suitsLongForm: Bool {
        operation != .divide && max(top, bottom) >= 10
    }
}

/// Long form: the numbers stacked in place-value columns, the way children write them on
/// paper, so they can work the ones column first and then the tens. The answer boxes fill
/// with the digits of the chosen answer.
struct LongFormProblemView: View {
    let problem: WrittenProblem
    let answer: String
    let selection: String

    @Environment(\.horizontalSizeClass) private var sizeClass

    private var columnCount: Int {
        let chosen = Int(selection).map { String($0).count } ?? 0
        return max(String(problem.top).count, String(problem.bottom).count, answer.count, chosen, 2)
    }

    private var cellWidth: CGFloat { sizeClass == .regular ? 64 : 52 }
    private var cellHeight: CGFloat { sizeClass == .regular ? 68 : 56 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(spacing: 4) {
                labelRow
                digitRow(symbol: "", number: problem.top)
                digitRow(symbol: problem.operation.symbol, number: problem.bottom)
                Rectangle()
                    .fill(AppTheme.textPrimary)
                    .frame(width: cellWidth * CGFloat(columnCount + 1), height: 3)
                answerRow
            }
            .frame(maxWidth: .infinity)

            Text("Start with the ones, then the tens.")
                .kidText(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(problem.top) \(problem.operation.spoken) \(problem.bottom), written in columns")
    }

    private var labelRow: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: cellWidth, height: 20)
            ForEach(0..<columnCount, id: \.self) { column in
                Text(Self.placeName(forColumn: column, of: columnCount))
                    .kidText(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(Self.placeColor(forColumn: column, of: columnCount))
                    .frame(width: cellWidth, height: 20)
            }
        }
    }

    private func digitRow(symbol: String, number: Int) -> some View {
        let digits = Self.digits(of: String(number), in: columnCount)
        return HStack(spacing: 0) {
            Text(symbol)
                .kidText(.display)
                .foregroundStyle(AppTheme.textPrimary)
                .frame(width: cellWidth, height: cellHeight)
            ForEach(0..<columnCount, id: \.self) { column in
                Text(digits[column])
                    .kidText(.display)
                    .monospacedDigit()
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: cellWidth, height: cellHeight)
                    .background(Self.placeColor(forColumn: column, of: columnCount).opacity(0.10))
            }
        }
    }

    private var answerRow: some View {
        let chosen = Int(selection).map { String($0) } ?? ""
        let digits = Self.digits(of: chosen, in: columnCount)
        return HStack(spacing: 0) {
            Color.clear.frame(width: cellWidth, height: cellHeight)
            ForEach(0..<columnCount, id: \.self) { column in
                let color = Self.placeColor(forColumn: column, of: columnCount)
                Text(digits[column])
                    .kidText(.display)
                    .monospacedDigit()
                    .foregroundStyle(color)
                    .frame(width: cellWidth - 8, height: cellHeight - 8)
                    .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(color.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    )
                    .frame(width: cellWidth, height: cellHeight)
            }
        }
    }

    /// The digits of `number` right-aligned into `columns` places, blank on the left.
    static func digits(of number: String, in columns: Int) -> [String] {
        let characters = number.map(String.init)
        let padding = max(0, columns - characters.count)
        return Array(repeating: "", count: padding) + characters.suffix(columns)
    }

    static func placeName(forColumn column: Int, of columns: Int) -> String {
        switch columns - 1 - column {
        case 0: return "ones"
        case 1: return "tens"
        case 2: return "hundreds"
        default: return "thousands"
        }
    }

    /// The same colors as the place-value blocks: ones blue, tens green.
    static func placeColor(forColumn column: Int, of columns: Int) -> Color {
        switch columns - 1 - column {
        case 0: return .blue
        case 1: return .green
        case 2: return .purple
        default: return .orange
        }
    }
}

// MARK: - Working a problem in columns

extension PracticeItem {
    /// Two-digit (and bigger) +, − and × problems are worked in columns, one digit at a time.
    /// Sums within 20 keep their dots: first graders add those by counting on and making ten.
    var columnProblem: WrittenProblem? {
        guard [.addTwoDigit, .subTwoDigit].contains(format),
              let problem = WrittenProblem.parse(prompt), problem.suitsLongForm else {
            return nil
        }
        return problem
    }
}

/// A child's written work on a column problem, as on paper: the answer digits, small carried
/// digits over the next column, and tens traded for ten ones when subtracting.
/// Columns are numbered left to right; the last one is the ones.
struct ColumnWork: Equatable {
    let problem: WrittenProblem
    let columnCount: Int
    var answer: [Int?]
    var carries: [Int?]
    var traded: Set<Int> = []

    init(problem: WrittenProblem, answer: String) {
        self.problem = problem
        let operandPlaces = max(String(problem.top).count, String(problem.bottom).count)
        // Adding and multiplying get a spare column on the left for a final carry, whether or
        // not the answer needs it, so the number of boxes doesn't give the answer away.
        let spare = problem.operation == .subtract ? 0 : 1
        let count = max(operandPlaces + spare, answer.count, 2)
        columnCount = count
        firstOperandColumn = count - operandPlaces
        self.answer = Array(repeating: nil, count: count)
        carries = Array(repeating: nil, count: count)
    }

    /// The leftmost column holding a digit of either number. Every column from here to the
    /// ones needs a digit in the answer (a 0 when nothing is left).
    let firstOperandColumn: Int

    var onesColumn: Int { columnCount - 1 }

    /// The answer as written, or "" until every column of the numbers has a digit and there
    /// are no gaps.
    var writtenAnswer: String {
        guard nextColumnToWrite == nil,
              let first = answer.firstIndex(where: { $0 != nil }) else { return "" }
        let written = answer[first...]
        guard !written.contains(where: { $0 == nil }) else { return "" }
        let text = written.compactMap { $0 }.map { String($0) }.joined()
        return Int(text).map { String($0) } ?? ""
    }

    /// The rightmost column of the numbers that still has no answer digit, or nil when
    /// they're all written.
    var nextColumnToWrite: Int? {
        (firstOperandColumn...onesColumn).reversed().first { answer[$0] == nil }
    }

    /// The spare column on the left for a final carry, when there is one.
    var spareColumn: Int? {
        firstOperandColumn > 0 ? firstOperandColumn - 1 : nil
    }

    func topDigit(_ column: Int) -> Int? { Self.digit(of: problem.top, column: column, columns: columnCount) }
    func bottomDigit(_ column: Int) -> Int? { Self.digit(of: problem.bottom, column: column, columns: columnCount) }

    /// The top digit after trades: one less if it gave a ten away, ten more if it got one.
    func tradedTopValue(_ column: Int) -> Int? {
        guard let digit = topDigit(column) else { return nil }
        return digit + (receivesTen(column) ? 10 : 0) - (traded.contains(column) ? 1 : 0)
    }

    /// Whether the column on the left traded one of its tens into this one.
    func receivesTen(_ column: Int) -> Bool {
        column > 0 && traded.contains(column - 1)
    }

    /// Columns whose written digit doesn't match the correct answer. Zeros in front of the
    /// answer (writing 08 for 8) aren't mistakes.
    func wrongColumns(comparedTo correct: String) -> Set<Int> {
        let expected = LongFormProblemView.digits(of: correct, in: columnCount)
        var wrong = Set<Int>()
        for column in 0..<columnCount {
            let written = answer[column].map { String($0) } ?? ""
            let leadingZero = expected[column].isEmpty && written == "0"
                && answer[..<column].allSatisfy { $0 == nil || $0 == 0 }
            if written != expected[column] && !leadingZero {
                wrong.insert(column)
            }
        }
        return wrong
    }

    /// Subtraction only: a column can give one of its tens (or hundreds) to the column on its right.
    func canTrade(_ column: Int) -> Bool {
        guard problem.operation == .subtract, column < onesColumn, topDigit(column) != nil else { return false }
        return traded.contains(column) || (tradedTopValue(column) ?? 0) > 0
    }

    /// Carries go over every column except the ones; subtraction has none.
    func takesCarry(_ column: Int) -> Bool {
        problem.operation != .subtract && column < onesColumn
    }

    /// What the columns to the right pass into `column` when the problem is worked correctly:
    /// the amount carried when adding or multiplying, or -1 when subtracting takes a ten from it.
    func regrouping(into column: Int) -> Int {
        let placesToTheRight = onesColumn - column
        guard placesToTheRight > 0 else { return 0 }
        var unit = 1
        for _ in 0..<placesToTheRight { unit *= 10 }
        let topRight = problem.top % unit
        let bottomRight = problem.bottom % unit
        switch problem.operation {
        case .add: return (topRight + bottomRight) / unit
        case .subtract: return topRight < bottomRight ? -1 : 0
        case .multiply: return (topRight * problem.bottom) / unit
        case .divide: return 0
        }
    }

    /// A note on the usual slip behind a wrong digit in `column`, or nil when there's no
    /// telling what went wrong.
    func coaching(for column: Int, correct: String) -> String? {
        let expected = LongFormProblemView.digits(of: correct, in: columnCount)
        guard let expectedDigit = Int(expected[column]) else { return nil }
        let place = LongFormProblemView.placeName(forColumn: column, of: columnCount)
        let top = topDigit(column)
        let bottom = bottomDigit(column)

        switch problem.operation {
        case .add, .multiply:
            let carried = regrouping(into: column)
            guard carried > 0 else { return nil }
            if top == nil && bottom == nil {
                return "Write the \(carried) you carried in the \(place)."
            }
            if answer[column] == (expectedDigit - carried + 10) % 10 {
                return "Did you add the \(carried) you carried into the \(place)?"
            }
        case .subtract:
            guard let written = answer[column], let top, let bottom else { return nil }
            let singular = String(place.dropLast())
            if column > 0, regrouping(into: column - 1) < 0, top < bottom, written == bottom - top {
                let left = String(LongFormProblemView.placeName(forColumn: column - 1, of: columnCount).dropLast())
                return "\(bottom) is more than \(top). Trade 1 \(left) for 10 \(place) first."
            }
            if regrouping(into: column) < 0, written == (expectedDigit + 1) % 10 {
                return "You traded 1 \(singular) away, so there's one less \(singular) now."
            }
        case .divide:
            break
        }
        return nil
    }

    static func digit(of number: Int, column: Int, columns: Int) -> Int? {
        let text = String(number)
        let fromRight = columns - column
        guard fromRight >= 1, fromRight <= text.count else { return nil }
        let index = text.index(text.endIndex, offsetBy: -fromRight)
        return Int(String(text[index]))
    }
}

/// Column-by-column entry for long-form problems: the child taps an answer box (the ones
/// first), then a digit, and can mark carries or trade a ten, the way it's done on paper.
/// After a wrong try, the columns that don't match are outlined and the note under the work
/// names the usual slip, so the child knows where to look.
struct ColumnWorkInteraction: View {
    let item: PracticeItem
    let problem: WrittenProblem
    @Binding var selection: String
    let theme: VisualTheme
    let wrongAttempts: Int
    var onDefer: (() -> Void)? = nil

    /// Where the next digit from the pad goes.
    enum Slot: Equatable {
        case answer(Int)
        case carry(Int)
    }

    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var work: ColumnWork
    @State private var active: Slot
    @State private var flagged: Set<Int> = []

    init(
        item: PracticeItem,
        problem: WrittenProblem,
        selection: Binding<String>,
        theme: VisualTheme,
        wrongAttempts: Int,
        onDefer: (() -> Void)? = nil
    ) {
        self.item = item
        self.problem = problem
        _selection = selection
        self.theme = theme
        self.wrongAttempts = wrongAttempts
        self.onDefer = onDefer
        let work = ColumnWork(problem: problem, answer: item.answer)
        _work = State(initialValue: work)
        _active = State(initialValue: .answer(work.onesColumn))
    }

    private var cellWidth: CGFloat { sizeClass == .regular ? 64 : 52 }
    private var cellHeight: CGFloat { sizeClass == .regular ? 68 : 56 }
    private var padKey: CGFloat { sizeClass == .regular ? 64 : 48 }
    private var padSpacing: CGFloat { sizeClass == .regular ? 10 : 6 }
    private var padWidth: CGFloat { padKey * 5 + padSpacing * 4 }
    private let aboveRowHeight: CGFloat = 34

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Side by side where there's room (iPad, phones in landscape), stacked otherwise.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 24) {
                    workArea
                    VStack(spacing: 12) {
                        guidanceText
                        digitPad
                    }
                    .frame(width: padWidth)
                }
                VStack(spacing: 16) {
                    workArea
                    guidanceText
                    digitPad
                }
            }
            .frame(maxWidth: .infinity)

            AnswerButton(
                index: 0,
                title: "I don't know yet",
                state: .idk,
                theme: theme,
                action: { onDefer?() }
            )
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
        .onAppear(perform: publish)
        .onChange(of: wrongAttempts) { _, attempts in
            flagged = attempts > 0 ? work.wrongColumns(comparedTo: item.answer) : []
        }
    }

    // MARK: Work area

    private var workArea: some View {
        VStack(spacing: 4) {
            row(label: "", height: 20) { column in
                Text(LongFormProblemView.placeName(forColumn: column, of: work.columnCount))
                    .kidText(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(LongFormProblemView.placeColor(forColumn: column, of: work.columnCount))
            }

            // Over the top number: carries when adding or multiplying, a traded column's
            // new value when subtracting.
            row(label: "", height: aboveRowHeight) { column in
                aboveCell(column)
            }

            row(label: "", height: cellHeight) { column in
                topDigitCell(column)
            }

            row(label: problem.operation.symbol, height: cellHeight) { column in
                digitText(work.bottomDigit(column))
            }

            Rectangle()
                .fill(AppTheme.textPrimary)
                .frame(width: cellWidth * CGFloat(work.columnCount + 1), height: 3)

            row(label: "", height: cellHeight) { column in
                answerBox(column)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(problem.top) \(problem.operation.spoken) \(problem.bottom), written in columns")
    }

    /// One row: the operator (or nothing) in the left cell, then one cell per column.
    private func row<Cell: View>(
        label: String,
        height: CGFloat,
        @ViewBuilder cell: @escaping (Int) -> Cell
    ) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .kidText(.display)
                .foregroundStyle(AppTheme.textPrimary)
                .frame(width: cellWidth, height: height)
            ForEach(0..<work.columnCount, id: \.self) { column in
                cell(column)
                    .frame(width: cellWidth, height: height)
                    .background(LongFormProblemView.placeColor(forColumn: column, of: work.columnCount).opacity(0.07))
            }
        }
    }

    private func digitText(_ digit: Int?) -> some View {
        Text(digit.map { String($0) } ?? "")
            .kidText(.display)
            .monospacedDigit()
            .foregroundStyle(AppTheme.textPrimary)
    }

    @ViewBuilder
    private func aboveCell(_ column: Int) -> some View {
        if work.takesCarry(column) {
            carryBox(column)
        } else if work.traded.contains(column), let value = work.tradedTopValue(column) {
            Text(String(value))
                .kidText(.h2)
                .foregroundStyle(Color.red)
                .accessibilityLabel("Now \(value)")
        } else {
            Color.clear
        }
    }

    private func carryBox(_ column: Int) -> some View {
        let place = LongFormProblemView.placeName(forColumn: column, of: work.columnCount)
        let isActive = active == .carry(column)
        let written: String = work.carries[column].map { String($0) } ?? ""
        let border: Color = isActive ? theme.primary : Color.orange.opacity(0.6)
        let lineWidth: CGFloat = isActive ? 2.5 : 1.5
        let dash: [CGFloat] = isActive ? [] : [4, 3]
        return Button {
            tapCarry(column)
        } label: {
            Text(written)
                .kidText(.h2)
                .foregroundStyle(Color.orange)
                .frame(width: 34, height: 30)
                .background(Color.orange.opacity(isActive ? 0.18 : 0.08), in: RoundedRectangle(cornerRadius: 7))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(border, style: StrokeStyle(lineWidth: lineWidth, dash: dash))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Carry into the \(place)")
        .accessibilityValue(written.isEmpty ? "empty" : written)
    }

    @ViewBuilder
    private func topDigitCell(_ column: Int) -> some View {
        let digit = work.topDigit(column)
        let gaveTen = work.traded.contains(column)
        let gotTen = work.receivesTen(column) && digit != nil
        let strikeWidth: CGFloat = cellWidth * (gotTen ? 0.8 : 0.55)
        let cell = HStack(spacing: 0) {
            if gotTen {
                Text("1")
                    .kidText(.h2)
                    .foregroundStyle(Color.red)
            }
            digitText(digit)
        }
        .overlay {
            if gaveTen {
                Rectangle()
                    .fill(Color.red)
                    .frame(width: strikeWidth, height: 3)
                    .rotationEffect(.degrees(-24))
            }
        }

        if work.canTrade(column) {
            let place = LongFormProblemView.placeName(forColumn: column, of: work.columnCount)
            let right = LongFormProblemView.placeName(forColumn: column + 1, of: work.columnCount)
            let label: String = gaveTen ? "Undo the trade" : "Trade 1 \(String(place.dropLast())) for 10 \(right)"
            Button {
                toggleTrade(column)
            } label: {
                cell
                    .frame(width: cellWidth - 8, height: cellHeight - 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(label)
        } else {
            cell
        }
    }

    private func answerBox(_ column: Int) -> some View {
        let color = LongFormProblemView.placeColor(forColumn: column, of: work.columnCount)
        let isActive = active == .answer(column)
        let isFlagged = flagged.contains(column)
        let emphasized = isActive || isFlagged
        let ink: Color = isFlagged ? .red : color
        let border: Color = isFlagged ? .red : (isActive ? theme.primary : color.opacity(0.5))
        let fill: Color = ink.opacity(isActive ? 0.18 : 0.08)
        let lineWidth: CGFloat = emphasized ? 3 : 2
        let dash: [CGFloat] = emphasized ? [] : [6, 4]
        let written: String = work.answer[column].map { String($0) } ?? ""
        let place = LongFormProblemView.placeName(forColumn: column, of: work.columnCount)
        return Button {
            active = .answer(column)
        } label: {
            Text(written)
                .kidText(.display)
                .monospacedDigit()
                .foregroundStyle(ink)
                .frame(width: cellWidth - 8, height: cellHeight - 8)
                .background(fill, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(border, style: StrokeStyle(lineWidth: lineWidth, dash: dash))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(place) answer box")
        .accessibilityValue(written.isEmpty ? "empty" : written)
    }

    // MARK: Digit pad

    private var digitPad: some View {
        VStack(spacing: padSpacing) {
            HStack(spacing: padSpacing) {
                ForEach([1, 2, 3, 4, 5], id: \.self) { digitKey($0) }
            }
            HStack(spacing: padSpacing) {
                ForEach([6, 7, 8, 9, 0], id: \.self) { digitKey($0) }
            }
            Button {
                erase()
            } label: {
                Label("Erase", systemImage: "delete.left")
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 44)
                    .background(Color.white.opacity(0.9), in: Capsule())
                    .overlay(Capsule().stroke(AppTheme.textSecondary.opacity(0.25), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private func digitKey(_ digit: Int) -> some View {
        Button {
            write(digit)
        } label: {
            Text(String(digit))
                .kidText(.h1)
                .foregroundStyle(AppTheme.textPrimary)
                .frame(width: padKey, height: padKey)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.primary.opacity(0.3), lineWidth: 2))
                .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Digit \(digit)")
    }

    // MARK: Guidance and actions

    private var guidanceText: some View {
        Text(guidance)
            .kidText(.body)
            .foregroundStyle(flagged.isEmpty ? AppTheme.textSecondary : Color.red)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }

    private var guidance: String {
        if let column = flagged.max() {
            // Children work right to left, so the rightmost wrong column is the first slip.
            let place = LongFormProblemView.placeName(forColumn: column, of: work.columnCount)
            return work.coaching(for: column, correct: item.answer) ?? "Check the \(place) column."
        }
        if work.nextColumnToWrite == nil {
            if problem.operation != .subtract, let spare = work.spareColumn, work.answer[spare] == nil {
                let place = LongFormProblemView.placeName(forColumn: spare, of: work.columnCount)
                let from = LongFormProblemView.placeName(forColumn: spare + 1, of: work.columnCount)
                return "Carried out of the \(from)? Write it in the \(place). Then tap Submit."
            }
            return "All done? Tap Submit."
        }
        if let next = work.nextColumnToWrite, next < work.onesColumn {
            let place = LongFormProblemView.placeName(forColumn: next, of: work.columnCount)
            let previous = LongFormProblemView.placeName(forColumn: next + 1, of: work.columnCount)
            switch problem.operation {
            case .add:
                return "Now the \(place). If the \(previous) made 10 or more, carry 1."
            case .subtract:
                return "Now the \(place). Write 0 if none are left."
            case .multiply:
                return "Now the \(place). Multiply, then add what you carried."
            case .divide:
                return ""
            }
        }
        switch problem.operation {
        case .add:
            return "Add the ones first. Made 10 or more? Tap the little box to carry 1."
        case .subtract:
            return "Subtract the ones first. Not enough ones? Tap the tens to trade 1 ten for 10 ones."
        case .multiply:
            return "Multiply the ones first. Tap the little box to write what you carry."
        case .divide:
            return ""
        }
    }

    private func write(_ digit: Int) {
        switch active {
        case .carry(let column):
            work.carries[column] = digit == 0 ? nil : digit
            // Back to the answer box under the carry, where the carried digit gets added.
            active = .answer(column)
        case .answer(let column):
            work.answer[column] = digit
            flagged.remove(column)
            // Children write right to left: after a digit, move to the next column on the left.
            if column > 0 {
                active = .answer(column - 1)
            }
            publish()
        }
    }

    private func erase() {
        switch active {
        case .carry(let column):
            work.carries[column] = nil
        case .answer(let current):
            var column = current
            // Like backspace: an empty box erases the digit just written to its right.
            if work.answer[column] == nil, column < work.onesColumn {
                column += 1
            }
            work.answer[column] = nil
            flagged.remove(column)
            active = .answer(column)
            publish()
        }
    }

    private func tapCarry(_ column: Int) {
        if problem.operation == .multiply {
            // Multiplying can carry any digit, so the box takes the next digit from the pad.
            active = active == .carry(column) ? .answer(column) : .carry(column)
        } else {
            // Adding two numbers carries at most 1: tap to mark it, tap again to clear it.
            work.carries[column] = work.carries[column] == nil ? 1 : nil
        }
    }

    private func toggleTrade(_ column: Int) {
        guard work.canTrade(column) else { return }
        if work.traded.contains(column) {
            work.traded.remove(column)
        } else {
            work.traded.insert(column)
        }
    }

    private func publish() {
        selection = work.writtenAnswer
    }
}
