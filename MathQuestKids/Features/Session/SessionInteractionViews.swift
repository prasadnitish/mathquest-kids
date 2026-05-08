import SwiftUI

struct SubtractionStoryInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            let total = item.payload.minuend ?? Int(item.answer) ?? 0
            let removed = item.payload.subtrahend ?? 0

            let dotSize: CGFloat = total > 12 ? 20 : 26
            LazyVGrid(columns: [GridItem(.adaptive(minimum: dotSize, maximum: dotSize + 4))], spacing: 6) {
                ForEach(0..<max(total, 0), id: \.self) { idx in
                    Circle()
                        .fill(idx < removed ? DesignTokens.incorrect.opacity(0.35) : AppTheme.accent.opacity(0.8))
                        .frame(width: dotSize, height: dotSize)
                        .overlay {
                            if idx < removed {
                                Image(systemName: "xmark")
                                    .kidText(.caption)
                                    .foregroundStyle(DesignTokens.incorrect)
                            }
                        }
                }
            }
            .padding(.vertical, 8)

            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, option in
                    AnswerButton(
                        index: index,
                        title: option,
                        state: selection == option ? .selected : .default,
                        theme: theme,
                        action: { selection = option }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct AdditionStoryInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            let left = item.payload.left ?? 0
            let right = item.payload.right ?? 0

            let addTotal = left + right
            let addDotSize: CGFloat = addTotal > 12 ? 20 : 26
            VStack(spacing: 8) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: addDotSize, maximum: addDotSize + 4))], spacing: 6) {
                    ForEach(0..<max(left, 0), id: \.self) { _ in
                        Circle()
                            .fill(AppTheme.accent.opacity(0.8))
                            .frame(width: addDotSize, height: addDotSize)
                    }
                    ForEach(left..<(left + max(right, 0)), id: \.self) { _ in
                        Circle()
                            .fill(AppTheme.primary.opacity(0.7))
                            .frame(width: addDotSize, height: addDotSize)
                    }
                }
                if left > 0 && right > 0 {
                    HStack(spacing: 6) {
                        Circle().fill(AppTheme.accent.opacity(0.8)).frame(width: 12, height: 12)
                        Text("= \(left)")
                            .kidText(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("+")
                            .kidText(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        Circle().fill(AppTheme.primary.opacity(0.7)).frame(width: 12, height: 12)
                        Text("= \(right)")
                            .kidText(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .padding(.vertical, 8)

            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, option in
                    AnswerButton(
                        index: index,
                        title: option,
                        state: selection == option ? .selected : .default,
                        theme: theme,
                        action: { selection = option }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct CountAndMatchInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            let count = Int(item.payload.target ?? 0)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(36)), count: 5), spacing: 8) {
                ForEach(0..<max(count, 0), id: \.self) { _ in
                    Circle()
                        .fill(AppTheme.accent.opacity(0.8))
                        .frame(width: 28, height: 28)
                }
            }
            .padding()

            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, option in
                    AnswerButton(
                        index: index,
                        title: option,
                        state: selection == option ? .selected : .default,
                        theme: theme,
                        action: { selection = option }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct NumberBondInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            // Whole circle
            Circle()
                .fill(AppTheme.card)
                .overlay(Circle().stroke(AppTheme.primary, lineWidth: 2))
                .overlay(Text("\(Int(item.payload.target ?? 10))").kidText(.h1).foregroundStyle(AppTheme.textPrimary))
                .frame(width: 72, height: 72)

            // Dividing line
            Rectangle().frame(height: 2).foregroundStyle(AppTheme.primary)
                .padding(.horizontal, 60)

            // Two part circles
            HStack(spacing: 60) {
                let leftLabel = item.payload.left.map { "\($0)" } ?? "?"
                let rightLabel = item.payload.right.map { "\($0)" } ?? "?"
                ForEach([leftLabel, rightLabel], id: \.self) { label in
                    Circle()
                        .fill(label == "?" ? AppTheme.accent.opacity(0.2) : AppTheme.card)
                        .overlay(Circle().stroke(AppTheme.primary, lineWidth: 2))
                        .overlay(Text(label).kidText(.h2).foregroundStyle(AppTheme.textPrimary))
                        .frame(width: 64, height: 64)
                }
            }

            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, option in
                    AnswerButton(
                        index: index,
                        title: option,
                        state: selection == option ? .selected : .default,
                        theme: theme,
                        action: { selection = option }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct TeenPlaceValueInteraction: View {
    let item: PracticeItem
    @Binding var selection: String

    @State private var tens = 0
    @State private var ones = 0

    private var targetNumber: Int {
        Int(item.payload.target ?? Double((item.payload.tens ?? 0) * 10 + (item.payload.ones ?? 0)))
    }

    private var targetTens: Int {
        item.payload.tens ?? targetNumber / 10
    }

    private var targetOnes: Int {
        item.payload.ones ?? targetNumber % 10
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Build the number with tens and ones")
                .kidText(.body)

            Text("Tap + or - to adjust the blocks. Big bars count as tens and small cubes count as ones.")
                .kidText(.body)
                .foregroundStyle(AppTheme.textSecondary)

            ZStack(alignment: .center) {
                HStack(spacing: 12) {
                    // Tens column: bucket + stepper
                    VStack(spacing: 10) {
                        PlaceValueBucket(title: "Tens", count: tens, targetCount: targetTens, kind: .ten)

                        HStack(spacing: 0) {
                            Button { adjust(.ten, delta: -1) } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(width: 44, height: 44)
                            }
                            .disabled(tens == 0)

                            Text("Tens")
                                .kidText(.body)
                                .frame(minWidth: 44)

                            Button { adjust(.ten, delta: 1) } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .foregroundStyle(Color.green.opacity(0.9))
                        .background(Color.green.opacity(0.10), in: Capsule())
                        .overlay(Capsule().stroke(Color.green.opacity(0.25), lineWidth: 1))
                    }

                    // Ones column: bucket + stepper
                    VStack(spacing: 10) {
                        PlaceValueBucket(title: "Ones", count: ones, targetCount: targetOnes, kind: .one)

                        HStack(spacing: 0) {
                            Button { adjust(.one, delta: -1) } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(width: 44, height: 44)
                            }
                            .disabled(ones == 0)

                            Text("Ones")
                                .kidText(.body)
                                .frame(minWidth: 44)

                            Button { adjust(.one, delta: 1) } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .foregroundStyle(Color.blue.opacity(0.9))
                        .background(Color.blue.opacity(0.10), in: Capsule())
                        .overlay(Capsule().stroke(Color.blue.opacity(0.25), lineWidth: 1))
                    }
                }
                .buttonStyle(.plain)

                // Reset button floats centered in the gap between columns
                VStack {
                    Spacer()
                    Button {
                        tens = 0
                        ones = 0
                        refreshSelection()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(width: 40, height: 40)
                            .background(AppTheme.card, in: Circle())
                            .overlay(Circle().stroke(AppTheme.textSecondary.opacity(0.25), lineWidth: 1))
                            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
        .onAppear {
            tens = 0
            ones = 0
            refreshSelection()
        }
        .onChange(of: item.id) { _, _ in
            tens = 0
            ones = 0
            refreshSelection()
        }
    }

    private func refreshSelection() {
        selection = "\(tens)|\(ones)"
    }

    private func adjust(_ kind: TokenKind, delta: Int) {
        switch kind {
        case .ten:
            tens = max(0, tens + delta)
        case .one:
            ones = max(0, ones + delta)
        }
        refreshSelection()
    }
}

struct PlaceValueBucket: View {
    let title: String
    let count: Int
    let targetCount: Int
    let kind: TokenKind

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(title)
                    .kidText(.body)
                Spacer()
                Text("Target \(targetCount)")
                    .kidText(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(AppTheme.card.opacity(0.85), in: Capsule())
            }
            Text("\(count)")
                .kidText(.display)
                .monospacedDigit()
                .frame(maxWidth: .infinity)
            blockPreview
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background((kind == .ten ? Color.green : Color.blue).opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke((kind == .ten ? Color.green : Color.blue).opacity(0.18), lineWidth: 1)
        )
        .accessibilityLabel("\(title) place value bucket")
    }

    @ViewBuilder
    private var blockPreview: some View {
        if kind == .ten {
            VStack(spacing: 4) {
                ForEach(0..<min(count, 5), id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green.opacity(0.82))
                        .frame(maxWidth: .infinity, minHeight: 14, maxHeight: 18)
                }
                if count > 5 {
                    Text("+\(count - 5)")
                        .kidText(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 126)
            .padding(.vertical, 8)
            .background(AppTheme.card.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 22, maximum: 28))], spacing: 6) {
                ForEach(0..<min(count, 20), id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue.opacity(0.85))
                        .frame(width: 22, height: 22)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 126)
            .padding(.vertical, 8)
            .background(AppTheme.card.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
        }
    }

}

enum TokenKind {
    case ten
    case one
}

struct ComparisonInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                NumberBadge(number: item.payload.left ?? 0)
                Text("?")
                    .kidText(.h1)
                NumberBadge(number: item.payload.right ?? 0)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, option in
                    AnswerButton(
                        index: index,
                        title: option,
                        state: selection == option ? .selected : .default,
                        theme: theme,
                        action: { selection = option }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct ThreeDigitComparisonInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil

    var body: some View {
        ComparisonInteraction(item: item, selection: $selection, theme: theme, onDefer: onDefer)
    }
}

struct MultiplicationArrayInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil

    private var rows: Int { item.payload.multiplicand ?? 1 }
    private var columns: Int { item.payload.multiplier ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Build the array: \(rows) rows × \(columns) columns")
                .kidText(.body)

            VStack(spacing: 4) {
                ForEach(0..<min(rows, 8), id: \.self) { _ in
                    HStack(spacing: 4) {
                        ForEach(0..<min(columns, 8), id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(AppTheme.primary.opacity(0.75))
                                .frame(width: 16, height: 16)
                        }
                    }
                }
            }
            .padding(12)
            .background(AppTheme.card.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, option in
                    AnswerButton(
                        index: index,
                        title: option,
                        state: selection == option ? .selected : .default,
                        theme: theme,
                        action: { selection = option }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct FractionComparisonInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil

    var body: some View {
        let aTop = item.payload.numeratorA ?? 0
        let aBottom = max(item.payload.denominatorA ?? 1, 1)
        let bTop = item.payload.numeratorB ?? 0
        let bBottom = max(item.payload.denominatorB ?? 1, 1)

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                FractionBadge(numerator: aTop, denominator: aBottom)
                Text("?")
                    .kidText(.h1)
                FractionBadge(numerator: bTop, denominator: bBottom)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, option in
                    AnswerButton(
                        index: index,
                        title: option,
                        state: selection == option ? .selected : .default,
                        theme: theme,
                        action: { selection = option }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct FractionOfWholeInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil

    var body: some View {
        let num = item.payload.numeratorA ?? 1
        let den = max(item.payload.denominatorA ?? 1, 1)
        let whole = item.payload.whole ?? 0

        return VStack(alignment: .leading, spacing: 14) {
            Text("Find \(num)/\(den) of \(whole)")
                .kidText(.body)

            ProgressView(value: Double(num), total: Double(den))
                .tint(AppTheme.primary)

            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, option in
                    AnswerButton(
                        index: index,
                        title: option,
                        state: selection == option ? .selected : .default,
                        theme: theme,
                        action: { selection = option }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct VolumePrismInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil

    var body: some View {
        let l = item.payload.length ?? 1
        let w = item.payload.width ?? 1
        let h = item.payload.height ?? 1

        return VStack(alignment: .leading, spacing: 14) {
            Text("Volume = length × width × height")
                .kidText(.body)

            HStack(spacing: 12) {
                MetricBadge(title: "L", value: l)
                MetricBadge(title: "W", value: w)
                MetricBadge(title: "H", value: h)
            }

            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, option in
                    AnswerButton(
                        index: index,
                        title: option,
                        state: selection == option ? .selected : .default,
                        theme: theme,
                        action: { selection = option }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct DecimalComparisonInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil

    var body: some View {
        let left = item.payload.decimalLeft ?? 0
        let right = item.payload.decimalRight ?? 0

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                DecimalBadge(value: left)
                Text("?")
                    .kidText(.h1)
                DecimalBadge(value: right)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, option in
                    AnswerButton(
                        index: index,
                        title: option,
                        state: selection == option ? .selected : .default,
                        theme: theme,
                        action: { selection = option }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct NumberBadge: View {
    let number: Int

    var body: some View {
        Text("\(number)")
            .kidText(.h1)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.primary.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct FractionBadge: View {
    let numerator: Int
    let denominator: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("\(numerator)")
                .kidText(.h2)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Rectangle()
                .fill(AppTheme.textPrimary.opacity(0.75))
                .frame(height: 2)
                .frame(minWidth: 28)
            Text("\(denominator)")
                .kidText(.h2)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppTheme.primary.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct DecimalBadge: View {
    let value: Double

    var body: some View {
        Text(String(format: "%.3f", value))
            .kidText(.question)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppTheme.primary.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct MetricBadge: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .kidText(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .kidText(.h2)
        }
        .padding(10)
        .frame(width: 56)
        .background(AppTheme.card.opacity(0.95), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - New K-5 Interaction Views

struct GroupComparisonInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                dotGroup(count: item.payload.left ?? 0, label: "Group A", color: AppTheme.accent)
                dotGroup(count: item.payload.right ?? 0, label: "Group B", color: AppTheme.primary)
            }
            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, opt in
                    AnswerButton(
                        index: index,
                        title: opt,
                        state: selection == opt ? .selected : .default,
                        theme: theme,
                        action: { selection = opt }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
    private func dotGroup(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(label).kidText(.caption).foregroundStyle(AppTheme.textSecondary)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(24)), count: 5), spacing: 6) {
                ForEach(0..<max(count, 0), id: \.self) { _ in
                    Circle().fill(color.opacity(0.8)).frame(width: 20, height: 20)
                }
            }.frame(minHeight: 40)
        }
        .padding(10)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ShapeClassificationInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil
    private var shapeSymbol: String {
        switch item.payload.shapeName ?? "" {
        case "Triangle": return "triangle.fill"
        case "Square": return "square.fill"
        case "Rectangle": return "rectangle.fill"
        case "Circle": return "circle.fill"
        case "Pentagon": return "pentagon.fill"
        case "Hexagon": return "hexagon.fill"
        case "Diamond", "Rhombus": return "diamond.fill"
        default: return "questionmark.square.fill"
        }
    }
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: shapeSymbol).font(.system(size: 80)).foregroundStyle(AppTheme.primary.opacity(0.7)).frame(height: 120)
            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, opt in
                    AnswerButton(
                        index: index,
                        title: opt,
                        state: selection == opt ? .selected : .default,
                        theme: theme,
                        action: { selection = opt }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct MeasureLengthInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil
    private var objectLength: Int { Int(item.payload.target ?? 5) }
    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 6).fill(AppTheme.accent.opacity(0.6)).frame(width: CGFloat(objectLength) * 32, height: 24)
            HStack(spacing: 0) {
                ForEach(0...12, id: \.self) { tick in
                    VStack(spacing: 2) {
                        Rectangle().fill(AppTheme.textPrimary.opacity(0.6)).frame(width: 1, height: tick % 5 == 0 ? 18 : 10)
                        Text("\(tick)").kidText(.caption).foregroundStyle(AppTheme.textSecondary)
                    }.frame(width: 32)
                }
            }
            .padding(.horizontal, 8).padding(.vertical, 6)
            .background(Color.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, opt in
                    AnswerButton(
                        index: index,
                        title: opt,
                        state: selection == opt ? .selected : .default,
                        theme: theme,
                        action: { selection = opt }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct DivisionGroupsInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil
    private var total: Int { item.payload.dividend ?? (item.payload.multiplicand ?? 1) * (item.payload.multiplier ?? 1) }
    private var groups: Int { max(item.payload.divisor ?? item.payload.multiplier ?? 1, 1) }
    private var perGroup: Int { max(1, total / groups) }
    var body: some View {
        VStack(spacing: 16) {
            Text("\(total) items \u{00F7} \(groups) groups").kidText(.body)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(groups, 4)), spacing: 12) {
                ForEach(0..<min(groups, 8), id: \.self) { g in
                    VStack(spacing: 4) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 16))], spacing: 4) {
                            ForEach(0..<min(perGroup, 12), id: \.self) { _ in
                                Circle().fill(AppTheme.accent.opacity(0.8)).frame(width: 14, height: 14)
                            }
                        }
                        Text("Group \(g + 1)").kidText(.caption).foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(8)
                    .background(AppTheme.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, opt in
                    AnswerButton(
                        index: index,
                        title: opt,
                        state: selection == opt ? .selected : .default,
                        theme: theme,
                        action: { selection = opt }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct AreaTilingInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil
    private var rows: Int { item.payload.length ?? item.payload.multiplicand ?? 3 }
    private var cols: Int { item.payload.width ?? item.payload.multiplier ?? 4 }
    var body: some View {
        VStack(spacing: 16) {
            Text("\(rows) rows \u{00D7} \(cols) columns = ?").kidText(.body)
            VStack(spacing: 2) {
                ForEach(0..<min(rows, 10), id: \.self) { _ in
                    HStack(spacing: 2) {
                        ForEach(0..<min(cols, 10), id: \.self) { _ in
                            Rectangle().fill(AppTheme.accent.opacity(0.5)).frame(width: 28, height: 28)
                                .overlay(Rectangle().stroke(AppTheme.primary.opacity(0.3), lineWidth: 1))
                        }
                    }
                }
            }
            .padding(8).background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, opt in
                    AnswerButton(
                        index: index,
                        title: opt,
                        state: selection == opt ? .selected : .default,
                        theme: theme,
                        action: { selection = opt }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct TimeMoneyInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil
    private var isTimeQuestion: Bool { item.payload.hours != nil }
    var body: some View {
        VStack(spacing: 16) {
            if isTimeQuestion {
                ClockFaceView(hours: item.payload.hours ?? 0, minutes: item.payload.minutes ?? 0).frame(width: 160, height: 160)
            } else {
                CoinDisplayView(cents: item.payload.cents ?? 0)
            }
            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, opt in
                    AnswerButton(
                        index: index,
                        title: opt,
                        state: selection == opt ? .selected : .default,
                        theme: theme,
                        action: { selection = opt }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct ClockFaceView: View {
    let hours: Int
    let minutes: Int
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            ZStack {
                Circle().stroke(AppTheme.textPrimary, lineWidth: 3)
                ForEach(1...12, id: \.self) { h in
                    let angle = Double(h) * .pi / 6 - .pi / 2
                    let r = size / 2 - 20
                    Text("\(h)").kidText(.caption)
                        .position(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
                }
                // Hour hand
                Rectangle().fill(AppTheme.textPrimary).frame(width: 4, height: size * 0.25)
                    .offset(y: -size * 0.125)
                    .rotationEffect(.degrees(Double(hours % 12) * 30 + Double(minutes) * 0.5))
                // Minute hand
                Rectangle().fill(AppTheme.primary).frame(width: 2.5, height: size * 0.35)
                    .offset(y: -size * 0.175)
                    .rotationEffect(.degrees(Double(minutes) * 6))
                Circle().fill(AppTheme.textPrimary).frame(width: 8, height: 8)
            }.frame(width: size, height: size)
        }
    }
}

struct CoinDisplayView: View {
    let cents: Int
    private var coins: [(String, Int)] {
        var remaining = cents
        var result: [(String, Int)] = []
        for (name, value) in [("Q", 25), ("D", 10), ("N", 5), ("P", 1)] {
            let count = remaining / value
            if count > 0 { result.append((name, count)); remaining -= count * value }
        }
        return result
    }
    var body: some View {
        HStack(spacing: 12) {
            ForEach(coins, id: \.0) { name, count in
                VStack(spacing: 4) {
                    ZStack {
                        Circle().fill(name == "P" ? Color.orange.opacity(0.6) : Color.gray.opacity(0.4))
                            .frame(width: name == "Q" ? 40 : name == "D" ? 28 : 34,
                                   height: name == "Q" ? 40 : name == "D" ? 28 : 34)
                        Text(name).kidText(.caption)
                    }
                    Text("\u{00D7}\(count)").kidText(.caption).foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }
}

struct DataPlotInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil
    private var values: [Int] { item.payload.barValues ?? [3, 5, 2, 4] }
    private var labels: [String] { item.payload.barLabels ?? ["A", "B", "C", "D"] }
    private var maxVal: Int { max(values.max() ?? 1, 1) }
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(0..<min(values.count, labels.count), id: \.self) { i in
                    VStack(spacing: 4) {
                        Text("\(values[i])").kidText(.caption)
                        RoundedRectangle(cornerRadius: 4).fill(AppTheme.primary.opacity(0.6 + 0.1 * Double(i)))
                            .frame(width: 36, height: CGFloat(values[i]) / CGFloat(maxVal) * 100)
                        Text(labels[i]).kidText(.caption).foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }.frame(height: 140).padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, opt in
                    AnswerButton(
                        index: index,
                        title: opt,
                        state: selection == opt ? .selected : .default,
                        theme: theme,
                        action: { selection = opt }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct AngleMeasureInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil
    private var deg: Double { Double(item.payload.degrees ?? 90) }
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Path { p in p.move(to: CGPoint(x: 30, y: 130)); p.addLine(to: CGPoint(x: 200, y: 130)) }
                    .stroke(AppTheme.textPrimary, lineWidth: 3)
                Path { p in
                    let r = deg * .pi / 180
                    p.move(to: CGPoint(x: 30, y: 130))
                    p.addLine(to: CGPoint(x: 30 + 170 * cos(r), y: 130 - 170 * sin(r)))
                }.stroke(AppTheme.primary, lineWidth: 3)
                Path { p in
                    p.addArc(center: CGPoint(x: 30, y: 130), radius: 40, startAngle: .degrees(0), endAngle: .degrees(-deg), clockwise: true)
                }.stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                Text("?\u{00B0}").kidText(.body)
                    .position(x: 30 + 55 * cos(deg / 2 * .pi / 180), y: 130 - 55 * sin(deg / 2 * .pi / 180))
            }.frame(width: 230, height: 160)
            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, opt in
                    AnswerButton(
                        index: index,
                        title: opt,
                        state: selection == opt ? .selected : .default,
                        theme: theme,
                        action: { selection = opt }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct FractionAddSubInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil
    private var numA: Int { item.payload.numeratorA ?? 1 }
    private var denA: Int { max(item.payload.denominatorA ?? 1, 1) }
    private var numB: Int { item.payload.numeratorB ?? 1 }
    private var denB: Int { max(item.payload.denominatorB ?? 1, 1) }
    private var isSubtraction: Bool { item.prompt.contains("\u{2212}") || item.prompt.lowercased().contains("subtract") }
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                fractionVisual(numerator: numA, denominator: denA, color: AppTheme.accent)
                Text(isSubtraction ? "\u{2212}" : "+").kidText(.h1)
                fractionVisual(numerator: numB, denominator: denB, color: AppTheme.primary)
            }
            Text("= ?").kidText(.h2).foregroundStyle(AppTheme.textPrimary)
            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, opt in
                    AnswerButton(
                        index: index,
                        title: opt,
                        state: selection == opt ? .selected : .default,
                        theme: theme,
                        action: { selection = opt }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
    private func fractionVisual(numerator: Int, denominator: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(numerator)/\(denominator)").kidText(.body)
            HStack(spacing: 1) {
                ForEach(0..<denominator, id: \.self) { i in
                    Rectangle().fill(i < numerator ? color.opacity(0.7) : Color.gray.opacity(0.15))
                        .frame(height: 20)
                        .overlay(Rectangle().stroke(color.opacity(0.3), lineWidth: 0.5))
                }
            }.frame(width: 100).clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}

struct RatioTableInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil
    private var ratioL: Int { item.payload.ratioLeft ?? item.payload.left ?? 2 }
    private var ratioR: Int { item.payload.ratioRight ?? item.payload.right ?? 3 }
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 0) {
                ratioRow(cells: ["\u{00D7}", "1", "2", "3", "4"], header: true)
                ratioRow(cells: ["A", "\(ratioL)", "\(ratioL * 2)", "\(ratioL * 3)", "?"], header: false)
                ratioRow(cells: ["B", "\(ratioR)", "\(ratioR * 2)", "\(ratioR * 3)", "\(ratioR * 4)"], header: false)
            }
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.primary.opacity(0.2), lineWidth: 1))
            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, opt in
                    AnswerButton(
                        index: index,
                        title: opt,
                        state: selection == opt ? .selected : .default,
                        theme: theme,
                        action: { selection = opt }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
    private func ratioRow(cells: [String], header: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(cells.indices, id: \.self) { i in
                Group {
                    if header {
                        Text(cells[i]).kidText(.caption)
                    } else {
                        Text(cells[i]).kidText(.body)
                    }
                }
                .frame(width: 54, height: 36)
                    .background(header ? AppTheme.primary.opacity(0.1) : (cells[i] == "?" ? AppTheme.accent.opacity(0.2) : Color.clear))
                    .overlay(Rectangle().stroke(AppTheme.primary.opacity(0.12), lineWidth: 0.5))
            }
        }
    }
}

struct SpatialChoiceInteraction: View {
    let item: PracticeItem
    @Binding var selection: String
    let theme: VisualTheme
    var onDefer: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            spatialCue

            VStack(spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, option in
                    AnswerButton(
                        index: index,
                        title: option,
                        state: selection == option ? .selected : .default,
                        theme: theme,
                        action: { selection = option }
                    )
                }
                AnswerButton(
                    index: 0,
                    title: "I don't know yet",
                    state: .idk,
                    theme: theme,
                    action: { onDefer?() }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }

    private var spatialCue: some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(theme.primary)
                .frame(width: 82, height: 82)
                .background(theme.primary.opacity(0.12), in: Circle())

            if item.format == .shapeHunt, let scene = item.payload.scene, let gridSize = item.payload.gridSize {
                ShapeHuntSceneView(
                    scene: scene,
                    gridSize: gridSize,
                    targetShape: item.payload.targetShape,
                    theme: theme
                )
            }

            if let spatialDetail {
                Text(spatialDetail)
                    .kidText(.caption)
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(theme.accent.opacity(0.16), in: Capsule())
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(cueText)
                .kidText(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }

    private var cueText: String {
        switch item.format {
        case .shapeHunt:
            return "Look across the scene and count only the matching shapes."
        case .positionWords:
            return "Find the named object first, then use the position word."
        case .rotateToMatch:
            return "Turn the shape in your mind and pick the matching choice."
        case .buildShape:
            return "Imagine the pieces sliding together to make the target."
        case .symmetryMirror:
            return "Each side should match after the mirror line folds."
        case .gridPath:
            return "Move one step at a time on the grid."
        case .solidAttributes:
            return "Match the clue to faces, edges, points, or curved parts."
        case .netPreview:
            return "Picture the squares folding into a solid."
        default:
            return "Use the visual clue, then choose the best match."
        }
    }

    private var spatialDetail: String? {
        switch item.format {
        case .shapeHunt:
            guard let targetShape = item.payload.targetShape else { return nil }
            if let context = item.payload.context {
                return "Find the \(targetShape)s in the \(context)."
            }
            return "Find the \(targetShape)s."
        case .positionWords:
            guard let relation = item.payload.relation, let anchor = item.payload.anchor else { return nil }
            return "Look \(relation) the \(anchor)."
        case .rotateToMatch:
            guard let shape = item.payload.shape, let degrees = item.payload.rotationDegrees else { return nil }
            return "Turn the \(shape) \(degrees) degrees."
        case .buildShape:
            guard let targetShape = item.payload.targetShape, let pieces = item.payload.correctPieces else { return nil }
            return "Build a \(targetShape) with \(pieces)."
        case .symmetryMirror:
            guard let object = item.payload.object, let axis = item.payload.axis else { return nil }
            return "Mirror the \(object) across a \(axis) line."
        case .gridPath:
            guard let start = item.payload.start, let moves = item.payload.moves else { return nil }
            return "Start at the \(start), then move \(moves)."
        case .solidAttributes:
            return item.payload.attribute
        case .netPreview:
            guard let solid = item.payload.targetSolid else { return nil }
            return "Pick the net that folds into a \(solid)."
        default:
            return nil
        }
    }

    private var iconName: String {
        switch item.format {
        case .shapeHunt:
            return "square.on.circle"
        case .positionWords:
            return "arrow.up.and.down.and.arrow.left.and.right"
        case .rotateToMatch:
            return "rotate.right"
        case .buildShape:
            return "square.on.square"
        case .symmetryMirror:
            return "rectangle.split.2x1"
        case .gridPath:
            return "point.topleft.down.curvedto.point.bottomright.up"
        case .solidAttributes:
            return "cube"
        case .netPreview:
            return "square.grid.3x3"
        default:
            return "sparkles"
        }
    }
}

private struct ShapeHuntSceneView: View {
    let scene: [SpatialSceneObject]
    let gridSize: SpatialGridSize
    let targetShape: String?
    let theme: VisualTheme

    var body: some View {
        GeometryReader { proxy in
            let columns = max(gridSize.columns, 1)
            let rows = max(gridSize.rows, 1)
            let cellWidth = proxy.size.width / CGFloat(columns)
            let cellHeight = proxy.size.height / CGFloat(rows)
            let shapeSize = min(cellWidth, cellHeight) * 0.62

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.primary.opacity(0.07))
                gridLines(columns: columns, rows: rows)

                ForEach(Array(scene.enumerated()), id: \.offset) { _, object in
                    spatialShape(object)
                        .frame(width: shapeSize, height: shapeSize)
                        .rotationEffect(.degrees(Double(object.rotation ?? 0)))
                        .overlay {
                            if object.target == true {
                                Circle()
                                    .stroke(theme.accent.opacity(0.55), lineWidth: 3)
                                    .scaleEffect(1.22)
                            }
                        }
                        .position(
                            x: (CGFloat(object.x) + 0.5) * cellWidth,
                            y: (CGFloat(object.y) + 0.5) * cellHeight
                        )
                }
            }
        }
        .aspectRatio(CGFloat(max(gridSize.columns, 1)) / CGFloat(max(gridSize.rows, 1)), contentMode: .fit)
        .frame(maxHeight: 190)
        .accessibilityLabel(accessibilitySummary)
    }

    private func gridLines(columns: Int, rows: Int) -> some View {
        GeometryReader { proxy in
            Path { path in
                for column in 1..<columns {
                    let x = proxy.size.width * CGFloat(column) / CGFloat(columns)
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                }
                for row in 1..<rows {
                    let y = proxy.size.height * CGFloat(row) / CGFloat(rows)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                }
            }
            .stroke(AppTheme.textSecondary.opacity(0.14), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func spatialShape(_ object: SpatialSceneObject) -> some View {
        let color = spatialColor(named: object.color)
        switch object.shape ?? object.name ?? "" {
        case "circle":
            Circle().fill(color)
        case "oval":
            Capsule().fill(color)
        case "triangle":
            TriangleShape().fill(color)
        case "diamond", "rhombus":
            DiamondShape().fill(color)
        case "rectangle":
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color)
                .aspectRatio(1.45, contentMode: .fit)
        default:
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(color)
        }
    }

    private func spatialColor(named name: String?) -> Color {
        switch name {
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        case "teal": return .teal
        case "red": return .red
        default: return theme.primary
        }
    }

    private var accessibilitySummary: String {
        let targetCount = scene.filter { $0.target == true }.count
        let target = targetShape ?? "matching shapes"
        return "Shape hunt scene with \(targetCount) \(target)"
    }
}

private struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.closeSubpath()
        }
    }
}

private struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}
