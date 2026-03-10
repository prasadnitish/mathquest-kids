import CoreData
import Foundation

@objc(CDChildProfile)
final class CDChildProfile: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var displayName: String
    @NSManaged var createdAt: Date
}

@objc(CDAttempt)
final class CDAttempt: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var childID: UUID
    @NSManaged var timestamp: Date
    @NSManaged var skillID: String
    @NSManaged var unitRaw: String
    @NSManaged var itemID: String
    @NSManaged var sessionID: UUID
    @NSManaged var response: String
    @NSManaged var correct: Bool
    @NSManaged var latencyMs: Double
    @NSManaged var hintsUsed: Int16
    @NSManaged var inputModeRaw: String
}

@objc(CDMasteryState)
final class CDMasteryState: NSManagedObject {
    @NSManaged var childID: UUID
    @NSManaged var skillID: String
    @NSManaged var statusRaw: String
    @NSManaged var masteryScore: Double
    @NSManaged var lastAssessedAt: Date
    @NSManaged var sessionCount: Int32
    @NSManaged var recentIncorrectStreak: Int16
}

@objc(CDReviewSchedule)
final class CDReviewSchedule: NSManagedObject {
    @NSManaged var childID: UUID
    @NSManaged var skillID: String
    @NSManaged var nextDueAt: Date
    @NSManaged var intervalIndex: Int16
    @NSManaged var lapseCount: Int16
}

@objc(CDSessionLog)
final class CDSessionLog: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var childID: UUID
    @NSManaged var unitRaw: String
    @NSManaged var startedAt: Date
    @NSManaged var endedAt: Date?
    @NSManaged var totalItems: Int16
    @NSManaged var correctItems: Int16
    @NSManaged var rewardTitle: String?
}

@objc(CDStickerRecord)
final class CDStickerRecord: NSManagedObject {
    @NSManaged var childID: UUID
    @NSManaged var unitRaw: String
    @NSManaged var dateEarned: Date
}
