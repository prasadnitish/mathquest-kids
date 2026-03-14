import Foundation

enum GradeBand: String, Codable, CaseIterable, Identifiable, Comparable {
    case kindergarten
    case grade1
    case grade2
    case grade3
    case grade4
    case grade5

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kindergarten: return "Kindergarten"
        case .grade1: return "Grade 1"
        case .grade2: return "Grade 2"
        case .grade3: return "Grade 3"
        case .grade4: return "Grade 4"
        case .grade5: return "Grade 5"
        }
    }

    var shortLabel: String {
        switch self {
        case .kindergarten: return "K"
        case .grade1: return "1"
        case .grade2: return "2"
        case .grade3: return "3"
        case .grade4: return "4"
        case .grade5: return "5"
        }
    }

    static func < (lhs: GradeBand, rhs: GradeBand) -> Bool {
        lhs.order < rhs.order
    }

    var order: Int {
        switch self {
        case .kindergarten: return 0
        case .grade1: return 1
        case .grade2: return 2
        case .grade3: return 3
        case .grade4: return 4
        case .grade5: return 5
        }
    }

    var previous: GradeBand? {
        GradeBand.allCases.first { $0.order == order - 1 }
    }

    var next: GradeBand? {
        GradeBand.allCases.first { $0.order == order + 1 }
    }
}

enum PedagogyStrategy: String, Codable, CaseIterable, Hashable, Identifiable {
    case concretePictorialAbstract
    case numberBonds
    case barModeling
    case workedExamples
    case guidedDiscovery
    case mathTalk
    case mentalMath
    case spiralReview
    case variationTheory
    case areaModeling
    case errorAnalysis
    case patternGeneralization

    var id: String { rawValue }

    var title: String {
        switch self {
        case .concretePictorialAbstract: return "CPA"
        case .numberBonds: return "Number Bonds"
        case .barModeling: return "Bar Modeling"
        case .workedExamples: return "Worked Examples"
        case .guidedDiscovery: return "Guided Discovery"
        case .mathTalk: return "Math Talk"
        case .mentalMath: return "Mental Math"
        case .spiralReview: return "Spiral Review"
        case .variationTheory: return "Variation Theory"
        case .areaModeling: return "Area Models"
        case .errorAnalysis: return "Error Analysis"
        case .patternGeneralization: return "Patterning"
        }
    }

    var description: String {
        switch self {
        case .concretePictorialAbstract:
            return "Start with manipulatives, then visuals, then symbols."
        case .numberBonds:
            return "Part-part-whole decomposition for flexible arithmetic."
        case .barModeling:
            return "Visual models to reason through multi-step problems."
        case .workedExamples:
            return "Teacher-led examples before independent attempts."
        case .guidedDiscovery:
            return "Prompt noticing and explanation, not guessing."
        case .mathTalk:
            return "Students verbalize strategies and compare methods."
        case .mentalMath:
            return "Efficient mental calculation routines and fluency strings."
        case .spiralReview:
            return "Daily mixed retrieval from previously learned skills."
        case .variationTheory:
            return "Carefully varied examples to reveal structure."
        case .areaModeling:
            return "Use rectangular/area representations for multiplication and division."
        case .errorAnalysis:
            return "Analyze mistakes as learning opportunities."
        case .patternGeneralization:
            return "Generalize arithmetic and geometric patterns."
        }
    }
}

enum LessonDomain: String, Codable, CaseIterable, Identifiable {
    case countingCardinality
    case operationsAlgebraicThinking
    case numberOperationsBaseTen
    case fractions
    case measurementData
    case geometry
    case ratiosExpressions

    var id: String { rawValue }

    var title: String {
        switch self {
        case .countingCardinality: return "Counting & Cardinality"
        case .operationsAlgebraicThinking: return "Operations & Algebraic Thinking"
        case .numberOperationsBaseTen: return "Number & Operations in Base Ten"
        case .fractions: return "Fractions"
        case .measurementData: return "Measurement & Data"
        case .geometry: return "Geometry"
        case .ratiosExpressions: return "Ratios & Expressions Foundations"
        }
    }
}

struct CurriculumCatalog: Codable, Equatable {
    let grades: [GradePlan]

    static let empty = CurriculumCatalog(grades: [])

    var allLessons: [LessonPlanItem] {
        grades.flatMap(\.lessons)
    }

    func gradePlan(for grade: GradeBand) -> GradePlan? {
        grades.first { $0.grade == grade }
    }

    func lessons(for grade: GradeBand) -> [LessonPlanItem] {
        gradePlan(for: grade)?.lessons ?? []
    }

    func lesson(id: String) -> LessonPlanItem? {
        allLessons.first { $0.id == id }
    }

    func validate() throws {
        guard !grades.isEmpty else {
            throw CurriculumValidationError.missingGrades
        }

        let gradeSet = Set(grades.map(\.grade))
        for grade in GradeBand.allCases where !gradeSet.contains(grade) {
            throw CurriculumValidationError.missingGrade(grade)
        }

        let ids = allLessons.map(\.id)
        guard ids.count == Set(ids).count else {
            throw CurriculumValidationError.duplicateLessonID
        }

        for grade in grades {
            guard !grade.lessons.isEmpty else {
                throw CurriculumValidationError.missingLessons(grade.grade)
            }
            for lesson in grade.lessons where lesson.grade != grade.grade {
                throw CurriculumValidationError.lessonGradeMismatch(lesson.id)
            }
        }
    }
}

struct GradePlan: Codable, Equatable, Identifiable {
    let grade: GradeBand
    let overview: String
    let bigIdeas: [String]
    let lessons: [LessonPlanItem]

    var id: GradeBand { grade }
}

struct LessonPlanItem: Codable, Equatable, Identifiable {
    let id: String
    let grade: GradeBand
    let title: String
    let domain: LessonDomain
    let objective: String
    let standards: [String]
    let strategies: [PedagogyStrategy]
    let estimatedMinutes: Int
    let isPlayableInApp: Bool
    let linkedUnit: UnitType?
    let activityPrompt: String

    init(
        id: String, grade: GradeBand, title: String, domain: LessonDomain,
        objective: String, standards: [String], strategies: [PedagogyStrategy],
        estimatedMinutes: Int, isPlayableInApp: Bool, linkedUnit: UnitType?,
        activityPrompt: String
    ) {
        self.id = id; self.grade = grade; self.title = title; self.domain = domain
        self.objective = objective; self.standards = standards; self.strategies = strategies
        self.estimatedMinutes = estimatedMinutes; self.isPlayableInApp = isPlayableInApp
        self.linkedUnit = linkedUnit; self.activityPrompt = activityPrompt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        grade = try container.decode(GradeBand.self, forKey: .grade)
        title = try container.decode(String.self, forKey: .title)
        domain = try container.decode(LessonDomain.self, forKey: .domain)
        objective = try container.decode(String.self, forKey: .objective)
        standards = try container.decode([String].self, forKey: .standards)
        strategies = try container.decode([PedagogyStrategy].self, forKey: .strategies)
        estimatedMinutes = try container.decode(Int.self, forKey: .estimatedMinutes)
        isPlayableInApp = try container.decode(Bool.self, forKey: .isPlayableInApp)
        activityPrompt = try container.decode(String.self, forKey: .activityPrompt)
        // Gracefully handle linkedUnit values that don't match a UnitType enum case
        // (future units referenced in the curriculum but not yet playable in-app)
        if let raw = try container.decodeIfPresent(String.self, forKey: .linkedUnit) {
            linkedUnit = UnitType(rawValue: raw)
        } else {
            linkedUnit = nil
        }
    }
}

enum DiagnosticDomain: String, Codable, CaseIterable, Identifiable {
    case numberSense
    case operations
    case placeValue
    case fractions
    case measurement
    case geometry
    case problemSolving

    var id: String { rawValue }

    var title: String {
        switch self {
        case .numberSense: return "Number Sense"
        case .operations: return "Operations"
        case .placeValue: return "Place Value"
        case .fractions: return "Fractions"
        case .measurement: return "Measurement"
        case .geometry: return "Geometry"
        case .problemSolving: return "Problem Solving"
        }
    }
}

struct DiagnosticQuestion: Identifiable, Equatable {
    let id: String
    let prompt: String
    let choices: [String]
    let correctIndex: Int
    let targetGrade: GradeBand
    let domain: DiagnosticDomain
}

struct DiagnosticSessionRuntime: Equatable {
    let questions: [DiagnosticQuestion]
    private(set) var index: Int = 0
    private(set) var selectedIndexes: [String: Int] = [:]

    var currentQuestion: DiagnosticQuestion {
        guard !questions.isEmpty, index < questions.count else {
            preconditionFailure("DiagnosticSessionRuntime.currentQuestion accessed at index \(index) but questions has \(questions.count) elements")
        }
        return questions[index]
    }

    var isComplete: Bool {
        index >= questions.count
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return min(1.0, Double(index) / Double(questions.count))
    }

    mutating func submit(choiceIndex: Int) {
        guard !isComplete else { return }
        selectedIndexes[currentQuestion.id] = choiceIndex
        index += 1
    }

    func selectedIndex(for questionID: String) -> Int? {
        selectedIndexes[questionID]
    }

    func correctCount() -> Int {
        questions.reduce(into: 0) { count, question in
            if selectedIndexes[question.id] == question.correctIndex {
                count += 1
            }
        }
    }

    func scoreByDomain() -> [DiagnosticDomain: Double] {
        var grouped: [DiagnosticDomain: (correct: Int, total: Int)] = [:]
        for question in questions {
            var current = grouped[question.domain] ?? (0, 0)
            current.total += 1
            if selectedIndexes[question.id] == question.correctIndex {
                current.correct += 1
            }
            grouped[question.domain] = current
        }

        return grouped.reduce(into: [:]) { output, pair in
            let total = max(pair.value.total, 1)
            output[pair.key] = Double(pair.value.correct) / Double(total)
        }
    }

    func scoreByGrade() -> [GradeBand: Double] {
        var grouped: [GradeBand: (correct: Int, total: Int)] = [:]
        for question in questions {
            var current = grouped[question.targetGrade] ?? (0, 0)
            current.total += 1
            if selectedIndexes[question.id] == question.correctIndex {
                current.correct += 1
            }
            grouped[question.targetGrade] = current
        }

        return grouped.reduce(into: [:]) { output, pair in
            let total = max(pair.value.total, 1)
            output[pair.key] = Double(pair.value.correct) / Double(total)
        }
    }
}

struct DiagnosticResult: Codable, Equatable {
    let childID: UUID
    let completedAt: Date
    let placedGrade: GradeBand
    let confidence: Double
    let overallScore: Double
    let domainScores: [String: Double]
    let recommendedLessonIDs: [String]
    let missedDomains: [String]
}

struct AdaptiveLessonPath: Equatable {
    let placedGrade: GradeBand
    let confidence: Double
    let recommendedLessons: [LessonPlanItem]
    let supportLessons: [LessonPlanItem]
    let stretchLessons: [LessonPlanItem]
    let pedagogyHighlights: [PedagogyStrategy]

    static let empty = AdaptiveLessonPath(
        placedGrade: .kindergarten,
        confidence: 0,
        recommendedLessons: [],
        supportLessons: [],
        stretchLessons: [],
        pedagogyHighlights: []
    )

    var hasRecommendations: Bool {
        !recommendedLessons.isEmpty
    }
}

enum CurriculumValidationError: LocalizedError {
    case missingGrades
    case missingGrade(GradeBand)
    case missingLessons(GradeBand)
    case duplicateLessonID
    case lessonGradeMismatch(String)

    var errorDescription: String? {
        switch self {
        case .missingGrades:
            return "Curriculum catalog has no grades."
        case .missingGrade(let grade):
            return "Curriculum catalog is missing \(grade.title)."
        case .missingLessons(let grade):
            return "Curriculum catalog has no lessons for \(grade.title)."
        case .duplicateLessonID:
            return "Curriculum catalog has duplicate lesson ids."
        case .lessonGradeMismatch(let lessonID):
            return "Lesson \(lessonID) has a mismatched grade assignment."
        }
    }
}
