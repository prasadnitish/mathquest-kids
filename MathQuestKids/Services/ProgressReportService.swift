import Foundation

final class ProgressReportService {
    private let repository: ProgressRepository
    private let catalog: CurriculumCatalog

    init(repository: ProgressRepository, catalog: CurriculumCatalog) {
        self.repository = repository
        self.catalog = catalog
    }

    func buildReport(for profile: ChildProfileRecord, dashboard: DashboardSnapshot, placedGrade: GradeBand) -> ProgressReport {
        let gradeLessons = catalog.lessons(for: placedGrade)
        let domainReports = buildDomainReports(childID: profile.id, lessons: gradeLessons)
        let recentActivity = buildRecentActivity(childID: profile.id)

        return ProgressReport(
            childName: profile.displayName,
            gradePlacement: placedGrade.title,
            streakDays: dashboard.streakDays,
            lastActiveDate: recentActivity.first?.date,
            domainReports: domainReports,
            recentActivity: recentActivity,
            weakSpots: domainReports.filter(\.isWeakSpot)
        )
    }

    private func buildDomainReports(childID: UUID, lessons: [LessonPlanItem]) -> [DomainReport] {
        let grouped = Dictionary(grouping: lessons, by: \.domain)
        return grouped.map { domain, domainLessons -> DomainReport in
            let playable = domainLessons.filter(\.isPlayableInApp)
            var coveredCount = 0
            var totalAccuracy = 0.0
            var perSkillStatus: [SkillStatus] = []

            for lesson in playable {
                guard let linkedUnit = lesson.linkedUnit else { continue }
                let attempts = repository.recentAttemptsForUnit(childID: childID, unitRaw: linkedUnit.rawValue, limit: 20)
                let correct = attempts.filter(\.correct).count
                let accuracy = attempts.isEmpty ? 0.0 : Double(correct) / Double(attempts.count)

                if !attempts.isEmpty { coveredCount += 1 }
                totalAccuracy += accuracy

                let masteryRecord = repository.fetchMasteryState(childID: childID, skillID: lesson.id)
                let status = masteryRecord.map { MasteryStatus(rawValue: $0.statusRaw) ?? .learning } ?? .learning

                perSkillStatus.append(SkillStatus(skillID: lesson.id, title: lesson.title, masteryStatus: status))
            }

            let avgAccuracy = playable.isEmpty ? 0.0 : totalAccuracy / Double(playable.count)
            return DomainReport(
                domain: domain,
                skillsCovered: coveredCount,
                skillsTotal: playable.count,
                averageAccuracy: avgAccuracy,
                perSkillStatus: perSkillStatus
            )
        }
        .sorted(by: { $0.domain.rawValue < $1.domain.rawValue })
    }

    private func buildRecentActivity(childID: UUID) -> [WeeklyActivity] {
        let logs = repository.fetchRecentSessionLogs(childID: childID, limit: 7)
        return logs.map { log in
            WeeklyActivity(
                date: log.startedAt,
                unitTitle: UnitType(rawValue: log.unitRaw)?.title ?? log.unitRaw,
                correctItems: Int(log.correctItems),
                totalItems: Int(log.totalItems)
            )
        }
    }
}
