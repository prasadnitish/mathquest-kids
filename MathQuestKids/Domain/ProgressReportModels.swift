import Foundation

struct DomainReport: Identifiable, Equatable {
    let domain: LessonDomain
    let skillsCovered: Int
    let skillsTotal: Int
    let averageAccuracy: Double
    let perSkillStatus: [SkillStatus]

    var id: String { domain.rawValue }
    var coverageFraction: Double {
        skillsTotal > 0 ? Double(skillsCovered) / Double(skillsTotal) : 0
    }
    var isWeakSpot: Bool { averageAccuracy < 0.40 && skillsCovered > 0 }
}

struct SkillStatus: Identifiable, Equatable {
    let skillID: String
    let title: String
    let masteryStatus: MasteryStatus
    var id: String { skillID }
}

struct WeeklyActivity: Identifiable, Equatable {
    let date: Date
    let unitTitle: String
    let correctItems: Int
    let totalItems: Int
    var id: String { date.ISO8601Format() + unitTitle }
}

struct ProgressReport: Equatable {
    let childName: String
    let gradePlacement: String
    let streakDays: Int
    let lastActiveDate: Date?
    let domainReports: [DomainReport]
    let recentActivity: [WeeklyActivity]
    let weakSpots: [DomainReport]

    static let empty = ProgressReport(
        childName: "—", gradePlacement: "—", streakDays: 0,
        lastActiveDate: nil, domainReports: [], recentActivity: [], weakSpots: []
    )
}
