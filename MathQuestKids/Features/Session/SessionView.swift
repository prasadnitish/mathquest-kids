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
        let showsAnswerDock = !runtime.pendingCorrection

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sessionTopRow

                topBar(runtime: runtime, progress: progress)

                MascotBlock(
                    companion: appState.activeCompanion,
                    context: mascotContext(for: runtime),
                    theme: appState.selectedTheme
                )

                questionCard(for: item, runtime: runtime)

                if let feedback {
                    feedbackCard(feedback)
                }

                if runtime.pendingCorrection {
                    correctionOverlay(item: item)
                } else {
                    answerStage(for: item)
                }
            }
            .padding(.bottom, showsAnswerDock ? 172 : 24)
        }
        .scrollIndicators(.hidden)
        .background(.clear)
        .safeAreaInset(edge: .bottom) {
            if showsAnswerDock {
                answerActionDock(item: item)
            }
        }
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

    private var sessionTopRow: some View {
        HStack(spacing: 12) {
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

            if appState.selectedTheme == .starsSpace || appState.selectedTheme == .candyland {
                HStack(spacing: 8) {
                    ThemeCompanionArtworkView(
                        companion: appState.activeCompanion,
                        theme: appState.selectedTheme,
                        size: 28,
                        highlighted: true
                    )

                    Text(sessionEncouragement)
                        .kidText(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(sessionBadgeBackground, in: Capsule())
                .overlay(Capsule().stroke(appState.selectedTheme.accent.opacity(0.24), lineWidth: 1))
            } else {
                Text("Keep going, \(appState.activeCompanion.name) is cheering for you.")
                    .kidText(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.66), in: Capsule())
            }
        }
    }

    private func topBar(runtime: SessionRuntime, progress: Double) -> some View {
        ZStack(alignment: .leading) {
            sessionPanelBackground(cornerRadius: 18)

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
                    .animation(Motion.transition, value: progress)
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
                    Text(progressTitle)
                        .kidText(.h2)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(progressSubtitle(for: runtime))
                        .kidText(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Text("\(Int(progress * 100))%")
                    .kidText(.h2)
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.82))
                    .padding(.trailing, 16)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(height: 64)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(sessionPanelStroke, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private func mascotContext(for runtime: SessionRuntime) -> MascotVoice.Context {
        if runtime.pendingCorrection {
            return .answerIdk
        }
        guard feedback != nil else {
            return .questionHint
        }
        return feedbackTone == .positive ? .answerCorrect : .answerWrong
    }

    private func questionCard(for item: PracticeItem, runtime: SessionRuntime) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                if item.isReview {
                    Text("Quick Review")
                        .kidText(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(appState.selectedTheme.accent.opacity(0.22), in: Capsule())
                        .accessibilityLabel("This is a review item")
                }

                if runtime.hintsUsedForCurrentItem > 0 {
                    Text("Hint Used")
                        .kidText(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(appState.selectedTheme.primary.opacity(0.12), in: Capsule())
                }
            }

            Text(questionHeadline(for: runtime))
                .kidText(.h2)
                .foregroundStyle(appState.selectedTheme.primary)

            Text(item.prompt)
                .kidText(.question)
                .foregroundStyle(AppTheme.textPrimary)
                .minimumScaleFactor(0.65)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Problem prompt")
                .accessibilityIdentifier("problemPrompt")

            Text(questionHelperText(for: runtime))
                .kidText(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            sessionPanelBackground(cornerRadius: 20)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(sessionPanelStroke, lineWidth: 1)
        }
    }

    private func feedbackCard(_ feedback: String) -> some View {
        let companion = appState.activeCompanion
        let companionPhrase = feedbackTone == .positive
            ? CompanionPhrases.correct(tone: companion.tone)
            : CompanionPhrases.incorrect(tone: companion.tone)
        let accentColor = feedbackTone == .positive ? appState.selectedTheme.accent : appState.selectedTheme.primary

        return HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(accentColor.opacity(0.2))
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: feedbackTone == .positive ? "star.fill" : "sparkles")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(accentColor)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(companionPhrase)
                    .kidText(.body)
                    .foregroundStyle(accentColor)
                Text(feedback)
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(feedbackBackground(accentColor: accentColor), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(accentColor.opacity(0.22), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func answerStage(for item: PracticeItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pick Your Answer")
                        .kidText(.h2)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(answerHelperText)
                        .kidText(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                if !selectedChoice.isEmpty {
                    Text("Ready")
                        .kidText(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(appState.selectedTheme.primary.opacity(0.14), in: Capsule())
                }
            }

            manipulativeArea(item: item)
                .disabled(choicesDisabledTemporarily)
                .opacity(choicesDisabledTemporarily ? 0.6 : 1.0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            sessionPanelBackground(cornerRadius: 20)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(sessionPanelStroke, lineWidth: 1)
        }
    }

    private var answerHelperText: String {
        if choicesDisabledTemporarily {
            return "Hold on. Let's look at the clue together."
        }
        if !selectedChoice.isEmpty {
            return "Nice pick. Tap Submit when you're ready."
        }
        return "Choose the answer that feels right."
    }

    private func questionHeadline(for runtime: SessionRuntime) -> String {
        if runtime.pendingCorrection {
            return "Let's Learn This One"
        }
        if feedback != nil {
            return feedbackTone == .positive ? "You Did It" : "Try a New Idea"
        }
        if runtime.currentItem.isReview {
            return "Let's Warm Up"
        }
        return "Your Turn"
    }

    private func questionHelperText(for runtime: SessionRuntime) -> String {
        if runtime.pendingCorrection {
            return "Watch the fix, then jump into the next question."
        }
        if feedbackTone == .positive, feedback != nil {
            return "That answer moved your quest forward."
        }
        if feedback != nil {
            return "Use the clue below and try again."
        }
        return "Listen, think, and choose the answer that matches."
    }

    private var hintButton: some View {
        Button {
            activeHint = appState.requestHint()
            showingHint = true
        } label: {
            Label("Hint", systemImage: "lightbulb.fill")
                .frame(maxWidth: .infinity)
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
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(CTAButtonStyle(theme: appState.selectedTheme))
        .disabled(selectedChoice.isEmpty)
        .accessibilityLabel("Submit Answer")
    }

    private func answerActionDock(item: PracticeItem) -> some View {
        VStack(spacing: 12) {
            if sizeClass == .regular {
                HStack(spacing: 12) {
                    readAloudButton
                    hintButton
                }
            } else {
                VStack(spacing: 12) {
                    readAloudButton
                    hintButton
                }
            }

            submitButton(item: item)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [Color.white.opacity(0.82), Color.white.opacity(0.35), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 1)
        }
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
            MascotBlock(
                companion: appState.activeCompanion,
                context: .answerIdk,
                theme: appState.selectedTheme
            )

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

            VStack(alignment: .leading, spacing: 6) {
                Text("Let's Solve It Together")
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
        .background {
            sessionPanelBackground(cornerRadius: 20)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(sessionPanelStroke, lineWidth: 1)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var sessionBadgeBackground: Color {
        switch appState.selectedTheme {
        case .starsSpace:
            return Color.white.opacity(0.12)
        case .candyland:
            return Color.white.opacity(0.40)
        default:
            return Color.white.opacity(0.66)
        }
    }

    private func progressSubtitle(for runtime: SessionRuntime) -> String {
        if appState.selectedTheme == .starsSpace {
            return "\(runtime.index + 1) of \(runtime.items.count) · \(runtime.correctCount) stars collected"
        }
        if appState.selectedTheme == .candyland {
            return "\(runtime.index + 1) of \(runtime.items.count) · \(runtime.correctCount) sweet wins"
        }
        return "\(runtime.index + 1) of \(runtime.items.count) · \(runtime.correctCount) stars earned"
    }

    private var progressTitle: String {
        switch appState.selectedTheme {
        case .starsSpace:
            return "Mission Step"
        case .candyland:
            return "Sweet Step"
        default:
            return "Quest Step"
        }
    }

    private var sessionEncouragement: String {
        switch appState.selectedTheme {
        case .starsSpace:
            return "Mission control is with you."
        case .candyland:
            return "Your candy guide is cheering you on."
        default:
            return "Keep going, \(appState.activeCompanion.name) is cheering for you."
        }
    }

    private var sessionPanelStroke: Color {
        switch appState.selectedTheme {
        case .starsSpace:
            return appState.selectedTheme.accent.opacity(0.22)
        case .candyland:
            return appState.selectedTheme.primary.opacity(0.20)
        default:
            return AppTheme.card.opacity(0.45)
        }
    }

    @ViewBuilder
    private func sessionPanelBackground(cornerRadius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if appState.selectedTheme == .starsSpace {
            shape
                .fill(Color.white.opacity(0.09))
                .background {
                    ZStack {
                        Image(appState.selectedTheme.backgroundAssetName)
                            .resizable()
                            .scaledToFill()
                        LinearGradient(
                            colors: [Color.black.opacity(0.28), Color.black.opacity(0.44)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                    .clipShape(shape)
                }
                .overlay {
                    shape
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.06), .clear, appState.selectedTheme.accent.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        } else if appState.selectedTheme == .candyland {
            shape
                .fill(Color.white.opacity(0.76))
                .background {
                    ZStack {
                        Image(appState.selectedTheme.backgroundAssetName)
                            .resizable()
                            .scaledToFill()
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.14),
                                Color(red: 0.86, green: 0.33, blue: 0.55).opacity(0.20),
                                Color(red: 0.54, green: 0.17, blue: 0.28).opacity(0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                    .clipShape(shape)
                }
                .overlay {
                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.34),
                                    appState.selectedTheme.accent.opacity(0.10),
                                    appState.selectedTheme.primary.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        } else {
            shape.fill(AppTheme.card)
        }
    }

    private func feedbackBackground(accentColor: Color) -> Color {
        if appState.selectedTheme == .starsSpace {
            return accentColor.opacity(feedbackTone == .positive ? 0.22 : 0.16)
        }
        if appState.selectedTheme == .candyland {
            return feedbackTone == .positive
                ? Color(red: 1.00, green: 0.88, blue: 0.64).opacity(0.54)
                : Color(red: 1.00, green: 0.76, blue: 0.85).opacity(0.68)
        }
        return feedbackTone == .positive ? appState.selectedTheme.accent.opacity(0.18) : appState.selectedTheme.primary.opacity(0.12)
    }

    private func recordDefer() {
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
