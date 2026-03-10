import Foundation

enum NodeState: Equatable {
    case locked
    case available
    case inProgress(masteryPercent: Double)
    case completed
    case mastered
}

struct TrailNode: Identifiable, Equatable {
    let unit: UnitType
    let nodeState: NodeState
    let isRecommended: Bool
    let stickerEarned: Bool

    var id: String { unit.rawValue }
}

struct SkillTrail: Equatable {
    let nodes: [TrailNode]

    static func build(
        dashboard: DashboardSnapshot,
        stickerCollection: StickerCollection
    ) -> SkillTrail {
        var previousUnlocked = true
        let nodes: [TrailNode] = UnitType.learningPath.map { unit in
            let progress = dashboard.unitProgress.first(where: { $0.unit == unit })
            let sessions = progress?.completedSessions ?? 0
            let unlocked = progress?.unlocked ?? false
            let stickerEarned = stickerCollection.stickers.first(where: { $0.unitType == unit })?.isUnlocked ?? false

            let state: NodeState
            if !unlocked && !previousUnlocked {
                state = .locked
            } else if sessions == 0 && unlocked {
                state = .available
            } else if sessions >= 3 {
                state = .mastered
            } else if sessions >= 1 {
                state = .completed
            } else {
                state = .locked
            }

            previousUnlocked = unlocked
            return TrailNode(
                unit: unit,
                nodeState: state,
                isRecommended: false,
                stickerEarned: stickerEarned
            )
        }

        return SkillTrail(nodes: nodes)
    }
}
