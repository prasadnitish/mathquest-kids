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
