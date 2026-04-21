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
    @State private var showingQuitConfirmation = false
    @State private var choicesDisabledTemporarily = false

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if let runtime = appState.currentSession {
                sessionContent(runtime: runtime)
            } else {
                ProgressView("Preparing your quest...")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }

    private func sessionContent(runtime: SessionRuntime) -> some View {
        let item = runtime.currentItem
        let progress = Double(runtime.answeredCount) / Double(max(runtime.items.count, 1))

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    showingQuitConfirmation = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .kidText(.body)
                        Text("Quit")
                            .kidText(.body)
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }
                .accessibilityLabel("Quit quest")

                Spacer()
            }

            topBar(runtime: runtime, progress: progress)

            // Question card: prompt only (no grade/domain labels)
            VStack(alignment: .leading, spacing: 12) {
                if item.isReview {
                    HStack(spacing: 8) {
                        Text("Review Item")
                            .kidText(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(appState.selectedTheme.accent.opacity(0.24), in: Capsule())
                            .accessibilityLabel("This is a review item")
                    }
                }

                Text(item.prompt)
                    .kidText(.question)
                    .foregroundStyle(AppTheme.textPrimary)
                    .minimumScaleFactor(0.65)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Problem prompt")
                    .accessibilityIdentifier("problemPrompt")

                if let feedback {
                    let companion = appState.activeCompanion
                    let companionPhrase = feedbackTone == .positive
                        ? CompanionPhrases.correct(tone: companion.tone)
                        : CompanionPhrases.incorrect(tone: companion.tone)

                    HStack(alignment: .top, spacing: 10) {
                        Group {
                            if !companion.imageName.isEmpty {
                                Image(companion.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(Circle())
                                    .shadow(color: appState.selectedTheme.primary.opacity(0.3), radius: 4, y: 2)
                            } else {
                                Image(systemName: companion.symbol)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 48, height: 48)
                                    .background(appState.selectedTheme.primary, in: Circle())
                                    .shadow(color: appState.selectedTheme.primary.opacity(0.3), radius: 4, y: 2)
                            }
                        }
                        .offset(y: -12) // overflow above the card

                        VStack(alignment: .leading, spacing: 4) {
                            Text(companionPhrase)
                                .kidText(.body)
                                .foregroundStyle(appState.selectedTheme.primary)
                                .lineLimit(1)
                            Text(feedback)
                                .kidText(.body)
                                .foregroundStyle(AppTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(feedbackTone == .positive ? appState.selectedTheme.accent.opacity(0.24) : appState.selectedTheme.primary.opacity(0.16), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke((feedbackTone == .positive ? appState.selectedTheme.accent : appState.selectedTheme.primary).opacity(0.28), lineWidth: 1)
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.updatesFrequently)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20))

            // Read Aloud — primary CTA above the answer options
            readAloudButton

            // Options / manipulative area
            if runtime.pendingCorrection {
                correctionOverlay(item: item)
            } else {
                manipulativeArea(item: item)
                    .disabled(choicesDisabledTemporarily)
                    .opacity(choicesDisabledTemporarily ? 0.6 : 1.0)
            }

            // Hint + Submit below options
            HStack(spacing: 12) {
                hintButton
                submitButton(item: item)
            }
            .padding(.horizontal, 4)

            Spacer(minLength: 0)
        }
        .background(.clear)
        .alert(appState.activeCompanion.name, isPresented: $showingHint, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            let intro = CompanionPhrases.hintIntro(tone: appState.activeCompanion.tone)
            Text("\(intro) \(activeHint?.text ?? "Try one step at a time.")")
        })
        .confirmationDialog("Leave this quest?", isPresented: $showingQuitConfirmation, titleVisibility: .visible) {
            Button("Quit Quest", role: .destructive) {
                appState.goHome()
            }
            Button("Keep Going", role: .cancel) { }
        } message: {
            Text("Your progress on this quest won't be saved.")
        }
        .onAppear {
            itemStartTime = Date()
            appState.readQuestionIfEnabled()
        }
        .onChange(of: runtime.index) { _, _ in
            selectedChoice = ""
            feedback = nil
            choicesDisabledTemporarily = false
            itemStartTime = Date()
            appState.readQuestionIfEnabled()
        }
    }

    private func topBar(runtime: SessionRuntime, progress: Double) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.card)

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
                    .animation(.easeInOut(duration: 0.4), value: progress)
                    .overlay(alignment: .trailing) {
                        Image(systemName: appState.selectedTheme.heroSymbol)
                            .kidText(.h2)
                            .foregroundStyle(appState.selectedTheme.primary.opacity(0.22))
                            .padding(.trailing, 14)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quest in Progress")
                        .kidText(.h2)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("\(Int(progress * 100))% complete")
                        .kidText(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Text("\(runtime.index + 1)/\(runtime.items.count)")
                    .kidText(.h2)
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.82))
                    .padding(.trailing, 36)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(height: 64)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppTheme.card.opacity(0.45), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var hintButton: some View {
        Button {
            activeHint = appState.requestHint()
            showingHint = true
        } label: {
            Label("Hint", systemImage: "lightbulb.fill")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityLabel("Hint")
    }

    private var readAloudButton: some View {
        Button {
            appState.replayPrompt()
        } label: {
            Label("Read Aloud", systemImage: "speaker.wave.2.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(CTAButtonStyle(theme: appState.selectedTheme))
        .accessibilityLabel("Read Aloud")
    }

    private func submitButton(item: PracticeItem) -> some View {
        Button {
            submit(item: item)
        } label: {
            Label("Submit", systemImage: "checkmark.circle.fill")
        }
        .buttonStyle(CTAButtonStyle(theme: appState.selectedTheme))
        .disabled(selectedChoice.isEmpty)
        .accessibilityLabel("Submit Answer")
    }

    @ViewBuilder
    private func sessionActionButtons(item: PracticeItem) -> some View {
        hintButton
        Spacer(minLength: 10)
        submitButton(item: item)
    }

    @ViewBuilder
    private func manipulativeArea(item: PracticeItem) -> some View {
        let theme = appState.selectedTheme
        switch item.format {
        case .subtractionStory:
            SubtractionStoryInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .teenPlaceValue:
            TeenPlaceValueInteraction(item: item, selection: $selectedChoice)
        case .twoDigitComparison:
            ComparisonInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .threeDigitComparison:
            ThreeDigitComparisonInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .multiplicationArray:
            MultiplicationArrayInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .fractionComparison:
            FractionComparisonInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .fractionOfWhole:
            FractionOfWholeInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .volumePrism:
            VolumePrismInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .decimalComparison:
            DecimalComparisonInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .additionStory, .addTwoDigit, .subTwoDigit, .factFamily:
            AdditionStoryInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .countAndMatch:
            CountAndMatchInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .numberBond:
            NumberBondInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .groupComparison:
            GroupComparisonInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .shapeClassification:
            ShapeClassificationInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .measureLength:
            MeasureLengthInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .divisionGroups:
            DivisionGroupsInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .areaTiling:
            AreaTilingInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .timeMoney:
            TimeMoneyInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .dataPlot:
            DataPlotInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .angleMeasure:
            AngleMeasureInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .fractionAddSub:
            FractionAddSubInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        case .ratioTable:
            RatioTableInteraction(item: item, selection: $selectedChoice, theme: theme, onDefer: recordDefer)
        }
    }

    private func correctionOverlay(item: PracticeItem) -> some View {
        let companion = appState.activeCompanion
        let correctionPhrase = CompanionPhrases.correction(tone: companion.tone)

        // Build a worked explanation from the hint engine
        let context = AttemptContext(
            unit: item.unit,
            skillID: item.skillID,
            prompt: item.prompt,
            payload: item.payload,
            incorrectAttempts: 2,
            recentMisconceptions: [],
            supports: item.supports
        )
        let workedHint = appState.hintEngine.nextHint(for: context)

        return VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Group {
                    if !companion.imageName.isEmpty {
                        Image(companion.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: companion.symbol)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(appState.selectedTheme.primary, in: Circle())
                    }
                }
                .shadow(color: appState.selectedTheme.primary.opacity(0.35), radius: 6, y: 3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(companion.name)
                        .kidText(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(correctionPhrase)
                        .kidText(.body)
                        .foregroundStyle(appState.selectedTheme.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Correct answer highlight
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .kidText(.h2)
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("The answer is")
                        .kidText(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(item.answer)
                        .kidText(.h2)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )

            // Worked explanation
            VStack(alignment: .leading, spacing: 6) {
                Text("How to solve it")
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                Text(workedHint.text)
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(appState.selectedTheme.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))

            Button {
                appState.acknowledgeCorrection()
            } label: {
                Label("Got it, next question!", systemImage: "arrow.right.circle.fill")
            }
            .buttonStyle(CTAButtonStyle(theme: appState.selectedTheme))
            .accessibilityLabel("Acknowledge correction and continue")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20))
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func recordDefer() {
        // "I don't know yet" — trigger the hint system so the child gets guidance
        // without scoring the question as wrong.
        activeHint = appState.requestHint()
        showingHint = true
    }

    private func submit(item: PracticeItem) {
        let latency = Date().timeIntervalSince(itemStartTime) * 1000
        let mode: InputMode = .tap
        let answer = selectedChoice
        let isCorrect = answer == item.answer
        feedbackTone = isCorrect ? .positive : .coaching
        feedback = questFeedback(for: item, isCorrect: isCorrect)
        appState.submitAnswer(answer: answer, inputMode: mode, latencyMs: latency)

        // After the first wrong answer, briefly disable choices so the child
        // reads the feedback before trying again.
        if !isCorrect && !(appState.currentSession?.pendingCorrection ?? false) {
            choicesDisabledTemporarily = true
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                choicesDisabledTemporarily = false
                selectedChoice = ""
            }
        }
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
            case .groupComparison:
                return "Great comparing! You noticed which group has more."
            case .shapeClassification:
                return "Nice shape thinking! You noticed the right attributes."
            case .measureLength:
                return "Good measuring! You counted the units carefully."
            case .divisionGroups:
                return "Nice sharing! You split them into equal groups."
            case .areaTiling:
                return "Great area thinking! You counted the squares."
            case .timeMoney:
                return "Nice time and money skills!"
            case .dataPlot:
                return "Good data reading! You found the right value."
            case .angleMeasure:
                return "Nice angle measurement!"
            case .fractionAddSub:
                return "Great fraction work! You combined the parts correctly."
            case .ratioTable:
                return "Nice pattern thinking! You extended the ratio."
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
        case .groupComparison:
            return "Good try. Count each group carefully."
        case .shapeClassification:
            return "Look at the sides and corners again."
        case .measureLength:
            return "Try counting the marks from the start."
        case .divisionGroups:
            return "Try dividing the total evenly."
        case .areaTiling:
            return "Count the rows and columns carefully."
        case .timeMoney:
            return "Look at the clock hands or coins again."
        case .dataPlot:
            return "Check the chart labels and heights."
        case .angleMeasure:
            return "Look at how wide the angle opens."
        case .fractionAddSub:
            return "Try adding the numerators over the same denominator."
        case .ratioTable:
            return "Look at how the numbers grow in each row."
        }
    }
}

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
