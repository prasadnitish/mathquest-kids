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
    private var statusDismissTask: Task<Void, Never>?

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
            refreshDashboard()
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
                showStatus("Great. Quick diagnostic next to personalize lessons.")
                diagnostics.info("Profile created; diagnostic required", metadata: ["childId": created.id.uuidString])
            } else {
                route = .home
                showStatus("Welcome, \(created.displayName)!")
                diagnostics.info("Profile created", metadata: ["childId": created.id.uuidString])
            }
        } catch {
            diagnostics.error("Profile creation failed", metadata: ["error": error.localizedDescription])
            showStatus("Couldn't save profile. Please try again.")
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
        showStatus("You can run the diagnostic anytime in Parent Settings.")
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
        showStatus("Placement complete: \(result.placedGrade.title).")
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
            showStatus("Complete the previous quest to unlock this unit.")
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
            showStatus("Unable to start that quest right now.")
        }
    }

    func startRecommendedSession() {
        guard let unit = recommendedUnit() else {
            showStatus("No playable lesson is available yet for this path.")
            return
        }
        startSession(for: unit)
    }

    private func recommendedUnit() -> UnitType? {
        for lesson in adaptivePath.recommendedLessons where lesson.isPlayableInApp {
            if let linked = lesson.linkedUnit, isUnitUnlocked(linked) {
                return linked
            }
        }

        return dashboard.unitProgress
            .first(where: { $0.unlocked })?
            .unit ?? .subtractionStories
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

            if runtime.isComplete {
                let reward = contentPack.rewards.randomElement()?.title ?? "Explorer Sticker"
                let summary = SessionSummary(
                    sessionID: runtime.sessionID,
                    unit: runtime.focusUnit,
                    totalItems: runtime.items.count,
                    correctItems: runtime.correctCount,
                    rewardTitle: reward,
                    nextRecommendation: masteryEngine.nextRecommendation(for: item.skillID, childID: profile.id)
                )

                try repository.finishSession(
                    sessionID: runtime.sessionID,
                    childID: profile.id,
                    unit: runtime.focusUnit,
                    totalItems: Int16(runtime.items.count),
                    correctItems: Int16(runtime.correctCount),
                    rewardTitle: reward
                )

                latestSummary = summary
                currentSession = nil
                refreshDashboard()
                checkAndAwardSticker(for: runtime.focusUnit)
                route = .summary
                narrationService.speakFeedback(isCorrect ? "Great finish!" : "Nice persistence. You did it!", style: narrationStyle, interrupt: true)
                playSFX(.reward)
                diagnostics.info(
                    "Session completed",
                    metadata: [
                        "sessionId": runtime.sessionID.uuidString,
                        "unit": runtime.focusUnit.rawValue,
                        "correct": "\(runtime.correctCount)",
                        "total": "\(runtime.items.count)"
                    ]
                )
            } else {
                currentSession = runtime
                narrationService.speakFeedback(isCorrect ? PraiseLibrary.randomCorrectPraise() : PraiseLibrary.randomRetryPrompt(), style: narrationStyle)
                if masteryState.status == .mastered { showStatus("Skill mastered!") }
                playSFX(isCorrect ? .correct : .incorrect)
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
            showStatus("We couldn't save that attempt.")
        }
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
        narrationService.speakFeedback("\(hint.encouragementLine) \(hint.text)", style: narrationStyle, interrupt: true)
        playSFX(.hint)
        return hint
    }

    func replayPrompt() {
        guard let item = currentSession?.currentItem else { return }
        narrationService.speakQuestion(item.narrationText, style: narrationStyle, interrupt: true, itemID: item.templateID)
    }

    func readQuestionIfEnabled() {
        guard autoReadQuestions else { return }
        // Short delay so the child can see the new question before audio starts
        Task {
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
        dashboard.unitProgress.first(where: { $0.unit == unit })?.unlocked ?? (unit == .subtractionStories)
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

    private func showStatus(_ message: String, duration: TimeInterval = 4) {
        statusDismissTask?.cancel()
        statusMessage = message
        statusDismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.statusMessage = nil
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
        var unlockedUnits: Set<UnitType> = [.subtractionStories]
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
    }

    private func placementUnlockIndex(for grade: GradeBand?) -> Int {
        guard let grade else { return 0 }
        switch grade {
        case .kindergarten: return 1
        case .grade1: return 2
        case .grade2: return 3
        case .grade3: return 4
        case .grade4: return 5
        case .grade5: return UnitType.learningPath.count - 1
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
        let left = Int.random(in: 2...9)
        let right = Int.random(in: 2...9)
        return ParentGateChallenge(prompt: "Parent check: \(left) + \(right) = ?", answer: String(left + right))
    }
}
