import Foundation

final class SessionComposer {
    private let repository: ProgressRepository
    private let contentPack: ContentPack
    private let deterministic: Bool

    init(repository: ProgressRepository, contentPack: ContentPack, deterministic: Bool = false) {
        self.repository = repository
        self.contentPack = contentPack
        self.deterministic = deterministic
    }

    func composeSession(
        childID: UUID,
        focusUnit: UnitType,
        targetItemCount: Int = FeatureFlags.defaultSessionItems,
        date: Date = .now
    ) throws -> SessionBlueprint {
        let dueSkills = repository.dueReviewSkillIDs(childID: childID, asOf: date)
        let dueReviewTemplates = contentPack.templates(for: dueSkills)
        let focusTemplates = contentPack.templates(for: focusUnit)
        let path = UnitType.learningPath
        let focusIndex = path.firstIndex(of: focusUnit) ?? 0
        let fallbackInterleave = contentPack.itemTemplates.filter { template in
            guard template.unit != focusUnit else { return false }
            guard let idx = path.firstIndex(of: template.unit) else { return false }
            return idx < focusIndex
        }
        let recentTemplateIDs = repository.recentTemplateIDs(childID: childID, unit: focusUnit)
        let freshFocusTemplates = focusTemplates.filter { !recentTemplateIDs.contains($0.id) }
        let effectiveFocusPool = freshFocusTemplates.isEmpty ? focusTemplates : freshFocusTemplates

        guard !effectiveFocusPool.isEmpty else {
            throw NSError(domain: "SessionComposer", code: 100, userInfo: [NSLocalizedDescriptionKey: "No templates for focus unit"])
        }

        let totalItems = min(max(targetItemCount, FeatureFlags.minimumSessionItems), FeatureFlags.maximumSessionItems)
        let reviewCount = max(1, Int(Double(totalItems) * 0.25))

        let reviewPool: [ItemTemplate]
        if !dueReviewTemplates.isEmpty {
            reviewPool = dueReviewTemplates
        } else if !fallbackInterleave.isEmpty {
            reviewPool = fallbackInterleave
        } else {
            reviewPool = effectiveFocusPool
        }
        let reviewed = deterministic ? reviewPool : reviewPool.shuffled()
        let focused = deterministic ? effectiveFocusPool : effectiveFocusPool.shuffled()
        let selectedReview = Array(reviewed.prefix(reviewCount))
        let selectedFocus = Array(focused.prefix(max(0, totalItems - selectedReview.count)))

        var templates = selectedReview + selectedFocus
        if templates.count < totalItems {
            var idx = 0
            while templates.count < totalItems {
                templates.append(focused[idx % focused.count])
                idx += 1
            }
        }

        let reviewIDs = Set(selectedReview.map(\.id))
        let orderedTemplates = deterministic ? templates : templates.shuffled()
        let items = orderedTemplates.enumerated().map { idx, template in
            makePracticeItem(template: template, seed: idx, isReview: reviewIDs.contains(template.id))
        }

        let sessionID = UUID()
        try repository.startSession(sessionID: sessionID, childID: childID, unit: focusUnit)

        return SessionBlueprint(
            sessionID: sessionID,
            childID: childID,
            focusUnit: focusUnit,
            items: items,
            startedAt: date
        )
    }

    private func makePracticeItem(template: ItemTemplate, seed: Int, isReview: Bool) -> PracticeItem {
        let options: [String]
        switch template.format {
        case .subtractionStory:
            let answer = Int(template.answer) ?? template.payload.target ?? 0
            options = makeNumericOptions(answer: answer)
        case .teenPlaceValue:
            options = []
        case .twoDigitComparison, .threeDigitComparison, .fractionComparison, .decimalComparison:
            options = ["<", ">", "="]
        case .multiplicationArray, .fractionOfWhole, .volumePrism:
            let answer = Int(template.answer) ?? template.payload.target ?? 0
            options = makeNumericOptions(answer: answer)
        case .additionStory, .countAndMatch, .numberBond, .factFamily, .addTwoDigit, .subTwoDigit:
            let answer = Int(template.answer) ?? template.payload.target ?? 0
            options = makeNumericOptions(answer: answer)
        }

        return PracticeItem(
            id: "\(template.id)-\(seed)",
            templateID: template.id,
            unit: template.unit,
            skillID: template.skill,
            format: template.format,
            prompt: normalizedPrompt(template.prompt, format: template.format),
            answer: template.answer,
            supports: template.supports,
            payload: template.payload,
            options: options,
            isReview: isReview
        )
    }

    private func makeNumericOptions(answer: Int) -> [String] {
        let offsets = [-4, -2, -1, 1, 2, 3]
        var candidates = [answer]
        for offset in offsets {
            let candidate = max(0, answer + offset)
            if candidate != answer {
                candidates.append(candidate)
            }
        }

        let unique = Array(Set(candidates)).sorted()
        let selected = deterministic ? Array(unique.prefix(4)) : Array(unique.shuffled().prefix(4))
        var ensureAnswer = selected
        if !ensureAnswer.contains(answer) {
            if ensureAnswer.isEmpty {
                ensureAnswer = [answer]
            } else if ensureAnswer.count >= 4 {
                ensureAnswer[ensureAnswer.count - 1] = answer
            } else {
                ensureAnswer.append(answer)
            }
        }
        return deterministic ? ensureAnswer.sorted().map(String.init) : ensureAnswer.shuffled().map(String.init)
    }

    private func normalizedPrompt(_ prompt: String, format: ItemFormat) -> String {
        var cleaned = prompt
        let replacements = [
            ("You gives away", "You give away"),
            ("You loses", "You lose"),
            ("You packs", "You pack"),
            ("You lends", "You lend"),
            ("You uses", "You use"),
            ("You shares", "You share"),
            ("You hands out", "You hand out"),
            ("You puts back", "You put back")
        ]

        for (source, target) in replacements {
            cleaned = cleaned.replacingOccurrences(of: source, with: target)
        }

        if format == .subtractionStory {
            cleaned = cleaned.replacingOccurrences(of: "How many now?", with: "How many are left now?")
        }

        while cleaned.contains("  ") {
            cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
