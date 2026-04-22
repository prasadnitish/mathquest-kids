import Foundation
import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    enum Route {
        case profileSetup
        case diagnostic
        case home
        case lessonPlans
        case session
        case summary
        case stickerBook
    }

    enum SettingsDismissAction {
        case retakeDiagnostic
    }

    enum ParentGateResult {
        case unlocked
        case incorrect(remainingAttempts: Int)
        case cooldown(seconds: Int)
        case pinNotConfigured
    }

    @Published var route: Route = .profileSetup
    @Published var profile: ChildProfileRecord?
    @Published var currentSession: SessionRuntime?
    @Published var latestSummary: SessionSummary?
    @Published var dashboard: DashboardSnapshot = .empty

    @Published var diagnosticSession: DiagnosticSessionRuntime?
    @Published var diagnosticResult: DiagnosticResult?
    @Published var adaptivePath: AdaptiveLessonPath = .empty
    @Published var curriculumCatalog: CurriculumCatalog
    @Published var diagnosticFeedbackMessage: String?
    @Published var diagnosticInteractionDisabled = false

    @Published var parentGateRequired = false
    @Published private(set) var parentPINConfigured = false
    @Published var parentGateLockedUntil: Date?
    @Published var statusMessage: String?

    @Published var selectedTheme: VisualTheme
    @Published var selectedCompanionID: String
    @Published var autoReadQuestions: Bool
    @Published var narrationStyle: NarrationStyle
    @Published var soundEffectsEnabled: Bool

    @Published var pendingStickerReward: Sticker?
    @Published var stickerCollection: StickerCollection = StickerCollection(stickers: [])
    @Published var showParentDashboard = false

    let repository: ProgressRepository
    let masteryEngine: MasteryEngine
    let sessionComposer: SessionComposer
    let hintEngine: DeterministicHintEngine
    let narrationService: NarrationService
    let sfxService: SFXService
    let contentPack: ContentPack
    let diagnosticService: DiagnosticService
    let adaptivePlanner: AdaptiveLessonPlanner
    let progressReportService: ProgressReportService
    let parentPINStore: ParentPINStoring

    private let defaults = UserDefaults.standard
    private let skipDiagnosticOnboarding: Bool
    private var temporarilySkippedDiagnostic = false
    private var diagnosticAdvanceTask: Task<Void, Never>?
    private var sessionAdvanceTask: Task<Void, Never>?
    private var questionReadTask: Task<Void, Never>?
    private var statusClearTask: Task<Void, Never>?
    private var parentGateFailureCount = 0
    private var pendingSettingsDismissAction: SettingsDismissAction?

    var availableCompanions: [ThemeCompanion] {
        CharacterPackLibrary.companions(for: selectedTheme)
    }

    var activeCompanion: ThemeCompanion {
        availableCompanions.first(where: { $0.id == selectedCompanionID }) ?? CharacterPackLibrary.defaultCompanion(for: selectedTheme)
    }

    init(
        repository: ProgressRepository? = nil,
        masteryEngine: MasteryEngine? = nil,
        sessionComposer: SessionComposer? = nil,
        hintEngine: DeterministicHintEngine? = nil,
        narrationService: NarrationService? = nil,
        sfxService: SFXService? = nil,
        contentPack: ContentPack? = nil,
        curriculumCatalog: CurriculumCatalog? = nil,
        diagnosticService: DiagnosticService? = nil,
        adaptivePlanner: AdaptiveLessonPlanner? = nil,
        parentPINStore: ParentPINStoring? = nil
    ) {
        let launchArgs = ProcessInfo.processInfo.arguments
        let isUITest = launchArgs.contains("-ui-test")
        skipDiagnosticOnboarding = isUITest || launchArgs.contains("-skip-diagnostic")

        if isUITest, let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }

        selectedTheme = VisualTheme.loadPersisted()
        selectedCompanionID = "" // placeholder — set after services are ready (line 142)
        autoReadQuestions = isUITest ? false : (UserDefaults.standard.object(forKey: "mathquest.autoReadQuestions") as? Bool ?? true)
        narrationStyle = NarrationStyle(rawValue: UserDefaults.standard.string(forKey: "mathquest.narrationStyle") ?? "") ?? .playful
        soundEffectsEnabled = isUITest ? false : (UserDefaults.standard.object(forKey: "mathquest.soundEffectsEnabled") as? Bool ?? true)

        NetworkGuard.assertOfflineOnly()

        let defaultCoreDataStack = isUITest ? CoreDataStack(inMemory: true) : CoreDataStack.shared
        let sharedRepository = repository ?? ProgressRepository(coreDataStack: defaultCoreDataStack)
        let pack: ContentPack
        if let contentPack {
            pack = contentPack
        } else {
            do {
                pack = try ContentLoader.loadDefaultPack()
            } catch {
                pack = .empty
            }
        }

        let catalog: CurriculumCatalog
        if let curriculumCatalog {
            catalog = curriculumCatalog
        } else {
            do {
                catalog = try CurriculumService.loadDefaultCatalog()
            } catch {
                catalog = .empty
            }
        }

        let deterministicSession = launchArgs.contains("-deterministic-session")
        let deterministicDiagnostic = deterministicSession || launchArgs.contains("-deterministic-diagnostic")

        self.repository = sharedRepository
        self.masteryEngine = masteryEngine ?? MasteryEngine(repository: sharedRepository)
        self.hintEngine = hintEngine ?? DeterministicHintEngine(contentPack: pack)
        self.sessionComposer = sessionComposer ?? SessionComposer(repository: sharedRepository, contentPack: pack, deterministic: deterministicSession)
        self.narrationService = narrationService ?? NarrationService()
        self.sfxService = sfxService ?? SFXService()
        self.contentPack = pack
        self.curriculumCatalog = catalog
        self.diagnosticService = diagnosticService ?? DiagnosticService(deterministic: deterministicDiagnostic)
        self.adaptivePlanner = adaptivePlanner ?? AdaptiveLessonPlanner()
        self.progressReportService = ProgressReportService(repository: sharedRepository, catalog: catalog)
        if let parentPINStore {
            self.parentPINStore = parentPINStore
        } else if isUITest {
            self.parentPINStore = InMemoryParentPINStore(initialPIN: "2468")
        } else {
            self.parentPINStore = KeychainParentPINStore()
        }
        self.parentPINConfigured = self.parentPINStore.isConfigured

        self.profile = sharedRepository.loadActiveProfile()
        selectedCompanionID = loadCompanion(for: selectedTheme)

        if let profile {
            diagnosticResult = loadDiagnosticResult(childID: profile.id)
            adaptivePath = self.adaptivePlanner.buildPath(result: diagnosticResult, catalog: catalog)
            refreshDashboard()
            if shouldRequireDiagnostic(for: profile.id) {
                route = .diagnostic
                startDiagnosticIfNeeded()
            } else {
                route = .home
            }
        } else {
            route = .profileSetup
            adaptivePath = self.adaptivePlanner.buildPath(result: nil, catalog: catalog)
        }
    }

    func createProfile(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let created = try repository.createOrLoadProfile(name: trimmed)
            profile = created
            refreshDashboard()

            diagnosticResult = loadDiagnosticResult(childID: created.id)
            adaptivePath = adaptivePlanner.buildPath(result: diagnosticResult, catalog: curriculumCatalog)
            refreshDashboard()

            if shouldRequireDiagnostic(for: created.id) {
                route = .diagnostic
                startDiagnosticIfNeeded()
                setStatus("Great. Quick diagnostic next to personalize lessons.")
            } else {
                route = .home
                setStatus("Welcome, \(created.displayName)!")
            }
        } catch {
            setStatus("Couldn't save profile. Please try again.")
        }
    }

    func startDiagnosticIfNeeded() {
        guard diagnosticSession == nil else { return }
        cancelQuestionReadTask()
        clearDiagnosticFeedbackState()
        diagnosticSession = diagnosticService.makeSession()
    }

    func submitDiagnosticChoice(_ choiceIndex: Int) {
        guard let session = diagnosticSession, !diagnosticInteractionDisabled else { return }
        let question = session.currentQuestion
        var updatedSession = session
        updatedSession.submit(choiceIndex: choiceIndex)
        playSFX(.tap)
        diagnosticFeedbackMessage = diagnosticFeedback(for: question, selectedIndex: choiceIndex)
        diagnosticInteractionDisabled = true
        narrationService.speakFeedback(diagnosticFeedbackMessage ?? "Thanks for showing your thinking.", style: narrationStyle, interrupt: true)

        diagnosticAdvanceTask?.cancel()
        diagnosticAdvanceTask = Task {
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            guard !Task.isCancelled else { return }
            if updatedSession.isComplete {
                finishDiagnostic(updatedSession)
            } else {
                diagnosticSession = updatedSession
                diagnosticFeedbackMessage = nil
                diagnosticInteractionDisabled = false
            }
        }
    }

    func submitDiagnosticDontKnow() {
        submitDiagnosticChoice(-1)
    }

    func skipDiagnosticForNow() {
        cancelQuestionReadTask()
        clearDiagnosticFeedbackState()
        temporarilySkippedDiagnostic = true
        diagnosticSession = nil
        route = .home
        setStatus("You can run the diagnostic anytime in Parent Settings.")
    }

    func retakeDiagnostic() {
        cancelQuestionReadTask()
        clearDiagnosticFeedbackState()
        diagnosticSession = diagnosticService.makeSession()
        route = .diagnostic
    }

    private func finishDiagnostic(_ session: DiagnosticSessionRuntime) {
        guard let profile else { return }
        clearDiagnosticFeedbackState()

        let result = diagnosticService.evaluate(session: session, childID: profile.id, catalog: curriculumCatalog)
        saveDiagnosticResult(result)

        diagnosticSession = nil
        diagnosticResult = result
        adaptivePath = adaptivePlanner.buildPath(result: result, catalog: curriculumCatalog)
        refreshDashboard()
        route = .home
        setStatus("Placement complete: \(result.placedGrade.title).")
        playSFX(.reward)
    }

    func startSession(for unit: UnitType) {
        guard let profile else { return }
        guard isUnitUnlocked(unit) else {
            setStatus("Complete the previous quest to unlock this unit.")
            return
        }

        do {
            cancelQuestionReadTask()
            let targetItemCount = FeatureFlags.adaptiveSessionItems(for: unit, placedGrade: diagnosticResult?.placedGrade)
            let blueprint = try sessionComposer.composeSession(
                childID: profile.id,
                focusUnit: unit,
                targetItemCount: targetItemCount
            )
            currentSession = SessionRuntime(blueprint: blueprint)
            route = .session
            playSFX(.tap)
        } catch {
            setStatus("Unable to start that quest right now.")
        }
    }

    func startRecommendedSession() {
        guard let unit = recommendedUnit() else {
            setStatus("No playable lesson is available yet for this path.")
            return
        }
        startSession(for: unit)
    }

    private func recommendedUnit() -> UnitType? {
        let completedUnits = Set(
            dashboard.unitProgress
                .filter { $0.completedSessions > 0 }
                .map(\.unit)
        )

        // 1. First playable, unlocked, uncompleted recommended lesson
        for lesson in adaptivePath.recommendedLessons where lesson.isPlayableInApp {
            if let linked = lesson.linkedUnit,
               isUnitUnlocked(linked),
               !completedUnits.contains(linked) {
                return linked
            }
        }

        // 2. Fallback: highest unlocked unit not yet completed. This keeps
        // progression moving even after the initial recommended slice has
        // been completed.
        if let next = dashboard.unitProgress
            .last(where: { $0.unlocked && $0.completedSessions == 0 }) {
            return next.unit
        }

        // 3. Highest unlocked unit (for replay after a full path clear)
        if let highestUnlocked = dashboard.unitProgress
            .last(where: { $0.unlocked }) {
            return highestUnlocked.unit
        }

        // 4. First playable, unlocked recommended lesson (even if completed — for review)
        for lesson in adaptivePath.recommendedLessons where lesson.isPlayableInApp {
            if let linked = lesson.linkedUnit, isUnitUnlocked(linked) {
                return linked
            }
        }

        // 5. Ultimate fallback
        return .kCountObjects
    }

    /// Whether the current recommendation is from the adaptive planner
    /// or a generic fallback. Used to adjust UI messaging.
    var isRecommendationPersonalized: Bool {
        guard !adaptivePath.recommendedLessons.isEmpty else { return false }
        let completedUnits = Set(
            dashboard.unitProgress
                .filter { $0.completedSessions > 0 }
                .map(\.unit)
        )
        return adaptivePath.recommendedLessons.contains { lesson in
            lesson.isPlayableInApp
            && lesson.linkedUnit != nil
            && isUnitUnlocked(lesson.linkedUnit!)
            && !completedUnits.contains(lesson.linkedUnit!)
        }
    }

    func openLessonPlans() {
        route = .lessonPlans
    }

    func closeLessonPlans() {
        route = .home
    }

    func submitAnswer(answer: String, inputMode: InputMode, latencyMs: Double) {
        guard let profile, var runtime = currentSession else { return }
        cancelQuestionReadTask()
        let item = runtime.currentItem
        let isCorrect = runtime.evaluate(answer: answer)

        let attempt = AttemptInput(
            childID: profile.id,
            skillID: item.skillID,
            unit: item.unit,
            itemID: item.id,
            sessionID: runtime.sessionID,
            response: answer,
            correct: isCorrect,
            latencyMs: latencyMs,
            hintsUsed: Int16(runtime.hintsUsedForCurrentItem),
            inputMode: inputMode
        )

        do {
            let masteryState = try masteryEngine.recordAttempt(attempt)
            runtime.recordSubmission(correct: isCorrect)

            // Update session immediately so progress bar reflects the answered item
            currentSession = runtime
            playSFX(isCorrect ? .correct : .incorrect)
            setStatus(masteryState.status == .mastered ? "Skill mastered!" : nil)

            if runtime.pendingCorrection {
                // Two wrong answers — show correction overlay (no auto-advance).
                let correctionPhrase = CompanionPhrases.correction(tone: activeCompanion.tone)
                narrationService.speakFeedback(correctionPhrase, style: narrationStyle)
            } else {
                narrationService.speakFeedback(isCorrect ? PraiseLibrary.randomCorrectPraise() : PraiseLibrary.randomRetryPrompt(), style: narrationStyle)

                // After a brief delay, advance to the next question (or complete)
                let feedbackDelayNs: UInt64 = isCorrect ? 1_200_000_000 : 1_800_000_000
                sessionAdvanceTask?.cancel()
                sessionAdvanceTask = Task { [weak self] in
                    try? await Task.sleep(nanoseconds: feedbackDelayNs)
                    guard !Task.isCancelled, let self else { return }
                    guard var rt = currentSession, rt.pendingAdvance else { return }
                    rt.advanceIfPending()

                    if rt.isComplete {
                        finishSession(rt, lastItem: item, lastCorrect: isCorrect)
                    } else {
                        currentSession = rt
                    }
                }
            }
        } catch {
            setStatus("We couldn't save that attempt.")
        }
    }

    func acknowledgeCorrection() {
        guard profile != nil, var runtime = currentSession, runtime.pendingCorrection else { return }
        cancelQuestionReadTask()
        runtime.acknowledgeCorrection()

        if runtime.isComplete {
            guard let lastItem = runtime.items.last else { return }
            finishSession(runtime, lastItem: lastItem, lastCorrect: false)
        } else {
            currentSession = runtime
        }
    }

    private func finishSession(_ rt: SessionRuntime, lastItem: PracticeItem, lastCorrect: Bool) {
        guard let profile else { return }
        cancelQuestionReadTask()
        let reward = contentPack.rewards.randomElement()?.title ?? "Explorer Sticker"
        let summary = SessionSummary(
            sessionID: rt.sessionID,
            unit: rt.focusUnit,
            totalItems: rt.items.count,
            correctItems: rt.correctCount,
            rewardTitle: reward,
            nextRecommendation: masteryEngine.nextRecommendation(for: lastItem.skillID, childID: profile.id),
            missedItems: rt.missedItems
        )

        do {
            try repository.finishSession(
                sessionID: rt.sessionID,
                childID: profile.id,
                unit: rt.focusUnit,
                totalItems: Int16(rt.items.count),
                correctItems: Int16(rt.correctCount),
                rewardTitle: reward
            )
        } catch {
        }

        latestSummary = summary
        currentSession = nil
        refreshDashboard()
        checkAndAwardSticker(for: rt.focusUnit)
        route = .summary
        narrationService.speakFeedback(lastCorrect ? "Great finish!" : "Nice persistence. You did it!", style: narrationStyle, interrupt: true)
        playSFX(.reward)
    }

    func requestHint() -> HintAction? {
        guard var runtime = currentSession else { return nil }
        cancelQuestionReadTask()
        let context = AttemptContext(
            unit: runtime.currentItem.unit,
            skillID: runtime.currentItem.skillID,
            prompt: runtime.currentItem.prompt,
            payload: runtime.currentItem.payload,
            incorrectAttempts: runtime.incorrectAttemptsForCurrentItem,
            recentMisconceptions: runtime.recentMisconceptions,
            supports: runtime.currentItem.supports
        )

        let hint = hintEngine.nextHint(for: context)
        runtime.registerHintUse()
        currentSession = runtime
        narrationService.speakFeedback(hint.encouragementLine, style: narrationStyle, interrupt: true)
        playSFX(.hint)
        return hint
    }

    func replayPrompt() {
        guard let item = currentSession?.currentItem else { return }
        narrationService.speakQuestion(item.narrationText, style: narrationStyle, interrupt: true, itemID: item.templateID)
    }

    func readQuestionIfEnabled() {
        questionReadTask?.cancel()
        guard autoReadQuestions, let runtime = currentSession else { return }
        let expectedSessionID = runtime.sessionID
        let expectedItemID = runtime.currentItem.id
        let narrationText = runtime.currentItem.narrationText
        let templateID = runtime.currentItem.templateID

        // Wait for any feedback audio to finish, then a short visual pause.
        questionReadTask = Task { [weak self] in
            // Wait up to 4 seconds for feedback audio to finish
            for _ in 0..<40 {
                guard !Task.isCancelled else { return }
                if self?.narrationService.isSpeaking != true { break }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
            // Abort if audio is still playing after timeout (avoid overlap)
            guard !Task.isCancelled, self?.narrationService.isSpeaking != true else { return }
            // Short pause so the child can see the new question before audio starts
            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s
            guard
                !Task.isCancelled,
                let self,
                let current = self.currentSession,
                current.sessionID == expectedSessionID,
                current.currentItem.id == expectedItemID
            else {
                return
            }
            self.narrationService.speakQuestion(narrationText, style: self.narrationStyle, interrupt: true, itemID: templateID)
        }
    }

    func replayDiagnosticPrompt() {
        guard let question = diagnosticSession?.currentQuestion else { return }
        narrationService.speakQuestion(question.prompt, style: narrationStyle, interrupt: true, itemID: question.id)
    }

    func readDiagnosticPromptIfEnabled() {
        guard autoReadQuestions else { return }
        replayDiagnosticPrompt()
    }

    private func diagnosticFeedback(for question: DiagnosticQuestion, selectedIndex: Int) -> String {
        if selectedIndex == -1 {
            return "Thanks for telling me. I will use that to find a better starting point."
        }

        if selectedIndex == question.correctIndex {
            switch question.domain {
            case .numberSense:
                return "Nice number sense. I am noting how confidently that was solved."
            case .operations:
                return "Strong thinking. I am using that strategy signal for the next question."
            case .placeValue:
                return "Nice place-value thinking. That helps tune the next level."
            case .problemSolving:
                return "Good reasoning. I am checking how stories and equations connect."
            case .geometry:
                return "Nice noticing. That helps me place the next shape or measurement task."
            case .measurement:
                return "Careful measurement thinking. I am using that to shape the next task."
            case .fractions:
                return "Nice fraction reasoning. That gives me a clearer picture of the right level."
            }
        }

        return "Thanks for showing your thinking. I will use that to choose the next challenge."
    }

    private func clearDiagnosticFeedbackState() {
        diagnosticAdvanceTask?.cancel()
        diagnosticAdvanceTask = nil
        diagnosticFeedbackMessage = nil
        diagnosticInteractionDisabled = false
    }

    func setTheme(_ theme: VisualTheme) {
        selectedTheme = theme
        VisualTheme.persist(theme)
        selectedCompanionID = loadCompanion(for: theme)
        defaults.set(selectedCompanionID, forKey: companionStorageKey(for: theme))
    }

    func setCompanion(_ companionID: String) {
        guard availableCompanions.contains(where: { $0.id == companionID }) else { return }
        selectedCompanionID = companionID
        defaults.set(companionID, forKey: companionStorageKey(for: selectedTheme))
    }

    func setAutoReadQuestions(_ enabled: Bool) {
        autoReadQuestions = enabled
        if !enabled {
            cancelQuestionReadTask()
        }
        defaults.set(enabled, forKey: "mathquest.autoReadQuestions")
    }

    func setNarrationStyle(_ style: NarrationStyle) {
        narrationStyle = style
        defaults.set(style.rawValue, forKey: "mathquest.narrationStyle")
    }

    func previewNarrationStyle() {
        narrationService.preview(style: narrationStyle)
    }

    func setSoundEffectsEnabled(_ enabled: Bool) {
        soundEffectsEnabled = enabled
        defaults.set(enabled, forKey: "mathquest.soundEffectsEnabled")
    }

    func previewSoundEffects() {
        playSFX(.reward)
    }

    func goHome() {
        sessionAdvanceTask?.cancel()
        sessionAdvanceTask = nil
        cancelQuestionReadTask()
        route = profile == nil ? .profileSetup : .home
        currentSession = nil
        latestSummary = nil
        refreshDashboard()
    }

    func showParentGate() {
        clearExpiredParentGateCooldown()
        parentGateRequired = true
    }

    func submitParentGate(answer: String, now: Date = .now) -> ParentGateResult {
        clearExpiredParentGateCooldown(now: now)

        guard parentPINConfigured else {
            return .pinNotConfigured
        }

        if let lockedUntil = parentGateLockedUntil, lockedUntil > now {
            return .cooldown(seconds: cooldownSeconds(until: lockedUntil, now: now))
        }

        let sanitizedAnswer = ParentPINPolicy.sanitize(answer.trimmingCharacters(in: .whitespacesAndNewlines))
        let isCorrect = parentPINStore.verify(pin: sanitizedAnswer)
        if isCorrect {
            parentGateFailureCount = 0
            parentGateLockedUntil = nil
            parentGateRequired = false
            return .unlocked
        }

        parentGateFailureCount += 1
        let remainingAttempts = max(0, 3 - parentGateFailureCount)
        if remainingAttempts == 0 {
            let lockedUntil = now.addingTimeInterval(20)
            parentGateFailureCount = 0
            parentGateLockedUntil = lockedUntil
            return .cooldown(seconds: cooldownSeconds(until: lockedUntil, now: now))
        }

        return .incorrect(remainingAttempts: remainingAttempts)
    }

    func saveParentPIN(_ pin: String) throws {
        try parentPINStore.save(pin: pin)
        parentPINConfigured = parentPINStore.isConfigured
        parentGateFailureCount = 0
        parentGateLockedUntil = nil
        parentGateRequired = false
    }

    var isParentGateLocked: Bool {
        guard let lockedUntil = parentGateLockedUntil else { return false }
        return lockedUntil > .now
    }

    var parentGateCooldownSecondsRemaining: Int? {
        guard let lockedUntil = parentGateLockedUntil, lockedUntil > .now else { return nil }
        return cooldownSeconds(until: lockedUntil, now: .now)
    }

    func scheduleDiagnosticRetakeAfterSettingsDismissal() {
        pendingSettingsDismissAction = .retakeDiagnostic
    }

    func handleSettingsDismissal() {
        guard let action = pendingSettingsDismissAction else { return }
        pendingSettingsDismissAction = nil

        switch action {
        case .retakeDiagnostic:
            retakeDiagnostic()
        }
    }

    func resetLearningData() {
        guard let profile else { return }

        do {
            try repository.deleteLearningData(childID: profile.id, deleteProfile: false)
            clearDiagnosticResult(childID: profile.id)
            cancelQuestionReadTask()
            clearDiagnosticFeedbackState()
            sessionAdvanceTask?.cancel()
            sessionAdvanceTask = nil
            pendingSettingsDismissAction = nil
            currentSession = nil
            latestSummary = nil
            pendingStickerReward = nil
            diagnosticSession = nil
            diagnosticResult = nil
            temporarilySkippedDiagnostic = false
            showParentDashboard = false
            refreshDashboard()
            route = .home
            setStatus("Learning progress reset on this device.")
        } catch {
            setStatus("Couldn't reset local learning data.")
        }
    }

    func deleteProfileAndData() {
        guard let profile else { return }

        do {
            try repository.deleteLearningData(childID: profile.id, deleteProfile: true)
            clearDiagnosticResult(childID: profile.id)
            cancelQuestionReadTask()
            clearDiagnosticFeedbackState()
            sessionAdvanceTask?.cancel()
            sessionAdvanceTask = nil
            pendingSettingsDismissAction = nil
            currentSession = nil
            latestSummary = nil
            pendingStickerReward = nil
            diagnosticSession = nil
            diagnosticResult = nil
            temporarilySkippedDiagnostic = false
            showParentDashboard = false
            parentGateFailureCount = 0
            parentGateLockedUntil = nil
            parentGateRequired = false
            dashboard = .empty
            stickerCollection = StickerCollection(stickers: [])
            adaptivePath = adaptivePlanner.buildPath(result: nil, catalog: curriculumCatalog)
            self.profile = nil
            route = .profileSetup
            setStatus("Child profile and local learning data deleted.")
        } catch {
            setStatus("Couldn't delete the child profile.")
        }
    }

    func isUnitUnlocked(_ unit: UnitType) -> Bool {
        dashboard.unitProgress.first(where: { $0.unit == unit })?.unlocked ?? (unit == .kCountObjects)
    }

    private func shouldRequireDiagnostic(for childID: UUID) -> Bool {
        guard !skipDiagnosticOnboarding else { return false }
        guard !temporarilySkippedDiagnostic else { return false }
        return loadDiagnosticResult(childID: childID) == nil
    }

    private func diagnosticStorageKey(for childID: UUID) -> String {
        "mathquest.diagnostic.\(childID.uuidString.lowercased())"
    }

    private func companionStorageKey(for theme: VisualTheme) -> String {
        "mathquest.selectedCompanion.\(theme.rawValue)"
    }

    private func loadCompanion(for theme: VisualTheme) -> String {
        let stored = defaults.string(forKey: companionStorageKey(for: theme))
        let available = CharacterPackLibrary.companions(for: theme)
        return available.first(where: { $0.id == stored })?.id ?? CharacterPackLibrary.defaultCompanion(for: theme).id
    }

    private func loadDiagnosticResult(childID: UUID) -> DiagnosticResult? {
        guard let data = defaults.data(forKey: diagnosticStorageKey(for: childID)) else {
            return nil
        }
        return try? JSONDecoder().decode(DiagnosticResult.self, from: data)
    }

    private func clearDiagnosticResult(childID: UUID) {
        defaults.removeObject(forKey: diagnosticStorageKey(for: childID))
    }

    private func saveDiagnosticResult(_ result: DiagnosticResult) {
        guard let encoded = try? JSONEncoder().encode(result) else { return }
        defaults.set(encoded, forKey: diagnosticStorageKey(for: result.childID))
    }

    private func setStatus(_ message: String?, autoClearSeconds: Double = 4.0) {
        statusClearTask?.cancel()
        statusMessage = message
        guard message != nil else { return }
        statusClearTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(autoClearSeconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            statusMessage = nil
        }
    }

    private func cancelQuestionReadTask() {
        questionReadTask?.cancel()
        questionReadTask = nil
    }

    private func clearExpiredParentGateCooldown(now: Date = .now) {
        guard let lockedUntil = parentGateLockedUntil, lockedUntil <= now else { return }
        parentGateLockedUntil = nil
    }

    private func cooldownSeconds(until lockedUntil: Date, now: Date) -> Int {
        max(1, Int(ceil(lockedUntil.timeIntervalSince(now))))
    }

    private func playSFX(_ event: SFXEvent) {
        guard soundEffectsEnabled else { return }
        sfxService.play(event, theme: selectedTheme)
    }

    private func refreshDashboard() {
        guard let profile else {
            dashboard = .empty
            return
        }

        let unitCounts = repository.unitSessionCounts(childID: profile.id)
        var unlockedUnits: Set<UnitType> = [.kCountObjects]
        let path = UnitType.learningPath
        let placementIndex = placementUnlockIndex(for: diagnosticResult?.placedGrade)

        if placementIndex >= 0 {
            for idx in 0...min(placementIndex, path.count - 1) {
                unlockedUnits.insert(path[idx])
            }
        }

        for (index, unit) in path.enumerated() where index > 0 {
            let previous = path[index - 1]
            if (unitCounts[previous] ?? 0) > 0 {
                unlockedUnits.insert(unit)
            }
        }

        let progress: [UnitProgress] = path.map { unit in
            UnitProgress(
                unit: unit,
                completedSessions: unitCounts[unit] ?? 0,
                unlocked: unlockedUnits.contains(unit)
            )
        }

        dashboard = DashboardSnapshot(
            completedSessions: repository.completedSessionCount(childID: profile.id),
            averageAccuracy: repository.averageAccuracy(childID: profile.id),
            streakDays: repository.streakDays(childID: profile.id),
            unitProgress: progress
        )
        refreshStickerCollection()

        // Rebuild adaptive path so recommendations reflect latest progress
        adaptivePath = adaptivePlanner.buildPath(result: diagnosticResult, catalog: curriculumCatalog)
    }

    private func placementUnlockIndex(for grade: GradeBand?) -> Int {
        guard let grade else { return 0 }
        switch grade {
        case .kindergarten: return 7   // unlock through teenPlaceValue (index 7)
        case .grade1: return 12        // unlock through g1MeasureLength (index 12)
        case .grade2: return 20        // unlock through g2DataIntro (index 20)
        case .grade3: return 26        // unlock through g3MultiStep (index 26)
        case .grade4: return 32        // unlock through g4AngleMeasure (index 32)
        case .grade5: return 37        // unlock through g5PreRatios (index 37)
        }
    }

    // MARK: - Stickers

    func openStickerBook() {
        route = .stickerBook
    }

    func checkAndAwardSticker(for unit: UnitType) {
        guard let profile else { return }
        let progress = dashboard.unitProgress.first(where: { $0.unit == unit })
        guard let progress, progress.completedSessions >= 1 else { return }
        let already = stickerCollection.stickers.first(where: { $0.unitType == unit })
        guard already?.isUnlocked != true else { return }
        try? repository.saveStickerEarned(childID: profile.id, unitRaw: unit.rawValue, dateEarned: .now)
        refreshStickerCollection()
        pendingStickerReward = Sticker(unitType: unit, dateEarned: .now)
    }

    func refreshStickerCollection() {
        guard let profile else { return }
        let records = repository.fetchStickers(childID: profile.id)
        stickerCollection = StickerCollection.build(from: records)
    }

    // MARK: - Progress Report

    var progressReport: ProgressReport {
        guard let profile else { return .empty }
        return progressReportService.buildReport(
            for: profile,
            dashboard: dashboard,
            placedGrade: adaptivePath.placedGrade
        )
    }

    // MARK: - Skill Trail

    var skillTrail: SkillTrail {
        SkillTrail.build(
            dashboard: dashboard,
            stickerCollection: stickerCollection
        )
    }
}
