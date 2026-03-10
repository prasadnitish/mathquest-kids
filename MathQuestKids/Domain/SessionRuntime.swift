import Foundation

struct SessionRuntime {
    let sessionID: UUID
    let focusUnit: UnitType
    let items: [PracticeItem]

    private(set) var index: Int
    private(set) var correctCount: Int
    private(set) var hintsUsedByItem: [String: Int]
    private(set) var incorrectByItem: [String: Int]
    private(set) var recentMisconceptions: [String]
    private(set) var completed: Bool

    init(blueprint: SessionBlueprint) {
        sessionID = blueprint.sessionID
        focusUnit = blueprint.focusUnit
        items = blueprint.items
        index = 0
        correctCount = 0
        hintsUsedByItem = [:]
        incorrectByItem = [:]
        recentMisconceptions = []
        completed = false
    }

    var currentItem: PracticeItem {
        items[index]
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
        if correct {
            correctCount += 1
            advanceOrComplete()
        } else {
            incorrectByItem[currentItem.id, default: 0] += 1
            if recentMisconceptions.count > 8 {
                recentMisconceptions.removeFirst()
            }
            recentMisconceptions.append("\(currentItem.skillID):\(currentItem.answer)")
            if incorrectByItem[currentItem.id, default: 0] >= 2 {
                advanceOrComplete()
            }
        }
    }

    private mutating func advanceOrComplete() {
        if index < items.count - 1 {
            index += 1
        } else {
            completed = true
        }
    }
}
