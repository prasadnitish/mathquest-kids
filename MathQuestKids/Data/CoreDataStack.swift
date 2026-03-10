import CoreData
import Foundation

final class CoreDataStack {
    static let shared = CoreDataStack()

    let persistentContainer: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.makeModel()
        persistentContainer = NSPersistentContainer(name: "MathQuestKidsModel", managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            persistentContainer.persistentStoreDescriptions = [description]
        }

        persistentContainer.loadPersistentStores { _, error in
            if let error {
                DiagnosticsLogger.shared.error("Core Data persistent store failed", metadata: ["error": error.localizedDescription])
                fatalError("Core Data failed: \(error)")
            }
        }

        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    func saveContext() throws {
        let context = persistentContainer.viewContext
        guard context.hasChanges else { return }
        try context.save()
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let profile = NSEntityDescription()
        profile.name = "CDChildProfile"
        profile.managedObjectClassName = NSStringFromClass(CDChildProfile.self)
        profile.properties = [
            makeAttribute(name: "id", type: .UUIDAttributeType),
            makeAttribute(name: "displayName", type: .stringAttributeType),
            makeAttribute(name: "createdAt", type: .dateAttributeType)
        ]

        let attempt = NSEntityDescription()
        attempt.name = "CDAttempt"
        attempt.managedObjectClassName = NSStringFromClass(CDAttempt.self)
        attempt.properties = [
            makeAttribute(name: "id", type: .UUIDAttributeType),
            makeAttribute(name: "childID", type: .UUIDAttributeType),
            makeAttribute(name: "timestamp", type: .dateAttributeType),
            makeAttribute(name: "skillID", type: .stringAttributeType),
            makeAttribute(name: "unitRaw", type: .stringAttributeType),
            makeAttribute(name: "itemID", type: .stringAttributeType),
            makeAttribute(name: "sessionID", type: .UUIDAttributeType),
            makeAttribute(name: "response", type: .stringAttributeType),
            makeAttribute(name: "correct", type: .booleanAttributeType),
            makeAttribute(name: "latencyMs", type: .doubleAttributeType),
            makeAttribute(name: "hintsUsed", type: .integer16AttributeType),
            makeAttribute(name: "inputModeRaw", type: .stringAttributeType)
        ]

        let mastery = NSEntityDescription()
        mastery.name = "CDMasteryState"
        mastery.managedObjectClassName = NSStringFromClass(CDMasteryState.self)
        mastery.properties = [
            makeAttribute(name: "childID", type: .UUIDAttributeType),
            makeAttribute(name: "skillID", type: .stringAttributeType),
            makeAttribute(name: "statusRaw", type: .stringAttributeType),
            makeAttribute(name: "masteryScore", type: .doubleAttributeType),
            makeAttribute(name: "lastAssessedAt", type: .dateAttributeType),
            makeAttribute(name: "sessionCount", type: .integer32AttributeType),
            makeAttribute(name: "recentIncorrectStreak", type: .integer16AttributeType)
        ]

        let review = NSEntityDescription()
        review.name = "CDReviewSchedule"
        review.managedObjectClassName = NSStringFromClass(CDReviewSchedule.self)
        review.properties = [
            makeAttribute(name: "childID", type: .UUIDAttributeType),
            makeAttribute(name: "skillID", type: .stringAttributeType),
            makeAttribute(name: "nextDueAt", type: .dateAttributeType),
            makeAttribute(name: "intervalIndex", type: .integer16AttributeType),
            makeAttribute(name: "lapseCount", type: .integer16AttributeType)
        ]

        let session = NSEntityDescription()
        session.name = "CDSessionLog"
        session.managedObjectClassName = NSStringFromClass(CDSessionLog.self)
        session.properties = [
            makeAttribute(name: "id", type: .UUIDAttributeType),
            makeAttribute(name: "childID", type: .UUIDAttributeType),
            makeAttribute(name: "unitRaw", type: .stringAttributeType),
            makeAttribute(name: "startedAt", type: .dateAttributeType),
            makeAttribute(name: "endedAt", type: .dateAttributeType, isOptional: true),
            makeAttribute(name: "totalItems", type: .integer16AttributeType),
            makeAttribute(name: "correctItems", type: .integer16AttributeType),
            makeAttribute(name: "rewardTitle", type: .stringAttributeType, isOptional: true)
        ]

        let sticker = NSEntityDescription()
        sticker.name = "CDStickerRecord"
        sticker.managedObjectClassName = NSStringFromClass(CDStickerRecord.self)
        sticker.properties = [
            makeAttribute(name: "childID", type: .UUIDAttributeType),
            makeAttribute(name: "unitRaw", type: .stringAttributeType),
            makeAttribute(name: "dateEarned", type: .dateAttributeType)
        ]

        model.entities = [profile, attempt, mastery, review, session, sticker]
        return model
    }

    private static func makeAttribute(name: String, type: NSAttributeType, isOptional: Bool = false) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = isOptional
        return attribute
    }
}
