import Foundation

final class MasteryEngine {
    private let repository: ProgressRepository
    private let scheduler = ReviewScheduler()

    init(repository: ProgressRepository) {
        self.repository = repository
    }

    func recordAttempt(_ attempt: AttemptInput) throws -> MasteryStateRecord {
        try repository.saveAttempt(attempt)

        let recent = repository.fetchRecentAttempts(childID: attempt.childID, skillID: attempt.skillID, limit: 20)
        let accuracy = recent.isEmpty ? 0.0 : Double(recent.filter(\.correct).count) / Double(recent.count)
        let sessionCount = repository.sessionCountInRecentAttempts(childID: attempt.childID, skillID: attempt.skillID, limit: 20)
        let incorrectStreak = countConsecutiveIncorrect(attempts: recent)

        let existing = repository.fetchMasteryState(childID: attempt.childID, skillID: attempt.skillID)
        let previousStatus = MasteryStatus(rawValue: existing?.statusRaw ?? MasteryStatus.learning.rawValue) ?? .learning

        let status: MasteryStatus
        if recent.count >= 20 && accuracy >= 0.85 && sessionCount >= 2 {
            status = .mastered
        } else if previousStatus == .mastered && (accuracy < 0.70 || incorrectStreak >= 3) {
            status = .reviewDue
        } else if accuracy >= 0.60 {
            status = .practicing
        } else {
            status = .learning
        }

        let state = MasteryStateRecord(
            childID: attempt.childID,
            skillID: attempt.skillID,
            status: status,
            masteryScore: accuracy,
            lastAssessedAt: Date(),
            sessionCount: sessionCount,
            recentIncorrectStreak: incorrectStreak
        )
        try repository.saveMasteryState(state)

        try updateReviewSchedule(for: state, previousStatus: previousStatus)

        return state
    }

    func currentStatus(skillId: String, childID: UUID) -> MasteryStatus {
        guard let current = repository.fetchMasteryState(childID: childID, skillID: skillId) else {
            return .learning
        }
        return MasteryStatus(rawValue: current.statusRaw) ?? .learning
    }

    func nextReviewDate(skillId: String, childID: UUID) -> Date? {
        repository.fetchReviewSchedule(childID: childID, skillID: skillId)?.nextDueAt
    }

    func nextRecommendation(for skillId: String, childID: UUID) -> String {
        let status = currentStatus(skillId: skillId, childID: childID)
        switch status {
        case .mastered:
            return "Review in a day to keep this skill strong."
        case .reviewDue:
            return "This skill is due for review next session."
        case .practicing:
            return "Keep practicing this strategy tomorrow."
        case .learning:
            return "Stay in learning mode and use hints freely."
        }
    }

    private func updateReviewSchedule(for state: MasteryStateRecord, previousStatus: MasteryStatus) throws {
        switch state.status {
        case .mastered:
            if previousStatus != .mastered {
                let first = scheduler.scheduleAfterMastery(from: Date())
                let record = ReviewScheduleRecord(
                    childID: state.childID,
                    skillID: state.skillID,
                    nextDueAt: first.nextDueAt,
                    intervalIndex: first.intervalIndex,
                    lapseCount: first.lapseCount
                )
                try repository.saveReviewSchedule(record)
            } else if let existing = repository.fetchReviewSchedule(childID: state.childID, skillID: state.skillID),
                      existing.nextDueAt <= Date(),
                      state.masteryScore >= 0.85 {
                let advanced = scheduler.nextDate(currentIndex: Int(existing.intervalIndex), from: Date())
                let record = ReviewScheduleRecord(
                    childID: state.childID,
                    skillID: state.skillID,
                    nextDueAt: advanced.1,
                    intervalIndex: advanced.0,
                    lapseCount: Int(existing.lapseCount)
                )
                try repository.saveReviewSchedule(record)
            }
        case .reviewDue:
            let existing = repository.fetchReviewSchedule(childID: state.childID, skillID: state.skillID)
            let currentLapses = Int(existing?.lapseCount ?? 0)
            let reset = scheduler.resetAfterLapse(from: Date(), lapseCount: currentLapses)
            let record = ReviewScheduleRecord(
                childID: state.childID,
                skillID: state.skillID,
                nextDueAt: reset.2,
                intervalIndex: reset.0,
                lapseCount: reset.1
            )
            try repository.saveReviewSchedule(record)
        case .learning, .practicing:
            break
        }
    }

    private func countConsecutiveIncorrect(attempts: [CDAttempt]) -> Int {
        var streak = 0
        for attempt in attempts {
            if attempt.correct {
                break
            }
            streak += 1
        }
        return streak
    }
}
