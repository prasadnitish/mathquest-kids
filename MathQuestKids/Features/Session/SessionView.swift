import SwiftUI

private enum SessionFeedbackTone {
    case positive
    case coaching
}

struct SessionView: View {
    @EnvironmentObject private var appState: AppState

    @State private var selectedChoice: String = ""
    @State private var feedback: String?
    @State private var feedbackTone: SessionFeedbackTone = .coaching
    @State private var showingHint = false
    @State private var activeHint: HintAction?
    @State private var itemStartTime = Date()

    var body: some View {
        Group {
            if let runtime = appState.currentSession {
                sessionContent(runtime: runtime)
            } else {
                ProgressView("Preparing your quest...")
            }
        }
        .padding(24)
    }

    private func sessionContent(runtime: SessionRuntime) -> some View {
        let item = runtime.currentItem
        let progress = Double(runtime.index + 1) / Double(max(runtime.items.count, 1))

        return VStack(alignment: .leading, spacing: 16) {
            topBar(runtime: runtime, progress: progress)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text(item.unit.title)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(appState.selectedTheme.primary.opacity(0.18), in: Capsule())

                    if item.isReview {
                        Text("Review Item")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(appState.selectedTheme.accent.opacity(0.24), in: Capsule())
                            .accessibilityLabel("This is a review item")
                    }
                }

                Text(item.prompt)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .minimumScaleFactor(0.8)
                    .accessibilityLabel("Problem prompt")
                    .accessibilityIdentifier("problemPrompt")

                if let feedback {
                    Text(feedback)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(feedbackTone == .positive ? appState.selectedTheme.accent.opacity(0.24) : appState.selectedTheme.primary.opacity(0.16), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke((feedbackTone == .positive ? appState.selectedTheme.accent : appState.selectedTheme.primary).opacity(0.28), lineWidth: 1)
                        )
                }

                HStack(spacing: 12) {
                    Button {
                        activeHint = appState.requestHint()
                        showingHint = true
                    } label: {
                        Label("Hint", systemImage: "lightbulb.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityLabel("Hint")

                    Button {
                        appState.replayPrompt()
                    } label: {
                        Label("Read Aloud", systemImage: "speaker.wave.2.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityLabel("Read Aloud")

                    Spacer(minLength: 10)

                    Button {
                        submit(item: item)
                    } label: {
                        Label("Submit", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(selectedChoice.isEmpty)
                    .accessibilityLabel("Submit Answer")
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20))

            manipulativeArea(item: item)

            Spacer(minLength: 0)
        }
        .background(.clear)
        .alert("Hint", isPresented: $showingHint, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(activeHint?.text ?? "Try one step at a time.")
        })
        .onAppear {
            itemStartTime = Date()
            appState.readQuestionIfEnabled()
        }
        .onChange(of: runtime.index) { _, _ in
            selectedChoice = ""
            feedback = nil
            itemStartTime = Date()
            appState.readQuestionIfEnabled()
        }
    }

    private func topBar(runtime: SessionRuntime, progress: Double) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.90))

            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                appState.selectedTheme.primary.opacity(0.24),
                                appState.selectedTheme.accent.opacity(0.32)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, proxy.size.width * progress))
                    .overlay(alignment: .trailing) {
                        Image(systemName: appState.selectedTheme.heroSymbol)
                            .font(.title2.weight(.black))
                            .foregroundStyle(appState.selectedTheme.primary.opacity(0.22))
                            .padding(.trailing, 14)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quest in Progress")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("\(Int(progress * 100))% complete")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Text("\(runtime.index + 1)/\(runtime.items.count)")
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.82))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: 74)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func manipulativeArea(item: PracticeItem) -> some View {
        switch item.format {
        case .subtractionStory:
            SubtractionStoryInteraction(item: item, selection: $selectedChoice)
        case .teenPlaceValue:
            TeenPlaceValueInteraction(item: item, selection: $selectedChoice)
        case .twoDigitComparison:
            ComparisonInteraction(item: item, selection: $selectedChoice)
        case .threeDigitComparison:
            ThreeDigitComparisonInteraction(item: item, selection: $selectedChoice)
        case .multiplicationArray:
            MultiplicationArrayInteraction(item: item, selection: $selectedChoice)
        case .fractionComparison:
            FractionComparisonInteraction(item: item, selection: $selectedChoice)
        case .fractionOfWhole:
            FractionOfWholeInteraction(item: item, selection: $selectedChoice)
        case .volumePrism:
            VolumePrismInteraction(item: item, selection: $selectedChoice)
        case .decimalComparison:
            DecimalComparisonInteraction(item: item, selection: $selectedChoice)
        case .additionStory, .addTwoDigit, .subTwoDigit, .factFamily:
            AdditionStoryInteraction(item: item, selection: $selectedChoice)
        case .countAndMatch:
            CountAndMatchInteraction(item: item, selection: $selectedChoice)
        case .numberBond:
            NumberBondInteraction(item: item, selection: $selectedChoice)
        }
    }

    private func submit(item: PracticeItem) {
        let latency = Date().timeIntervalSince(itemStartTime) * 1000
        let mode: InputMode = .tap
        let answer = selectedChoice
        let isCorrect = answer == item.answer
        feedbackTone = isCorrect ? .positive : .coaching
        feedback = questFeedback(for: item, isCorrect: isCorrect)
        appState.submitAnswer(answer: answer, inputMode: mode, latencyMs: latency)
    }

    private func questFeedback(for item: PracticeItem, isCorrect: Bool) -> String {
        if isCorrect {
            switch item.format {
            case .subtractionStory:
                return "Nice job noticing what was left."
            case .teenPlaceValue:
                return "Great build. You matched the tens and ones."
            case .twoDigitComparison, .threeDigitComparison, .decimalComparison:
                return "Strong comparing. You checked the biggest place first."
            case .multiplicationArray:
                return "Nice array thinking. The rows and columns matched."
            case .fractionComparison, .fractionOfWhole:
                return "Great fraction reasoning. You noticed the size of the parts."
            case .volumePrism:
                return "Nice work. You used the dimensions carefully."
            case .additionStory, .addTwoDigit:
                return "Great adding! You put the groups together perfectly."
            case .countAndMatch:
                return "Excellent counting! You matched the right number."
            case .numberBond:
                return "Nice work! You found the missing part of 10."
            case .factFamily:
                return "Great thinking! You found the missing number."
            case .subTwoDigit:
                return "Well done! You subtracted those big numbers correctly."
            }
        }

        switch item.format {
        case .subtractionStory:
            return "Nice try. Check how many are left after you take some away."
        case .teenPlaceValue:
            return "Good effort. Adjust the tens or ones and test the build again."
        case .twoDigitComparison, .threeDigitComparison:
            return "Good start. Compare the biggest place value first."
        case .multiplicationArray:
            return "Good effort. Recount the rows and columns one more time."
        case .fractionComparison:
            return "Nice try. Compare the size of the pieces before you choose."
        case .fractionOfWhole:
            return "Good thinking. Find one equal part first, then build the fraction."
        case .volumePrism:
            return "Nice try. Multiply one layer first, then the height."
        case .decimalComparison:
            return "Good effort. Line up the decimal points and compare place by place."
        case .additionStory, .addTwoDigit:
            return "Good try. Count all the objects together to find the total."
        case .countAndMatch:
            return "Almost! Try counting each dot one more time."
        case .numberBond:
            return "Good effort. Think about what number plus the given number equals 10."
        case .factFamily:
            return "Nice try. Think: the whole minus the known part gives the missing part."
        case .subTwoDigit:
            return "Good effort. Subtract the ones first, then the tens."
        }
    }
}

struct SubtractionStoryInteraction: View {
    let item: PracticeItem
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            let total = item.payload.minuend ?? Int(item.answer) ?? 0
            let removed = item.payload.subtrahend ?? 0

            HStack(spacing: 8) {
                ForEach(0..<max(total, 0), id: \.self) { idx in
                    Circle()
                        .fill(idx < removed ? AppTheme.error.opacity(0.35) : AppTheme.accent.opacity(0.8))
                        .frame(width: 28, height: 28)
                        .overlay {
                            if idx < removed {
                                Image(systemName: "xmark")
                                    .font(.caption2.bold())
                                    .foregroundStyle(AppTheme.error)
                            }
                        }
                }
            }
            .padding(.vertical, 8)

            HStack(spacing: 10) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) {
                        selection = option
                    }
                }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            let left = item.payload.left ?? 0
            let right = item.payload.right ?? 0

            HStack(spacing: 8) {
                ForEach(0..<max(left, 0), id: \.self) { _ in
                    Circle()
                        .fill(AppTheme.accent.opacity(0.8))
                        .frame(width: 28, height: 28)
                }
                if left > 0 && right > 0 {
                    Text("+")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ForEach(0..<max(right, 0), id: \.self) { _ in
                    Circle()
                        .fill(AppTheme.primary.opacity(0.7))
                        .frame(width: 28, height: 28)
                }
            }
            .padding(.vertical, 8)

            HStack(spacing: 10) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) {
                        selection = option
                    }
                }
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

    var body: some View {
        VStack(spacing: 16) {
            let count = item.payload.target ?? 0
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(36)), count: 5), spacing: 8) {
                ForEach(0..<max(count, 0), id: \.self) { _ in
                    Circle()
                        .fill(AppTheme.accent.opacity(0.8))
                        .frame(width: 28, height: 28)
                }
            }
            .padding()

            HStack(spacing: 10) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) {
                        selection = option
                    }
                }
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

    var body: some View {
        VStack(spacing: 20) {
            // Whole circle
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(AppTheme.primary, lineWidth: 2))
                .overlay(Text("\(item.payload.target ?? 10)").font(.title.bold()))
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
                        .fill(label == "?" ? AppTheme.accent.opacity(0.2) : Color.white)
                        .overlay(Circle().stroke(AppTheme.primary, lineWidth: 2))
                        .overlay(Text(label).font(.title2.bold()))
                        .frame(width: 64, height: 64)
                }
            }

            HStack(spacing: 10) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) {
                        selection = option
                    }
                }
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
        item.payload.target ?? ((item.payload.tens ?? 0) * 10 + (item.payload.ones ?? 0))
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
                .font(.headline)

            Text("Tap + or - to adjust the blocks. Big bars count as tens and small cubes count as ones.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: 12) {
                PlaceValueBucket(title: "Tens", count: tens, targetCount: targetTens, kind: .ten) {
                    adjust(.ten, delta: 1)
                } onRemove: {
                    adjust(.ten, delta: -1)
                }
                PlaceValueBucket(title: "Ones", count: ones, targetCount: targetOnes, kind: .one) {
                    adjust(.one, delta: 1)
                } onRemove: {
                    adjust(.one, delta: -1)
                }
            }

            HStack(spacing: 12) {
                Button {
                    adjust(.ten, delta: 1)
                } label: {
                    Label("+1 Ten", systemImage: "plus.circle.fill")
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    adjust(.one, delta: 1)
                } label: {
                    Label("+1 One", systemImage: "plus.circle.fill")
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    adjust(.ten, delta: -1)
                } label: {
                    Label("-1 Ten", systemImage: "minus.circle.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(tens == 0)

                Button {
                    adjust(.one, delta: -1)
                } label: {
                    Label("-1 One", systemImage: "minus.circle.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(ones == 0)

                Button {
                    tens = 0
                    ones = 0
                    refreshSelection()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(SecondaryButtonStyle())
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
    let onAdd: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("Target \(targetCount)")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.72), in: Capsule())
            }
            Text("\(count)")
                .font(.largeTitle.bold())
                .monospacedDigit()
                .frame(maxWidth: .infinity)
            blockPreview

            HStack(spacing: 10) {
                stepButton(systemName: "minus.circle.fill", action: onRemove)
                    .disabled(count == 0)
                stepButton(systemName: "plus.circle.fill", action: onAdd)
            }
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
                        .frame(width: 112, height: 18)
                }
                if count > 5 {
                    Text("+\(count - 5)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 126)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 12))
        } else {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(22), spacing: 6), count: 5), spacing: 6) {
                ForEach(0..<min(count, 20), id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue.opacity(0.85))
                        .frame(width: 22, height: 22)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 126)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(kind == .ten ? Color.green.opacity(0.85) : Color.blue.opacity(0.85))
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.9), in: Circle())
        }
        .buttonStyle(.plain)
    }
}

enum TokenKind {
    case ten
    case one
}

struct ComparisonInteraction: View {
    let item: PracticeItem
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 20) {
                NumberBadge(number: item.payload.left ?? 0)
                Text("?")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                NumberBadge(number: item.payload.right ?? 0)
            }

            HStack(spacing: 12) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) {
                        selection = option
                    }
                }
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

    var body: some View {
        ComparisonInteraction(item: item, selection: $selection)
    }
}

struct MultiplicationArrayInteraction: View {
    let item: PracticeItem
    @Binding var selection: String

    private var rows: Int { item.payload.multiplicand ?? 1 }
    private var columns: Int { item.payload.multiplier ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Build the array: \(rows) rows × \(columns) columns")
                .font(.headline)

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
            .background(Color.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 10) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) {
                        selection = option
                    }
                }
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

    var body: some View {
        let aTop = item.payload.numeratorA ?? 0
        let aBottom = max(item.payload.denominatorA ?? 1, 1)
        let bTop = item.payload.numeratorB ?? 0
        let bBottom = max(item.payload.denominatorB ?? 1, 1)

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 18) {
                FractionBadge(numerator: aTop, denominator: aBottom)
                Text("?")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                FractionBadge(numerator: bTop, denominator: bBottom)
            }

            HStack(spacing: 12) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) {
                        selection = option
                    }
                }
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

    var body: some View {
        let num = item.payload.numeratorA ?? 1
        let den = max(item.payload.denominatorA ?? 1, 1)
        let whole = item.payload.whole ?? 0

        return VStack(alignment: .leading, spacing: 14) {
            Text("Find \(num)/\(den) of \(whole)")
                .font(.headline)

            ProgressView(value: Double(num), total: Double(den))
                .tint(AppTheme.primary)

            HStack(spacing: 10) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) {
                        selection = option
                    }
                }
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

    var body: some View {
        let l = item.payload.length ?? 1
        let w = item.payload.width ?? 1
        let h = item.payload.height ?? 1

        return VStack(alignment: .leading, spacing: 14) {
            Text("Volume = length × width × height")
                .font(.headline)

            HStack(spacing: 12) {
                MetricBadge(title: "L", value: l)
                MetricBadge(title: "W", value: w)
                MetricBadge(title: "H", value: h)
            }

            HStack(spacing: 10) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) {
                        selection = option
                    }
                }
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

    var body: some View {
        let left = item.payload.decimalLeft ?? 0
        let right = item.payload.decimalRight ?? 0

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 20) {
                DecimalBadge(value: left)
                Text("?")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                DecimalBadge(value: right)
            }

            HStack(spacing: 12) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) {
                        selection = option
                    }
                }
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
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(AppTheme.primary.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct FractionBadge: View {
    let numerator: Int
    let denominator: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("\(numerator)")
                .font(.title.bold())
            Rectangle()
                .fill(AppTheme.textPrimary.opacity(0.75))
                .frame(width: 40, height: 2)
            Text("\(denominator)")
                .font(.title.bold())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.primary.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct DecimalBadge: View {
    let value: Double

    var body: some View {
        Text(String(format: "%.3f", value))
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(AppTheme.primary.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct MetricBadge: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.title3.bold())
        }
        .padding(10)
        .frame(width: 56)
        .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ChoiceButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title3.bold())
                .frame(minWidth: 70)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(isSelected ? AppTheme.primary.opacity(0.24) : Color.white)
                .foregroundStyle(AppTheme.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.primary.opacity(isSelected ? 0.78 : 0.5), lineWidth: isSelected ? 2 : 1)
                )
        }
        .accessibilityLabel("Option \(title)")
    }
}
