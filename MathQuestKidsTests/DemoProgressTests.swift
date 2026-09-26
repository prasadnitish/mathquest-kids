import Foundation
import Testing
@testable import MathQuestKids

/// The sample profile used when filming the app. The promo videos show its parent
/// dashboard, so check it reads the way the videos describe it.
struct DemoProgressTests {
    @Test @MainActor
    func demoProgressFillsTheParentDashboard() throws {
        let repository = ProgressRepository(coreDataStack: CoreDataStack(inMemory: true))
        let pack = try ContentLoader.loadDefaultPack()
        let catalog = try CurriculumService.loadDefaultCatalog()
        let defaults = try #require(UserDefaults(suiteName: "DemoProgressTests"))
        defaults.removePersistentDomain(forName: "DemoProgressTests")

        DemoProgress.seed(repository: repository, pack: pack, defaults: defaults)

        let profile = try #require(repository.loadActiveProfile())
        #expect(profile.displayName == DemoProgress.childName)
        #expect(repository.completedSessionCount(childID: profile.id) == 13)
        #expect(repository.streakDays(childID: profile.id) == 6)
        #expect(repository.fetchStickers(childID: profile.id).count == 9)
        #expect(defaults.data(forKey: AppState.PreferenceKey.diagnosticResult(for: profile.id)) != nil)

        let report = ProgressReportService(repository: repository, catalog: catalog)
            .buildReport(for: profile, dashboard: .empty, placedGrade: .grade2)
        #expect(report.domainReports.reduce(0) { $0 + $1.skillsCovered } == 9)
        #expect(report.domainReports.reduce(0) { $0 + $1.skillsTotal } == 10)
        #expect(report.weakSpots.map(\.domain) == [.geometry])
        #expect(report.recentActivity.count == 7)
    }
}
