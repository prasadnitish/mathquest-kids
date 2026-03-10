import Foundation

final class DiagnosticService {
    private let deterministic: Bool

    init(deterministic: Bool = false) {
        self.deterministic = deterministic
    }

    func makeSession() -> DiagnosticSessionRuntime {
        let questions = Self.selectQuestions(deterministic: deterministic)
        return DiagnosticSessionRuntime(questions: questions)
    }

    func evaluate(session: DiagnosticSessionRuntime, childID: UUID, catalog: CurriculumCatalog) -> DiagnosticResult {
        let overall = session.questions.isEmpty ? 0 : Double(session.correctCount()) / Double(session.questions.count)
        let gradeScores = session.scoreByGrade()
        let domainScores = session.scoreByDomain()
        let placed = placementGrade(from: gradeScores, overall: overall)

        let weakDomains = domainScores
            .filter { $0.value < 0.65 }
            .sorted { $0.value < $1.value }
            .map { $0.key.rawValue }

        let recommendedLessonIDs = recommendedLessons(
            placedGrade: placed,
            weakDomains: Set(weakDomains),
            catalog: catalog
        )

        return DiagnosticResult(
            childID: childID,
            completedAt: Date(),
            placedGrade: placed,
            confidence: min(max(overall + 0.15, 0.35), 0.98),
            overallScore: overall,
            domainScores: Dictionary(uniqueKeysWithValues: domainScores.map { ($0.key.rawValue, $0.value) }),
            recommendedLessonIDs: recommendedLessonIDs,
            missedDomains: weakDomains
        )
    }

    private func placementGrade(from gradeScores: [GradeBand: Double], overall: Double) -> GradeBand {
        var placed: GradeBand = .kindergarten
        for grade in GradeBand.allCases {
            let score = gradeScores[grade] ?? 0
            if score >= 0.60 || (grade == .kindergarten && overall >= 0.45) {
                placed = grade
            } else {
                break
            }
        }
        return placed
    }

    private func recommendedLessons(placedGrade: GradeBand, weakDomains: Set<String>, catalog: CurriculumCatalog) -> [String] {
        let gradeLessons = catalog.lessons(for: placedGrade)
        let prioritized = gradeLessons.sorted { lhs, rhs in
            let lhsWeak = weakDomains.contains(lhs.domain.rawValue)
            let rhsWeak = weakDomains.contains(rhs.domain.rawValue)
            if lhsWeak != rhsWeak {
                return lhsWeak && !rhsWeak
            }
            return lhs.estimatedMinutes < rhs.estimatedMinutes
        }

        var recommendations = prioritized.prefix(8).map(\.id)

        if recommendations.count < 8, let previousGrade = placedGrade.previous {
            let support = catalog.lessons(for: previousGrade)
                .filter { weakDomains.contains($0.domain.rawValue) }
                .prefix(8 - recommendations.count)
                .map(\.id)
            recommendations.append(contentsOf: support)
        }

        return recommendations
    }

    private static func selectQuestions(deterministic: Bool) -> [DiagnosticQuestion] {
        let pool = questionBank
        var selected: [DiagnosticQuestion] = []

        for grade in GradeBand.allCases {
            let gradeQuestions = pool.filter { $0.targetGrade == grade }
            let chosen = deterministic ? Array(gradeQuestions.prefix(2)) : Array(gradeQuestions.shuffled().prefix(2))
            selected.append(contentsOf: chosen)
        }

        if selected.count < 12 {
            let needed = 12 - selected.count
            let leftovers = pool.filter { candidate in
                !selected.contains(where: { $0.id == candidate.id })
            }
            selected.append(contentsOf: deterministic ? leftovers.prefix(needed) : leftovers.shuffled().prefix(needed))
        }

        return deterministic ? selected : selected.shuffled()
    }

    private static let questionBank: [DiagnosticQuestion] = [
        // Kindergarten
        DiagnosticQuestion(id: "diag-k-01", prompt: "Which number is 1 more than 7?", choices: ["6", "7", "8", "9"], correctIndex: 2, targetGrade: .kindergarten, domain: .numberSense),
        DiagnosticQuestion(id: "diag-k-02", prompt: "Sam has 5 apples and gets 2 more. How many now?", choices: ["6", "7", "8", "9"], correctIndex: 1, targetGrade: .kindergarten, domain: .operations),
        DiagnosticQuestion(id: "diag-k-03", prompt: "Pick the shape with 4 equal sides.", choices: ["Triangle", "Square", "Circle", "Oval"], correctIndex: 1, targetGrade: .kindergarten, domain: .geometry),

        // Grade 1
        DiagnosticQuestion(id: "diag-g1-01", prompt: "What is 14 as tens and ones?", choices: ["1 ten and 4 ones", "4 tens and 1 one", "14 tens", "2 tens and 4 ones"], correctIndex: 0, targetGrade: .grade1, domain: .placeValue),
        DiagnosticQuestion(id: "diag-g1-02", prompt: "12 - 5 = ?", choices: ["6", "7", "8", "9"], correctIndex: 1, targetGrade: .grade1, domain: .operations),
        DiagnosticQuestion(id: "diag-g1-03", prompt: "Which equation matches this story: 9 birds, 3 fly away?", choices: ["9 + 3", "9 - 3", "3 - 9", "9 + 9"], correctIndex: 1, targetGrade: .grade1, domain: .problemSolving),

        // Grade 2
        DiagnosticQuestion(id: "diag-g2-01", prompt: "Which number is greater?", choices: ["38", "83", "They are equal", "Not sure"], correctIndex: 1, targetGrade: .grade2, domain: .placeValue),
        DiagnosticQuestion(id: "diag-g2-02", prompt: "46 + 27 = ?", choices: ["63", "73", "74", "83"], correctIndex: 1, targetGrade: .grade2, domain: .operations),
        DiagnosticQuestion(id: "diag-g2-03", prompt: "A ribbon is 35 cm. It is cut into 20 cm and ? cm.", choices: ["10", "15", "20", "25"], correctIndex: 1, targetGrade: .grade2, domain: .measurement),

        // Grade 3
        DiagnosticQuestion(id: "diag-g3-01", prompt: "Which is equivalent to 3 x 7?", choices: ["7 + 7 + 7", "3 + 7", "21 - 3", "7 + 3"], correctIndex: 0, targetGrade: .grade3, domain: .operations),
        DiagnosticQuestion(id: "diag-g3-02", prompt: "Which fraction is larger?", choices: ["1/4", "1/3", "They are equal", "Cannot tell"], correctIndex: 1, targetGrade: .grade3, domain: .fractions),
        DiagnosticQuestion(id: "diag-g3-03", prompt: "Perimeter of a 5 by 3 rectangle is:", choices: ["8", "15", "16", "30"], correctIndex: 2, targetGrade: .grade3, domain: .geometry),

        // Grade 4
        DiagnosticQuestion(id: "diag-g4-01", prompt: "What is 304 x 10?", choices: ["304", "3,040", "30,400", "314"], correctIndex: 1, targetGrade: .grade4, domain: .placeValue),
        DiagnosticQuestion(id: "diag-g4-02", prompt: "Which decimal is greatest?", choices: ["0.45", "0.405", "0.54", "0.504"], correctIndex: 2, targetGrade: .grade4, domain: .numberSense),
        DiagnosticQuestion(id: "diag-g4-03", prompt: "1/2 + 1/4 = ?", choices: ["2/6", "3/4", "1/6", "1/8"], correctIndex: 1, targetGrade: .grade4, domain: .fractions),

        // Grade 5
        DiagnosticQuestion(id: "diag-g5-01", prompt: "What is 3/5 of 20?", choices: ["8", "10", "12", "15"], correctIndex: 2, targetGrade: .grade5, domain: .fractions),
        DiagnosticQuestion(id: "diag-g5-02", prompt: "A recipe uses 1.5 cups sugar per batch. For 4 batches?", choices: ["5 cups", "5.5 cups", "6 cups", "6.5 cups"], correctIndex: 2, targetGrade: .grade5, domain: .problemSolving),
        DiagnosticQuestion(id: "diag-g5-03", prompt: "Volume of a prism 4 x 3 x 2 is:", choices: ["9", "12", "24", "48"], correctIndex: 2, targetGrade: .grade5, domain: .measurement)
    ]
}
