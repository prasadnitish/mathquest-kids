import Foundation

struct ContentPack: Codable {
    let units: [UnitDefinition]
    let lessons: [LessonDefinition]
    let itemTemplates: [ItemTemplate]
    let hints: [HintTemplate]
    let rewards: [RewardDefinition]

    static let empty = ContentPack(units: [], lessons: [], itemTemplates: [], hints: [], rewards: [])

    func validate() throws {
        guard !units.isEmpty else {
            throw ContentValidationError.missingUnits
        }
        guard !itemTemplates.isEmpty else {
            throw ContentValidationError.missingItems
        }

        let unitIDs = Set(units.map(\.id))
        for template in itemTemplates {
            guard unitIDs.contains(template.unit) else {
                throw ContentValidationError.orphanTemplate(template.id)
            }
            guard !template.skill.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ContentValidationError.invalidTemplate(template.id)
            }
        }
    }

    func templates(for unit: UnitType) -> [ItemTemplate] {
        itemTemplates.filter { $0.unit == unit }
    }

    func templates(for skills: Set<String>) -> [ItemTemplate] {
        itemTemplates.filter { skills.contains($0.skill) }
    }
}

struct UnitDefinition: Codable {
    let id: UnitType
    let title: String
    let order: Int
}

struct LessonDefinition: Codable {
    let id: String
    let unit: UnitType
    let title: String
    let skill: String
}

struct ItemTemplate: Codable {
    let id: String
    let unit: UnitType
    let skill: String
    let format: ItemFormat
    let difficulty: Int
    let prompt: String
    let answer: String
    let supports: [SupportType]
    let payload: ItemPayload
}

struct ItemPayload: Codable, Equatable {
    let left: Int?
    let right: Int?
    let minuend: Int?
    let subtrahend: Int?
    let target: Int?
    let tens: Int?
    let ones: Int?

    let multiplicand: Int?
    let multiplier: Int?
    let numeratorA: Int?
    let denominatorA: Int?
    let numeratorB: Int?
    let denominatorB: Int?
    let whole: Int?
    let length: Int?
    let width: Int?
    let height: Int?
    let decimalLeft: Double?
    let decimalRight: Double?

    init(
        left: Int? = nil,
        right: Int? = nil,
        minuend: Int? = nil,
        subtrahend: Int? = nil,
        target: Int? = nil,
        tens: Int? = nil,
        ones: Int? = nil,
        multiplicand: Int? = nil,
        multiplier: Int? = nil,
        numeratorA: Int? = nil,
        denominatorA: Int? = nil,
        numeratorB: Int? = nil,
        denominatorB: Int? = nil,
        whole: Int? = nil,
        length: Int? = nil,
        width: Int? = nil,
        height: Int? = nil,
        decimalLeft: Double? = nil,
        decimalRight: Double? = nil
    ) {
        self.left = left
        self.right = right
        self.minuend = minuend
        self.subtrahend = subtrahend
        self.target = target
        self.tens = tens
        self.ones = ones
        self.multiplicand = multiplicand
        self.multiplier = multiplier
        self.numeratorA = numeratorA
        self.denominatorA = denominatorA
        self.numeratorB = numeratorB
        self.denominatorB = denominatorB
        self.whole = whole
        self.length = length
        self.width = width
        self.height = height
        self.decimalLeft = decimalLeft
        self.decimalRight = decimalRight
    }
}

struct HintTemplate: Codable {
    let skill: String
    let concrete: String
    let strategy: String
    let worked: String
}

struct RewardDefinition: Codable {
    let id: String
    let title: String
    let description: String
}

enum ContentValidationError: LocalizedError {
    case missingUnits
    case missingItems
    case orphanTemplate(String)
    case invalidTemplate(String)

    var errorDescription: String? {
        switch self {
        case .missingUnits: return "Content pack has no units."
        case .missingItems: return "Content pack has no item templates."
        case .orphanTemplate(let id): return "Item template \(id) references an unknown unit."
        case .invalidTemplate(let id): return "Item template \(id) is invalid."
        }
    }
}
