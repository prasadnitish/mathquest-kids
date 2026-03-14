import Foundation

struct SessionRuntime {
    let sessionID: UUID
    let focusUnit: UnitType
    let items: [PracticeItem]

    private(set) var index: Int
    private(set) var correctCount: Int
    private(set) var answeredCount: Int
    private(set) var hintsUsedByItem: [String: Int]
    private(set) var incorrectByItem: [String: Int]
    private(set) var recentMisconceptions: [String]
    private(set) var completed: Bool
    private(set) var pendingAdvance: Bool

    init(blueprint: SessionBlueprint) {
        sessionID = blueprint.sessionID
        focusUnit = blueprint.focusUnit
        items = blueprint.items
        index = 0
        correctCount = 0
        answeredCount = 0
        hintsUsedByItem = [:]
        incorrectByItem = [:]
        recentMisconceptions = []
        completed = false
        pendingAdvance = false
    }

    var currentItem: PracticeItem {
        guard !items.isEmpty, index < items.count else {
            preconditionFailure("SessionRuntime.currentItem accessed at index \(index) but items has \(items.count) elements")
        }
        return items[index]
    }

    var isComplete: Bool {
        completed
    }

    var hintsUsedForCurrentItem: Int {
        hintsUsedByItem[currentItem.id, default: 0]
    }

    var incorrectAttemptsForCurrentItem: Int {
        incorrectByItem[currentItem.id, default: 0]
    }

    func evaluate(answer: String) -> Bool {
        answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == currentItem.answer.lowercased()
    }

    mutating func registerHintUse() {
        hintsUsedByItem[currentItem.id, default: 0] += 1
    }

    mutating func recordSubmission(correct: Bool) {
        // If this item already triggered pendingAdvance (e.g. 2 incorrect),
        // don't double-count answeredCount on a subsequent correct answer.
        let alreadyCounted = pendingAdvance

        if correct {
            correctCount += 1
            if !alreadyCounted {
                answeredCount += 1
            }
            pendingAdvance = true
        } else {
            incorrectByItem[currentItem.id, default: 0] += 1
            if recentMisconceptions.count > 8 {
                recentMisconceptions.removeFirst()
            }
            recentMisconceptions.append("\(currentItem.skillID):\(currentItem.answer)")
            if !alreadyCounted && incorrectByItem[currentItem.id, default: 0] >= 2 {
                answeredCount += 1
                pendingAdvance = true
            }
        }
    }

    /// Call after showing feedback to actually move to the next item.
    mutating func advanceIfPending() {
        guard pendingAdvance else { return }
        pendingAdvance = false
        advanceOrComplete()
    }

    private mutating func advanceOrComplete() {
        if index < items.count - 1 {
            index += 1
        } else {
            completed = true
        }
    }
}
