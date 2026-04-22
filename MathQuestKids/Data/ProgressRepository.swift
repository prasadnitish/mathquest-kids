import CoreData
import Foundation

final class ProgressRepository {
    private let stack: CoreDataStack
    private var context: NSManagedObjectContext { stack.persistentContainer.viewContext }
    private var lastAttemptTimestamp: Date = .distantPast

    init(coreDataStack: CoreDataStack) {
        self.stack = coreDataStack
    }

    func loadActiveProfile() -> ChildProfileRecord? {
        withContextValue {
            let request = NSFetchRequest<CDChildProfile>(entityName: "CDChildProfile")
            request.fetchLimit = 1
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            let profile = try? context.fetch(request).first
            return profile.map { ChildProfileRecord(id: $0.id, displayName: $0.displayName, createdAt: $0.createdAt) }
        }
    }

    func createOrLoadProfile(name: String) throws -> ChildProfileRecord {
        if let existing = loadActiveProfile() {
            return existing
        }

        return try withContextResult {
            let profile = CDChildProfile(context: context)
            profile.id = UUID()
            profile.displayName = name
            profile.createdAt = Date()
            try saveContextIfNeeded()
            return ChildProfileRecord(id: profile.id, displayName: profile.displayName, createdAt: profile.createdAt)
        }
    }

    func startSession(sessionID: UUID, childID: UUID, unit: UnitType) throws {
        try withContextResult {
            let session = CDSessionLog(context: context)
            session.id = sessionID
            session.childID = childID
            session.unitRaw = unit.rawValue
            session.startedAt = Date()
            session.totalItems = 0
            session.correctItems = 0
            try saveContextIfNeeded()
        }
    }

    func finishSession(sessionID: UUID, childID: UUID, unit: UnitType, totalItems: Int16, correctItems: Int16, rewardTitle: String) throws {
        try withContextResult {
            let request = NSFetchRequest<CDSessionLog>(entityName: "CDSessionLog")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", sessionID as CVarArg)
            let session = try context.fetch(request).first ?? CDSessionLog(context: context)
            session.id = sessionID
            session.childID = childID
            session.unitRaw = unit.rawValue
            session.endedAt = Date()
            session.totalItems = totalItems
            session.correctItems = correctItems
            session.rewardTitle = rewardTitle
            try saveContextIfNeeded()
        }
    }

    func saveAttempt(_ attempt: AttemptInput) throws {
        try withContextResult {
            let now = Date()
            let timestamp = now > lastAttemptTimestamp
                ? now
                : lastAttemptTimestamp.addingTimeInterval(0.001)
            lastAttemptTimestamp = timestamp

            let entity = CDAttempt(context: context)
            entity.id = UUID()
            entity.childID = attempt.childID
            entity.timestamp = timestamp
            entity.skillID = attempt.skillID
            entity.unitRaw = attempt.unit.rawValue
            entity.itemID = attempt.itemID
            entity.sessionID = attempt.sessionID
            entity.response = attempt.response
            entity.correct = attempt.correct
            entity.latencyMs = attempt.latencyMs
            entity.hintsUsed = attempt.hintsUsed
            entity.inputModeRaw = attempt.inputMode.rawValue
            try saveContextIfNeeded()
        }
    }

    func fetchRecentAttempts(childID: UUID, skillID: String, limit: Int = 20) -> [CDAttempt] {
        withContextValue {
            let request = NSFetchRequest<CDAttempt>(entityName: "CDAttempt")
            request.fetchLimit = limit
            request.predicate = NSPredicate(format: "childID == %@ AND skillID == %@", childID as CVarArg, skillID)
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            return (try? context.fetch(request)) ?? []
        }
    }

    func fetchMasteryState(childID: UUID, skillID: String) -> CDMasteryState? {
        withContextValue {
            let request = NSFetchRequest<CDMasteryState>(entityName: "CDMasteryState")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "childID == %@ AND skillID == %@", childID as CVarArg, skillID)
            return try? context.fetch(request).first
        }
    }

    func saveMasteryState(_ state: MasteryStateRecord) throws {
        try withContextResult {
            let request = NSFetchRequest<CDMasteryState>(entityName: "CDMasteryState")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "childID == %@ AND skillID == %@", state.childID as CVarArg, state.skillID)
            let entity = try context.fetch(request).first ?? CDMasteryState(context: context)
            entity.childID = state.childID
            entity.skillID = state.skillID
            entity.statusRaw = state.status.rawValue
            entity.masteryScore = state.masteryScore
            entity.lastAssessedAt = state.lastAssessedAt
            entity.sessionCount = Int32(state.sessionCount)
            entity.recentIncorrectStreak = Int16(state.recentIncorrectStreak)
            try saveContextIfNeeded()
        }
    }

    func fetchReviewSchedule(childID: UUID, skillID: String) -> CDReviewSchedule? {
        withContextValue {
            let request = NSFetchRequest<CDReviewSchedule>(entityName: "CDReviewSchedule")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "childID == %@ AND skillID == %@", childID as CVarArg, skillID)
            return try? context.fetch(request).first
        }
    }

    func saveReviewSchedule(_ record: ReviewScheduleRecord) throws {
        try withContextResult {
            let request = NSFetchRequest<CDReviewSchedule>(entityName: "CDReviewSchedule")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "childID == %@ AND skillID == %@", record.childID as CVarArg, record.skillID)
            let entity = try context.fetch(request).first ?? CDReviewSchedule(context: context)
            entity.childID = record.childID
            entity.skillID = record.skillID
            entity.nextDueAt = record.nextDueAt
            entity.intervalIndex = Int16(record.intervalIndex)
            entity.lapseCount = Int16(record.lapseCount)
            try saveContextIfNeeded()
        }
    }

    func dueReviewSkillIDs(childID: UUID, asOf date: Date = .now) -> Set<String> {
        withContextValue {
            let request = NSFetchRequest<CDReviewSchedule>(entityName: "CDReviewSchedule")
            request.predicate = NSPredicate(format: "childID == %@ AND nextDueAt <= %@", childID as CVarArg, date as NSDate)
            let schedules = (try? context.fetch(request)) ?? []
            return Set(schedules.map(\.skillID))
        }
    }

    func sessionCountInRecentAttempts(childID: UUID, skillID: String, limit: Int = 20) -> Int {
        let attempts = fetchRecentAttempts(childID: childID, skillID: skillID, limit: limit)
        return Set(attempts.map(\.sessionID)).count
    }

    func recentAttemptsForSession(sessionID: UUID) -> [CDAttempt] {
        withContextValue {
            let request = NSFetchRequest<CDAttempt>(entityName: "CDAttempt")
            request.predicate = NSPredicate(format: "sessionID == %@", sessionID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            return (try? context.fetch(request)) ?? []
        }
    }

    func fetchSessionLog(sessionID: UUID) -> CDSessionLog? {
        withContextValue {
            let request = NSFetchRequest<CDSessionLog>(entityName: "CDSessionLog")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", sessionID as CVarArg)
            return try? context.fetch(request).first
        }
    }

    func recentCompletedSessions(childID: UUID, limit: Int = 50) -> [CDSessionLog] {
        withContextValue {
            let request = NSFetchRequest<CDSessionLog>(entityName: "CDSessionLog")
            request.fetchLimit = limit
            request.predicate = NSPredicate(format: "childID == %@ AND endedAt != nil", childID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "endedAt", ascending: false)]
            return (try? context.fetch(request)) ?? []
        }
    }

    func completedSessionCount(childID: UUID, unit: UnitType? = nil) -> Int {
        withContextValue {
            let request = NSFetchRequest<CDSessionLog>(entityName: "CDSessionLog")
            if let unit {
                request.predicate = NSPredicate(
                    format: "childID == %@ AND endedAt != nil AND unitRaw == %@",
                    childID as CVarArg,
                    unit.rawValue
                )
            } else {
                request.predicate = NSPredicate(format: "childID == %@ AND endedAt != nil", childID as CVarArg)
            }
            return (try? context.count(for: request)) ?? 0
        }
    }

    func averageAccuracy(childID: UUID) -> Double {
        let sessions = recentCompletedSessions(childID: childID, limit: 200)
        let totals = sessions.reduce(into: (correct: 0, total: 0)) { partial, log in
            partial.correct += Int(log.correctItems)
            partial.total += Int(log.totalItems)
        }
        guard totals.total > 0 else { return 0.0 }
        return Double(totals.correct) / Double(totals.total)
    }

    func streakDays(childID: UUID, now: Date = .now) -> Int {
        let sessions = recentCompletedSessions(childID: childID, limit: 365)
        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        let activeDays = Set(sessions.compactMap { session -> Date? in
            guard let endedAt = session.endedAt else { return nil }
            return calendar.startOfDay(for: endedAt)
        })

        var streak = 0
        var cursor = calendar.startOfDay(for: now)
        while activeDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    func unitSessionCounts(childID: UUID) -> [UnitType: Int] {
        let sessions = recentCompletedSessions(childID: childID, limit: 500)
        var counts: [UnitType: Int] = [:]
        for session in sessions {
            guard let unit = UnitType(rawValue: session.unitRaw) else { continue }
            counts[unit, default: 0] += 1
        }
        return counts
    }

    func recentTemplateIDs(childID: UUID, unit: UnitType, limit: Int = 120) -> Set<String> {
        withContextValue {
            let request = NSFetchRequest<CDAttempt>(entityName: "CDAttempt")
            request.fetchLimit = limit
            request.predicate = NSPredicate(
                format: "childID == %@ AND unitRaw == %@",
                childID as CVarArg,
                unit.rawValue
            )
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

            let attempts = (try? context.fetch(request)) ?? []
            let regex = try? NSRegularExpression(pattern: "-\\d+$")

            return Set(attempts.map { attempt in
                guard let regex else { return attempt.itemID }
                let nsRange = NSRange(attempt.itemID.startIndex..<attempt.itemID.endIndex, in: attempt.itemID)
                return regex.stringByReplacingMatches(in: attempt.itemID, options: [], range: nsRange, withTemplate: "")
            })
        }
    }

    func saveStickerEarned(childID: UUID, unitRaw: String, dateEarned: Date) throws {
        try withContextResult {
            let fetchRequest = NSFetchRequest<CDStickerRecord>(entityName: "CDStickerRecord")
            fetchRequest.predicate = NSPredicate(
                format: "childID == %@ AND unitRaw == %@",
                childID as CVarArg, unitRaw
            )
            let existing = try context.fetch(fetchRequest)
            guard existing.isEmpty else { return }

            let record = CDStickerRecord(context: context)
            record.childID = childID
            record.unitRaw = unitRaw
            record.dateEarned = dateEarned
            try saveContextIfNeeded()
        }
    }

    func fetchStickers(childID: UUID) -> [CDStickerRecord] {
        withContextValue {
            let request = NSFetchRequest<CDStickerRecord>(entityName: "CDStickerRecord")
            request.predicate = NSPredicate(format: "childID == %@", childID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "dateEarned", ascending: true)]
            return (try? context.fetch(request)) ?? []
        }
    }

    func fetchRecentSessionLogs(childID: UUID, limit: Int) -> [CDSessionLog] {
        withContextValue {
            let request = NSFetchRequest<CDSessionLog>(entityName: "CDSessionLog")
            request.predicate = NSPredicate(format: "childID == %@", childID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
            request.fetchLimit = limit
            return (try? context.fetch(request)) ?? []
        }
    }

    func recentAttemptsForUnit(childID: UUID, unitRaw: String, limit: Int) -> [CDAttempt] {
        withContextValue {
            let request = NSFetchRequest<CDAttempt>(entityName: "CDAttempt")
            request.predicate = NSPredicate(
                format: "childID == %@ AND unitRaw == %@",
                childID as CVarArg, unitRaw
            )
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            request.fetchLimit = limit
            return (try? context.fetch(request)) ?? []
        }
    }

    func deleteLearningData(childID: UUID, deleteProfile: Bool) throws {
        try withContextResult {
            try deleteRecords(entityName: "CDAttempt", predicate: NSPredicate(format: "childID == %@", childID as CVarArg))
            try deleteRecords(entityName: "CDMasteryState", predicate: NSPredicate(format: "childID == %@", childID as CVarArg))
            try deleteRecords(entityName: "CDReviewSchedule", predicate: NSPredicate(format: "childID == %@", childID as CVarArg))
            try deleteRecords(entityName: "CDSessionLog", predicate: NSPredicate(format: "childID == %@", childID as CVarArg))
            try deleteRecords(entityName: "CDStickerRecord", predicate: NSPredicate(format: "childID == %@", childID as CVarArg))

            if deleteProfile {
                try deleteRecords(entityName: "CDChildProfile", predicate: NSPredicate(format: "id == %@", childID as CVarArg))
            }

            try saveContextIfNeeded()
        }
    }

    private func deleteRecords(entityName: String, predicate: NSPredicate) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = predicate
        let records = try context.fetch(request)
        for record in records {
            context.delete(record)
        }
    }

    private func saveContextIfNeeded() throws {
        guard context.hasChanges else { return }
        try context.save()
    }

    private func withContextValue<T>(_ work: () -> T) -> T {
        var value: T!
        context.performAndWait {
            value = work()
        }
        return value
    }

    private func withContextResult<T>(_ work: () throws -> T) throws -> T {
        var result: Result<T, Error>!
        context.performAndWait {
            result = Result(catching: work)
        }
        return try result.get()
    }
}
