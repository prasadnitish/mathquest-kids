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
    let spokenForm: String?
    let choices: [String]?
    let audioID: String?
    let answer: String
    let supports: [SupportType]
    let payload: ItemPayload

    init(
        id: String,
        unit: UnitType,
        skill: String,
        format: ItemFormat,
        difficulty: Int,
        prompt: String,
        spokenForm: String?,
        choices: [String]? = nil,
        audioID: String? = nil,
        answer: String,
        supports: [SupportType],
        payload: ItemPayload
    ) {
        self.id = id
        self.unit = unit
        self.skill = skill
        self.format = format
        self.difficulty = difficulty
        self.prompt = prompt
        self.spokenForm = spokenForm
        self.choices = choices
        self.audioID = audioID
        self.answer = answer
        self.supports = supports
        self.payload = payload
    }

    /// The text that should be read aloud by TTS.
    /// Falls back to `prompt` when no spoken form is provided.
    var narrationText: String { spokenForm ?? prompt }
}

struct ItemPayload: Codable, Equatable {
    let left: Int?
    let right: Int?
    let minuend: Int?
    let subtrahend: Int?
    let target: Double?
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

    // Shape attributes
    let sides: Int?
    let corners: Int?
    let shapeName: String?

    // Time & money
    let hours: Int?
    let minutes: Int?
    let cents: Int?

    // Division
    let dividend: Int?
    let divisor: Int?

    // Angles
    let degrees: Int?

    // Data plots (stored as JSON arrays)
    let barValues: [Int]?
    let barLabels: [String]?

    // Ratios
    let ratioLeft: Int?
    let ratioRight: Int?

    // Spatial reasoning
    let targetShape: String?
    let targetCount: Int?
    let context: String?
    let gridSize: SpatialGridSize?
    let scene: [SpatialSceneObject]?
    let relation: String?
    let anchor: String?
    let objects: [SpatialSceneObject]?
    let shape: String?
    let color: String?
    let rotationDegrees: Int?
    let options: [SpatialOption]?
    let correctPieces: String?
    let distractorPieces: [String]?
    let rotationAllowed: Bool?
    let object: String?
    let axis: String?
    let answerChoice: String?
    let start: String?
    let startPosition: SpatialGridPoint?
    let moves: String?
    let delta: SpatialGridPoint?
    let targetPosition: SpatialGridPoint?
    let targetObject: String?
    let solidName: String?
    let faces: Int?
    let edges: Int?
    let vertices: Int?
    let attribute: String?
    let realWorldObjects: [String]?
    let targetSolid: String?

    init(
        left: Int? = nil,
        right: Int? = nil,
        minuend: Int? = nil,
        subtrahend: Int? = nil,
        target: Double? = nil,
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
        decimalRight: Double? = nil,
        sides: Int? = nil,
        corners: Int? = nil,
        shapeName: String? = nil,
        hours: Int? = nil,
        minutes: Int? = nil,
        cents: Int? = nil,
        dividend: Int? = nil,
        divisor: Int? = nil,
        degrees: Int? = nil,
        barValues: [Int]? = nil,
        barLabels: [String]? = nil,
        ratioLeft: Int? = nil,
        ratioRight: Int? = nil,
        targetShape: String? = nil,
        targetCount: Int? = nil,
        context: String? = nil,
        gridSize: SpatialGridSize? = nil,
        scene: [SpatialSceneObject]? = nil,
        relation: String? = nil,
        anchor: String? = nil,
        objects: [SpatialSceneObject]? = nil,
        shape: String? = nil,
        color: String? = nil,
        rotationDegrees: Int? = nil,
        options: [SpatialOption]? = nil,
        correctPieces: String? = nil,
        distractorPieces: [String]? = nil,
        rotationAllowed: Bool? = nil,
        object: String? = nil,
        axis: String? = nil,
        answerChoice: String? = nil,
        start: String? = nil,
        startPosition: SpatialGridPoint? = nil,
        moves: String? = nil,
        delta: SpatialGridPoint? = nil,
        targetPosition: SpatialGridPoint? = nil,
        targetObject: String? = nil,
        solidName: String? = nil,
        faces: Int? = nil,
        edges: Int? = nil,
        vertices: Int? = nil,
        attribute: String? = nil,
        realWorldObjects: [String]? = nil,
        targetSolid: String? = nil
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
        self.sides = sides
        self.corners = corners
        self.shapeName = shapeName
        self.hours = hours
        self.minutes = minutes
        self.cents = cents
        self.dividend = dividend
        self.divisor = divisor
        self.degrees = degrees
        self.barValues = barValues
        self.barLabels = barLabels
        self.ratioLeft = ratioLeft
        self.ratioRight = ratioRight
        self.targetShape = targetShape
        self.targetCount = targetCount
        self.context = context
        self.gridSize = gridSize
        self.scene = scene
        self.relation = relation
        self.anchor = anchor
        self.objects = objects
        self.shape = shape
        self.color = color
        self.rotationDegrees = rotationDegrees
        self.options = options
        self.correctPieces = correctPieces
        self.distractorPieces = distractorPieces
        self.rotationAllowed = rotationAllowed
        self.object = object
        self.axis = axis
        self.answerChoice = answerChoice
        self.start = start
        self.startPosition = startPosition
        self.moves = moves
        self.delta = delta
        self.targetPosition = targetPosition
        self.targetObject = targetObject
        self.solidName = solidName
        self.faces = faces
        self.edges = edges
        self.vertices = vertices
        self.attribute = attribute
        self.realWorldObjects = realWorldObjects
        self.targetSolid = targetSolid
    }
}

struct SpatialGridSize: Codable, Equatable {
    let columns: Int
    let rows: Int
}

struct SpatialGridPoint: Codable, Equatable {
    let x: Int
    let y: Int
}

struct SpatialSceneObject: Codable, Equatable {
    let name: String?
    let shape: String?
    let color: String?
    let x: Int
    let y: Int
    let rotation: Int?
    let target: Bool?
}

struct SpatialOption: Codable, Equatable {
    let label: String?
    let shape: String?
    let rotation: Int?
    let mirrored: Bool?
    let mirrorsCorrectly: Bool?
    let pattern: String?
    let description: String?
    let foldsToCube: Bool?
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
