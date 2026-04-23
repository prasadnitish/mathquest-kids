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

    enum PreferenceKey {
        static let autoReadQuestions = "mathquest.autoReadQuestions"
        static let narrationStyle = "mathquest.narrationStyle"
        static let soundEffectsEnabled = "mathquest.soundEffectsEnabled"

        static func diagnosticResult(for childID: UUID) -> String {
            "mathquest.diagnostic.\(childID.uuidString.lowercased())"
        }

        static func selectedCompanion(for theme: VisualTheme) -> String {
            "mathquest.selectedCompanion.\(theme.rawValue)"
        }
    }

    enum Timing {
        static let diagnosticAdvanceDelayNs: UInt64 = 1_100_000_000
        static let correctAnswerAdvanceDelayNs: UInt64 = 1_200_000_000
        static let incorrectAnswerAdvanceDelayNs: UInt64 = 1_800_000_000
        static let incorrectAnswerResetDelayNs: UInt64 = 1_000_000_000
        static let questionReadPauseDelayNs: UInt64 = 600_000_000
        static let narrationPollIntervalNs: UInt64 = 100_000_000
        static let narrationPollCount = 40
    }

    enum ParentGatePolicy {
        static let maxAttempts = 3
        static let cooldownSeconds: TimeInterval = 20
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
    @Published var parentPINConfigured = false
    @Published var parentGateLockedUntil: Date?
    @Published var statusMessage: String?

    @Published var selectedTheme: VisualTheme
    @Published var selectedCompanionID: String
    @Published var autoReadQuestions: Bool
    @Published var narrationStyle: NarrationStyle
    @Published var soundEffectsEnabled: Bool

    @Published var pendingStickerReward: Sticker?
    @Published var pendingChapterCelebration: ChapterCelebration?
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

    let defaults = UserDefaults.standard
    let skipDiagnosticOnboarding: Bool
    var temporarilySkippedDiagnostic = false
    var diagnosticAdvanceTask: Task<Void, Never>?
    var sessionAdvanceTask: Task<Void, Never>?
    var questionReadTask: Task<Void, Never>?
    var statusClearTask: Task<Void, Never>?
    var parentGateFailureCount = 0
    var pendingSettingsDismissAction: SettingsDismissAction?

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
        autoReadQuestions = isUITest ? false : (UserDefaults.standard.object(forKey: PreferenceKey.autoReadQuestions) as? Bool ?? true)
        narrationStyle = NarrationStyle(rawValue: UserDefaults.standard.string(forKey: PreferenceKey.narrationStyle) ?? "") ?? .playful
        soundEffectsEnabled = isUITest ? false : (UserDefaults.standard.object(forKey: PreferenceKey.soundEffectsEnabled) as? Bool ?? true)

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
}
