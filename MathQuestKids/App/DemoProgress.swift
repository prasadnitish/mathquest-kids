import Foundation

/// Sample progress for filming the app (promo videos, App Store screenshots): a second
/// grader with about ten days of quests behind her, so Home, the sticker book and the parent
/// dashboard look the way they do in use. Only with -ui-test (an in-memory store that's
/// thrown away) plus -promo-demo, so it never touches a real child's progress.
enum DemoProgress {
    static let launchArgument = "-promo-demo"
    static let childName = "Maya"

    private struct Session {
        let daysAgo: Int
        let hour: Int
        let minute: Int
        let unit: UnitType
        /// Right answers out of eight.
        let correct: Int
    }

    /// Most recent first: a six-day streak, a day off, then three more days. Grid paths is
    /// still new to her, so the dashboard has one area that needs attention.
    private static let sessions: [Session] = [
        Session(daysAgo: 0, hour: 0, minute: 0, unit: .g2AddWithin100, correct: 8),
        Session(daysAgo: 0, hour: 0, minute: 0, unit: .g2SpatialGridPaths, correct: 5),
        Session(daysAgo: 1, hour: 17, minute: 5, unit: .g2SubWithin100, correct: 7),
        Session(daysAgo: 2, hour: 16, minute: 30, unit: .g2AddSubRegroup, correct: 6),
        Session(daysAgo: 3, hour: 18, minute: 0, unit: .g2TimeMoney, correct: 7),
        Session(daysAgo: 3, hour: 17, minute: 20, unit: .g2AddWithin100, correct: 7),
        Session(daysAgo: 4, hour: 16, minute: 45, unit: .g2PlaceValue1000, correct: 7),
        Session(daysAgo: 5, hour: 17, minute: 15, unit: .g2EqualGroups, correct: 7),
        Session(daysAgo: 5, hour: 16, minute: 35, unit: .g2SubWithin100, correct: 7),
        Session(daysAgo: 7, hour: 16, minute: 0, unit: .g2DataIntro, correct: 7),
        Session(daysAgo: 8, hour: 17, minute: 30, unit: .threeDigitComparison, correct: 7),
        Session(daysAgo: 8, hour: 16, minute: 50, unit: .g2PlaceValue1000, correct: 6),
        Session(daysAgo: 9, hour: 16, minute: 20, unit: .g2AddWithin100, correct: 7),
    ]

    /// Lesson (skill) standings shown on the dashboard's domain cards.
    private static let mastery: [(lessonID: String, status: MasteryStatus, score: Double)] = [
        ("g2-add-within-100", .mastered, 0.92),
        ("g2-sub-within-100", .mastered, 0.88),
        ("g2-place-value-1000", .practicing, 0.8),
        ("g2-add-sub-regroup", .practicing, 0.72),
        ("g2-compare-3digit", .practicing, 0.84),
        ("g2-equal-groups", .practicing, 0.86),
        ("g2-time-money", .practicing, 0.82),
        ("g2-data-lineplot-intro", .practicing, 0.85),
        ("g2-spatial-grid-paths", .learning, 0.55),
    ]

    static func seed(repository: ProgressRepository, pack: ContentPack, defaults: UserDefaults, now: Date = .now) {
        guard let profile = try? repository.createOrLoadProfile(name: childName) else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        var firstSessionByUnit: [UnitType: Date] = [:]
        for (index, session) in sessions.enumerated() {
            let startedAt: Date
            if session.daysAgo == 0 {
                // Earlier today, whatever time it is now, so the streak includes today.
                let fraction = 0.9 - 0.1 * Double(index)
                startedAt = today.addingTimeInterval(now.timeIntervalSince(today) * fraction)
            } else {
                let day = calendar.date(byAdding: .day, value: -session.daysAgo, to: today) ?? today
                startedAt = calendar.date(bySettingHour: session.hour, minute: session.minute, second: 0, of: day) ?? day
            }

            let templates = pack.itemTemplates.filter { $0.unit == session.unit }
            guard !templates.isEmpty else { continue }
            // Misses land mid-quest rather than all at the end.
            let missed = Set([2, 5, 3, 6].prefix(max(0, 8 - session.correct)))
            // History comes from the back half of each unit, so the questions filmed in a
            // fresh quest (the first ones in the pack) haven't been "seen" recently.
            let backHalf = Array(templates.suffix(max(1, templates.count / 2)))
            let attempts = (0..<8).map { item in
                (template: backHalf[(item + index * 8) % backHalf.count], correct: !missed.contains(item))
            }
            try? repository.seedDemoSession(
                childID: profile.id,
                unit: session.unit,
                startedAt: startedAt,
                attempts: attempts
            )
            firstSessionByUnit[session.unit] = startedAt
        }

        for (unit, earned) in firstSessionByUnit {
            try? repository.saveStickerEarned(childID: profile.id, unitRaw: unit.rawValue, dateEarned: earned)
        }

        for entry in mastery {
            try? repository.saveMasteryState(MasteryStateRecord(
                childID: profile.id,
                skillID: entry.lessonID,
                status: entry.status,
                masteryScore: entry.score,
                lastAssessedAt: now,
                sessionCount: 2,
                recentIncorrectStreak: 0
            ))
        }

        let placement = DiagnosticResult(
            childID: profile.id,
            completedAt: calendar.date(byAdding: .day, value: -10, to: today) ?? today,
            placedGrade: .grade2,
            confidence: 0.82,
            overallScore: 0.76,
            domainScores: [:],
            recommendedLessonIDs: mastery.map(\.lessonID),
            missedDomains: []
        )
        if let encoded = try? JSONEncoder().encode(placement) {
            defaults.set(encoded, forKey: AppState.PreferenceKey.diagnosticResult(for: profile.id))
        }
    }
}
