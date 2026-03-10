import Foundation

final class AdaptiveLessonPlanner {
    func buildPath(result: DiagnosticResult?, catalog: CurriculumCatalog) -> AdaptiveLessonPath {
        guard let result else {
            let starter = catalog.lessons(for: .kindergarten)
            return AdaptiveLessonPath(
                placedGrade: .kindergarten,
                confidence: 0,
                recommendedLessons: Array(starter.prefix(6)),
                supportLessons: [],
                stretchLessons: [],
                pedagogyHighlights: [.concretePictorialAbstract, .mathTalk, .spiralReview]
            )
        }

        let placedGrade = result.placedGrade
        let weakDomains = Set(result.missedDomains)

        let recommendedFromResult = result.recommendedLessonIDs.compactMap { catalog.lesson(id: $0) }
        let fallbackGradeLessons = catalog.lessons(for: placedGrade)

        let recommended = !recommendedFromResult.isEmpty
            ? recommendedFromResult
            : prioritize(lessons: fallbackGradeLessons, weakDomains: weakDomains)

        let supportLessons: [LessonPlanItem]
        if let previous = placedGrade.previous {
            let previousGradeLessons = catalog.lessons(for: previous)
            supportLessons = prioritize(lessons: previousGradeLessons, weakDomains: weakDomains).prefix(4).map { $0 }
        } else {
            supportLessons = []
        }

        let stretchLessons: [LessonPlanItem]
        if let next = placedGrade.next {
            let nextGradeLessons = catalog.lessons(for: next)
            stretchLessons = prioritize(lessons: nextGradeLessons, weakDomains: []).prefix(4).map { $0 }
        } else {
            stretchLessons = []
        }

        let pedagogyHighlights = strategyHighlights(from: Array(recommended.prefix(8)))

        return AdaptiveLessonPath(
            placedGrade: placedGrade,
            confidence: result.confidence,
            recommendedLessons: Array(recommended.prefix(10)),
            supportLessons: supportLessons,
            stretchLessons: stretchLessons,
            pedagogyHighlights: pedagogyHighlights
        )
    }

    private func prioritize(lessons: [LessonPlanItem], weakDomains: Set<String>) -> [LessonPlanItem] {
        lessons.sorted { lhs, rhs in
            let lhsWeak = weakDomains.contains(lhs.domain.rawValue)
            let rhsWeak = weakDomains.contains(rhs.domain.rawValue)
            if lhsWeak != rhsWeak {
                return lhsWeak && !rhsWeak
            }
            return lhs.estimatedMinutes < rhs.estimatedMinutes
        }
    }

    private func strategyHighlights(from lessons: [LessonPlanItem]) -> [PedagogyStrategy] {
        var seen: Set<PedagogyStrategy> = []
        var ordered: [PedagogyStrategy] = []

        for lesson in lessons {
            for strategy in lesson.strategies where !seen.contains(strategy) {
                seen.insert(strategy)
                ordered.append(strategy)
            }
        }

        if ordered.isEmpty {
            return [.concretePictorialAbstract, .guidedDiscovery, .spiralReview]
        }

        return Array(ordered.prefix(5))
    }
}
