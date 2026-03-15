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
    @Published var parentGatePrompt = ParentGateChallenge.newChallenge()
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
    let diagnostics: DiagnosticsLogger

    private let defaults = UserDefaults.standard
    private let skipDiagnosticOnboarding: Bool
    private var temporarilySkippedDiagnostic = false
    private var diagnosticAdvanceTask: Task<Void, Never>?
    private var sessionAdvanceTask: Task<Void, Never>?
    private var statusClearTask: Task<Void, Never>?

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
        diagnostics: DiagnosticsLogger? = nil
    ) {
        let launchArgs = ProcessInfo.processInfo.arguments
        let isUITest = launchArgs.contains("-ui-test")
        skipDiagnosticOnboarding = isUITest || launchArgs.contains("-skip-diagnostic")
        let diagnostics = diagnostics ?? DiagnosticsLogger.shared

        selectedTheme = VisualTheme.loadPersisted()
        selectedCompanionID = UserDefaults.standard.string(forKey: "mathquest.selectedCompanion.\(VisualTheme.loadPersisted().rawValue)")
            ?? CharacterPackLibrary.defaultCompanion(for: VisualTheme.loadPersisted()).id
        autoReadQuestions = isUITest ? false : (UserDefaults.standard.object(forKey: "mathquest.autoReadQuestions") as? Bool ?? true)
        narrationStyle = NarrationStyle(rawValue: UserDefaults.standard.string(forKey: "mathquest.narrationStyle") ?? "") ?? .playful
        soundEffectsEnabled = isUITest ? false : (UserDefaults.standard.object(forKey: "mathquest.soundEffectsEnabled") as? Bool ?? true)

        NetworkGuard.assertOfflineOnly()

        let sharedRepository = repository ?? ProgressRepository(coreDataStack: CoreDataStack.shared)
        let pack: ContentPack
        if let contentPack {
            pack = contentPack
        } else {
            do {
                pack = try ContentLoader.loadDefaultPack()
                diagnostics.info("Loaded content pack", metadata: ["units": "\(pack.units.count)", "lessons": "\(pack.lessons.count)"])
            } catch {
                diagnostics.error("Failed to load content pack; using empty fallback", metadata: ["error": error.localizedDescription])
                pack = .empty
            }
        }

        let catalog: CurriculumCatalog
        if let curriculumCatalog {
            catalog = curriculumCatalog
        } else {
            do {
                catalog = try CurriculumService.loadDefaultCatalog()
                diagnostics.info("Loaded curriculum catalog", metadata: ["grades": "\(catalog.grades.count)"])
            } catch {
                diagnostics.error("Failed to load curriculum catalog; using empty fallback", metadata: ["error": error.localizedDescription])
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
        self.diagnostics = diagnostics

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

        diagnostics.info(
            "App state initialized",
            metadata: [
                "route": String(describing: route),
                "theme": selectedTheme.rawValue,
                "hasProfile": "\(profile != nil)"
            ]
        )
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
                diagnostics.info("Profile created; diagnostic required", metadata: ["childId": created.id.uuidString])
            } else {
                route = .home
                setStatus("Welcome, \(created.displayName)!")
                diagnostics.info("Profile created", metadata: ["childId": created.id.uuidString])
            }
        } catch {
            diagnostics.error("Profile creation failed", metadata: ["error": error.localizedDescription])
            setStatus("Couldn't save profile. Please try again.")
        }
    }

    func startDiagnosticIfNeeded() {
        guard diagnosticSession == nil else { return }
        clearDiagnosticFeedbackState()
        diagnosticSession = diagnosticService.makeSession()
        diagnostics.info("Diagnostic session started")
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
        diagnostics.info("Diagnostic answer: I don't know")
        submitDiagnosticChoice(-1)
    }

    func skipDiagnosticForNow() {
        clearDiagnosticFeedbackState()
        temporarilySkippedDiagnostic = true
        diagnosticSession = nil
        route = .home
        setStatus("You can run the diagnostic anytime in Parent Settings.")
        diagnostics.info("Diagnostic skipped for now")
    }

    func retakeDiagnostic() {
        clearDiagnosticFeedbackState()
        diagnosticSession = diagnosticService.makeSession()
        route = .diagnostic
        diagnostics.info("Diagnostic retake started")
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
        diagnostics.info(
            "Diagnostic finished",
            metadata: [
                "placedGrade": result.placedGrade.rawValue,
                "overallScore": String(format: "%.3f", result.overallScore)
            ]
        )
    }

    func startSession(for unit: UnitType) {
        guard let profile else { return }
        guard isUnitUnlocked(unit) else {
            setStatus("Complete the previous quest to unlock this unit.")
            diagnostics.warning("Attempted to start locked unit", metadata: ["unit": unit.rawValue])
            return
        }

        do {
            let targetItemCount = FeatureFlags.adaptiveSessionItems(for: unit, placedGrade: diagnosticResult?.placedGrade)
            let blueprint = try sessionComposer.composeSession(
                childID: profile.id,
                focusUnit: unit,
                targetItemCount: targetItemCount
            )
            currentSession = SessionRuntime(blueprint: blueprint)
            route = .session
            playSFX(.tap)
            diagnostics.info(
                "Session started",
                metadata: [
                    "unit": unit.rawValue,
                    "sessionId": blueprint.sessionID.uuidString,
                    "items": "\(blueprint.items.count)",
                    "placedGrade": diagnosticResult?.placedGrade.rawValue ?? "none"
                ]
            )
        } catch {
            diagnostics.error("Session composition failed", metadata: ["unit": unit.rawValue, "error": error.localizedDescription])
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

        // 2. First playable, unlocked recommended lesson (even if completed — for review)
        for lesson in adaptivePath.recommendedLessons where lesson.isPlayableInApp {
            if let linked = lesson.linkedUnit, isUnitUnlocked(linked) {
                return linked
            }
        }

        // 3. Fallback: highest unlocked unit not yet completed
        if let next = dashboard.unitProgress
            .last(where: { $0.unlocked && $0.completedSessions == 0 }) {
            return next.unit
        }

        // 4. Ultimate fallback: highest unlocked unit (for replay)
        return dashboard.unitProgress
            .last(where: { $0.unlocked })?
            .unit ?? .kCountObjects
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
            diagnostics.error(
                "Failed to persist attempt",
                metadata: [
                    "skillId": item.skillID,
                    "sessionId": runtime.sessionID.uuidString,
                    "error": error.localizedDescription
                ]
            )
            setStatus("We couldn't save that attempt.")
        }
    }

    func acknowledgeCorrection() {
        guard profile != nil, var runtime = currentSession, runtime.pendingCorrection else { return }
        runtime.acknowledgeCorrection()

        if runtime.isComplete {
            finishSession(runtime, lastItem: runtime.items.last!, lastCorrect: false)
        } else {
            currentSession = runtime
        }
    }

    private func finishSession(_ rt: SessionRuntime, lastItem: PracticeItem, lastCorrect: Bool) {
        guard let profile else { return }
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
            diagnostics.error("Failed to finish session", metadata: ["error": error.localizedDescription])
        }

        latestSummary = summary
        currentSession = nil
        refreshDashboard()
        checkAndAwardSticker(for: rt.focusUnit)
        route = .summary
        narrationService.speakFeedback(lastCorrect ? "Great finish!" : "Nice persistence. You did it!", style: narrationStyle, interrupt: true)
        playSFX(.reward)
        diagnostics.info(
            "Session completed",
            metadata: [
                "sessionId": rt.sessionID.uuidString,
                "unit": rt.focusUnit.rawValue,
                "correct": "\(rt.correctCount)",
                "total": "\(rt.items.count)"
            ]
        )
    }

    func requestHint() -> HintAction? {
        guard var runtime = currentSession else { return nil }
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
        guard autoReadQuestions else { return }
        // Wait for any feedback audio to finish, then a short visual pause
        Task {
            // Wait up to 4 seconds for feedback audio to finish
            for _ in 0..<40 {
                if !narrationService.isSpeaking { break }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
            // Short pause so the child can see the new question before audio starts
            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s
            replayPrompt()
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
        diagnostics.info("Theme changed", metadata: ["theme": theme.rawValue])
    }

    func setCompanion(_ companionID: String) {
        guard availableCompanions.contains(where: { $0.id == companionID }) else { return }
        selectedCompanionID = companionID
        defaults.set(companionID, forKey: companionStorageKey(for: selectedTheme))
    }

    func setAutoReadQuestions(_ enabled: Bool) {
        autoReadQuestions = enabled
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
        route = profile == nil ? .profileSetup : .home
        currentSession = nil
        latestSummary = nil
        refreshDashboard()
        diagnostics.debug("Navigated to home", metadata: ["route": String(describing: route)])
    }

    func showParentGate() {
        parentGatePrompt = ParentGateChallenge.newChallenge()
        parentGateRequired = true
    }

    func validateParentGate(answer: String) -> Bool {
        let isCorrect = answer.trimmingCharacters(in: .whitespacesAndNewlines) == parentGatePrompt.answer
        if isCorrect {
            parentGateRequired = false
            diagnostics.info("Parent gate unlocked")
        } else {
            diagnostics.warning("Parent gate failed attempt")
        }
        return isCorrect
    }

    func exportDiagnosticsFile() throws -> URL {
        do {
            return try diagnostics.exportDiagnosticsFile()
        } catch {
            diagnostics.error("Diagnostics export failed", metadata: ["error": error.localizedDescription])
            throw error
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

struct ParentGateChallenge {
    let prompt: String
    let answer: String

    static func newChallenge() -> ParentGateChallenge {
        // Simple single-digit multiplication — easy for parents, hard for K-2 kids.
        let left = Int.random(in: 6...9)
        let right = Int.random(in: 6...9)
        return ParentGateChallenge(prompt: "Parent check: \(left) \u{00D7} \(right) = ?", answer: String(left * right))
    }
}
