import Foundation

enum UnitType: String, Codable, CaseIterable, Identifiable {
    case subtractionStories
    case teenPlaceValue
    case twoDigitComparison
    case threeDigitComparison
    case multiplicationArrays
    case fractionComparison
    case fractionOfWhole
    case volumeAndDecimals
    case kAddWithin5
    case kAddWithin10
    case kCountObjects
    case kComposeDecompose
    case g1AddWithin20
    case g1FactFamilies
    case g2AddWithin100
    case g2SubWithin100

    var id: String { rawValue }

    static var learningPath: [UnitType] {
        [
            // Kindergarten
            .kCountObjects,
            .kComposeDecompose,
            .kAddWithin5,
            .kAddWithin10,
            // Grade 1
            .g1AddWithin20,
            .g1FactFamilies,
            // Grade 2
            .g2AddWithin100,
            .g2SubWithin100,
            // Existing Grade 1–5 (keep all existing)
            .subtractionStories,
            .teenPlaceValue,
            .twoDigitComparison,
            .threeDigitComparison,
            .multiplicationArrays,
            .fractionComparison,
            .fractionOfWhole,
            .volumeAndDecimals
        ]
    }

    var title: String {
        switch self {
        case .subtractionStories: return "Subtraction Stories"
        case .teenPlaceValue: return "Teen Place Value"
        case .twoDigitComparison: return "2-Digit Comparison"
        case .threeDigitComparison: return "3-Digit Comparison"
        case .multiplicationArrays: return "Multiplication Arrays"
        case .fractionComparison: return "Fraction Comparison"
        case .fractionOfWhole: return "Fraction of Whole"
        case .volumeAndDecimals: return "Volume & Decimals"
        case .kCountObjects:      return "Count & Match"
        case .kComposeDecompose:  return "Number Bonds to 10"
        case .kAddWithin5:        return "Addition Within 5"
        case .kAddWithin10:       return "Addition Within 10"
        case .g1AddWithin20:      return "Addition Within 20"
        case .g1FactFamilies:     return "Fact Families"
        case .g2AddWithin100:     return "Add Within 100"
        case .g2SubWithin100:     return "Subtract Within 100"
        }
    }

    var subtitle: String {
        switch self {
        case .subtractionStories: return "Take away and find what's left"
        case .teenPlaceValue: return "Build numbers as 10 + ones"
        case .twoDigitComparison: return "Compare tens, then ones"
        case .threeDigitComparison: return "Compare hundreds, tens, and ones"
        case .multiplicationArrays: return "Equal groups and area arrays"
        case .fractionComparison: return "Compare fraction sizes with models"
        case .fractionOfWhole: return "Find part of a total"
        case .volumeAndDecimals: return "Reason with volume and decimals"
        case .kCountObjects:      return "Count and match objects to numbers"
        case .kComposeDecompose:  return "Find pairs of numbers that make 10"
        case .kAddWithin5:        return "Put groups together within 5"
        case .kAddWithin10:       return "Add groups and count the total"
        case .g1AddWithin20:      return "Add with pictures and equations"
        case .g1FactFamilies:     return "Relate addition and subtraction"
        case .g2AddWithin100:     return "Add two-digit numbers"
        case .g2SubWithin100:     return "Subtract two-digit numbers"
        }
    }

    var gradeHint: String {
        switch self {
        case .subtractionStories: return "K-1"
        case .teenPlaceValue: return "K-1"
        case .twoDigitComparison: return "1-2"
        case .threeDigitComparison: return "2"
        case .multiplicationArrays: return "3"
        case .fractionComparison: return "3-4"
        case .fractionOfWhole: return "5"
        case .volumeAndDecimals: return "5"
        case .kCountObjects, .kComposeDecompose, .kAddWithin5, .kAddWithin10: return "K"
        case .g1AddWithin20, .g1FactFamilies: return "1"
        case .g2AddWithin100, .g2SubWithin100: return "2"
        }
    }
}

enum MasteryStatus: String, Codable {
    case learning
    case practicing
    case mastered
    case reviewDue
}

enum InputMode: String, Codable {
    case tap
    case drag
}

enum ItemFormat: String, Codable {
    case subtractionStory
    case teenPlaceValue
    case twoDigitComparison
    case threeDigitComparison
    case multiplicationArray
    case fractionComparison
    case fractionOfWhole
    case volumePrism
    case decimalComparison
    case additionStory    // addend + addend = ?
    case countAndMatch    // count objects, tap numeral
    case numberBond       // missing part that makes 10
    case factFamily       // missing addend
    case addTwoDigit      // two-digit column addition
    case subTwoDigit      // two-digit column subtraction
}

enum SupportType: String, Codable {
    case counters
    case tenFrame
    case numberLine
    case placeValueMat
    case compareChart
    case arrayGrid
    case fractionStrip
    case areaModel
    case decimalGrid
}

struct ChildProfileRecord: Equatable {
    let id: UUID
    let displayName: String
    let createdAt: Date
}

struct AttemptInput {
    let childID: UUID
    let skillID: String
    let unit: UnitType
    let itemID: String
    let sessionID: UUID
    let response: String
    let correct: Bool
    let latencyMs: Double
    let hintsUsed: Int16
    let inputMode: InputMode
}

struct MasteryStateRecord: Equatable {
    let childID: UUID
    let skillID: String
    let status: MasteryStatus
    let masteryScore: Double
    let lastAssessedAt: Date
    let sessionCount: Int
    let recentIncorrectStreak: Int
}

struct ReviewScheduleRecord: Equatable {
    let childID: UUID
    let skillID: String
    let nextDueAt: Date
    let intervalIndex: Int
    let lapseCount: Int
}

struct SessionSummary: Equatable {
    let sessionID: UUID
    let unit: UnitType
    let totalItems: Int
    let correctItems: Int
    let rewardTitle: String
    let nextRecommendation: String
}

struct UnitProgress: Equatable, Identifiable {
    let unit: UnitType
    let completedSessions: Int
    let unlocked: Bool

    var id: UnitType { unit }
}

struct DashboardSnapshot: Equatable {
    let completedSessions: Int
    let averageAccuracy: Double
    let streakDays: Int
    let unitProgress: [UnitProgress]

    static let empty = DashboardSnapshot(
        completedSessions: 0,
        averageAccuracy: 0.0,
        streakDays: 0,
        unitProgress: UnitType.learningPath.map { UnitProgress(unit: $0, completedSessions: 0, unlocked: $0 == .kCountObjects) }
    )

    var rewardProgress: Double {
        min(1.0, Double(streakDays) / 5.0)
    }
}

struct AttemptContext {
    let unit: UnitType
    let skillID: String
    let prompt: String
    let payload: ItemPayload
    let incorrectAttempts: Int
    let recentMisconceptions: [String]
    let supports: [SupportType]
}

enum HintAction {
    case showConcreteSupport(text: String)
    case strategyPrompt(text: String)
    case workedStep(text: String)

    var encouragementLine: String {
        switch self {
        case .showConcreteSupport:
            return "Nice effort. Let's use a visual helper."
        case .strategyPrompt:
            return "Good thinking. Try this strategy hint."
        case .workedStep:
            return "You're learning. Let's do one step together."
        }
    }

    var text: String {
        switch self {
        case .showConcreteSupport(let text), .strategyPrompt(let text), .workedStep(let text):
            return text
        }
    }
}

struct PracticeItem: Identifiable, Equatable {
    let id: String
    let templateID: String
    let unit: UnitType
    let skillID: String
    let format: ItemFormat
    let prompt: String
    let spokenForm: String?
    let answer: String
    let supports: [SupportType]
    let payload: ItemPayload
    let options: [String]
    let isReview: Bool

    /// The text that TTS should read aloud. Falls back to prompt.
    var narrationText: String { spokenForm ?? prompt }
}

struct SessionBlueprint: Equatable {
    let sessionID: UUID
    let childID: UUID
    let focusUnit: UnitType
    let items: [PracticeItem]
    let startedAt: Date
}

struct PraiseLibrary {
    private static let success = [
        "Great strategy!",
        "You kept trying and solved it!",
        "Nice math thinking!",
        "Strong effort, nice job!",
        "That was careful math work!",
        "You noticed the important part. Nice job!"
    ]

    private static let retry = [
        "Nice try. Let's look again.",
        "You're learning. Try one more time.",
        "Good effort. Use the hint if you want.",
        "Keep going. You can do this step.",
        "You're close. Check one part and try again.",
        "Good thinking. Adjust one step and test it again."
    ]

    static func randomCorrectPraise() -> String {
        success.randomElement() ?? "Great strategy!"
    }

    static func randomRetryPrompt() -> String {
        retry.randomElement() ?? "Nice try. Let's look again."
    }
}
