import CoreData
import Foundation

final class ProgressRepository {
    private let stack: CoreDataStack
    private var context: NSManagedObjectContext { stack.persistentContainer.viewContext }

    init(coreDataStack: CoreDataStack) {
        self.stack = coreDataStack
    }

    func loadActiveProfile() -> ChildProfileRecord? {
        let request = NSFetchRequest<CDChildProfile>(entityName: "CDChildProfile")
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        let profile = try? context.fetch(request).first
        return profile.map { ChildProfileRecord(id: $0.id, displayName: $0.displayName, createdAt: $0.createdAt) }
    }

    func createOrLoadProfile(name: String) throws -> ChildProfileRecord {
        if let existing = loadActiveProfile() {
            return existing
        }

        let profile = CDChildProfile(context: context)
        profile.id = UUID()
        profile.displayName = name
        profile.createdAt = Date()
        try stack.saveContext()
        return ChildProfileRecord(id: profile.id, displayName: profile.displayName, createdAt: profile.createdAt)
    }

    func startSession(sessionID: UUID, childID: UUID, unit: UnitType) throws {
        let session = CDSessionLog(context: context)
        session.id = sessionID
        session.childID = childID
        session.unitRaw = unit.rawValue
        session.startedAt = Date()
        session.totalItems = 0
        session.correctItems = 0
        try stack.saveContext()
    }

    func finishSession(sessionID: UUID, childID: UUID, unit: UnitType, totalItems: Int16, correctItems: Int16, rewardTitle: String) throws {
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
        try stack.saveContext()
    }

    func saveAttempt(_ attempt: AttemptInput) throws {
        let entity = CDAttempt(context: context)
        entity.id = UUID()
        entity.childID = attempt.childID
        entity.timestamp = Date()
        entity.skillID = attempt.skillID
        entity.unitRaw = attempt.unit.rawValue
        entity.itemID = attempt.itemID
        entity.sessionID = attempt.sessionID
        entity.response = attempt.response
        entity.correct = attempt.correct
        entity.latencyMs = attempt.latencyMs
        entity.hintsUsed = attempt.hintsUsed
        entity.inputModeRaw = attempt.inputMode.rawValue
        try stack.saveContext()
    }

    func fetchRecentAttempts(childID: UUID, skillID: String, limit: Int = 20) -> [CDAttempt] {
        let request = NSFetchRequest<CDAttempt>(entityName: "CDAttempt")
        request.fetchLimit = limit
        request.predicate = NSPredicate(format: "childID == %@ AND skillID == %@", childID as CVarArg, skillID)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    func fetchMasteryState(childID: UUID, skillID: String) -> CDMasteryState? {
        let request = NSFetchRequest<CDMasteryState>(entityName: "CDMasteryState")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "childID == %@ AND skillID == %@", childID as CVarArg, skillID)
        return try? context.fetch(request).first
    }

    func saveMasteryState(_ state: MasteryStateRecord) throws {
        let entity = fetchMasteryState(childID: state.childID, skillID: state.skillID) ?? CDMasteryState(context: context)
        entity.childID = state.childID
        entity.skillID = state.skillID
        entity.statusRaw = state.status.rawValue
        entity.masteryScore = state.masteryScore
        entity.lastAssessedAt = state.lastAssessedAt
        entity.sessionCount = Int32(state.sessionCount)
        entity.recentIncorrectStreak = Int16(state.recentIncorrectStreak)
        try stack.saveContext()
    }

    func fetchReviewSchedule(childID: UUID, skillID: String) -> CDReviewSchedule? {
        let request = NSFetchRequest<CDReviewSchedule>(entityName: "CDReviewSchedule")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "childID == %@ AND skillID == %@", childID as CVarArg, skillID)
        return try? context.fetch(request).first
    }

    func saveReviewSchedule(_ record: ReviewScheduleRecord) throws {
        let entity = fetchReviewSchedule(childID: record.childID, skillID: record.skillID) ?? CDReviewSchedule(context: context)
        entity.childID = record.childID
        entity.skillID = record.skillID
        entity.nextDueAt = record.nextDueAt
        entity.intervalIndex = Int16(record.intervalIndex)
        entity.lapseCount = Int16(record.lapseCount)
        try stack.saveContext()
    }

    func dueReviewSkillIDs(childID: UUID, asOf date: Date = .now) -> Set<String> {
        let request = NSFetchRequest<CDReviewSchedule>(entityName: "CDReviewSchedule")
        request.predicate = NSPredicate(format: "childID == %@ AND nextDueAt <= %@", childID as CVarArg, date as NSDate)
        let schedules = (try? context.fetch(request)) ?? []
        return Set(schedules.map(\.skillID))
    }

    func sessionCountInRecentAttempts(childID: UUID, skillID: String, limit: Int = 20) -> Int {
        let attempts = fetchRecentAttempts(childID: childID, skillID: skillID, limit: limit)
        return Set(attempts.map(\.sessionID)).count
    }

    func recentAttemptsForSession(sessionID: UUID) -> [CDAttempt] {
        let request = NSFetchRequest<CDAttempt>(entityName: "CDAttempt")
        request.predicate = NSPredicate(format: "sessionID == %@", sessionID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    func fetchSessionLog(sessionID: UUID) -> CDSessionLog? {
        let request = NSFetchRequest<CDSessionLog>(entityName: "CDSessionLog")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", sessionID as CVarArg)
        return try? context.fetch(request).first
    }

    func recentCompletedSessions(childID: UUID, limit: Int = 50) -> [CDSessionLog] {
        let request = NSFetchRequest<CDSessionLog>(entityName: "CDSessionLog")
        request.fetchLimit = limit
        request.predicate = NSPredicate(format: "childID == %@ AND endedAt != nil", childID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "endedAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    func completedSessionCount(childID: UUID, unit: UnitType? = nil) -> Int {
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

    // MARK: - Stickers

    func saveStickerEarned(childID: UUID, unitRaw: String, dateEarned: Date) throws {
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
        try context.save()
    }

    func fetchStickers(childID: UUID) -> [CDStickerRecord] {
        let request = NSFetchRequest<CDStickerRecord>(entityName: "CDStickerRecord")
        request.predicate = NSPredicate(format: "childID == %@", childID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "dateEarned", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    // MARK: - Recent Session Logs

    func fetchRecentSessionLogs(childID: UUID, limit: Int) -> [CDSessionLog] {
        let request = NSFetchRequest<CDSessionLog>(entityName: "CDSessionLog")
        request.predicate = NSPredicate(format: "childID == %@", childID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        request.fetchLimit = limit
        return (try? context.fetch(request)) ?? []
    }

    func recentAttemptsForUnit(childID: UUID, unitRaw: String, limit: Int) -> [CDAttempt] {
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
