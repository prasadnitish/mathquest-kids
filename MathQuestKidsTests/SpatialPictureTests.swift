import Testing
@testable import MathQuestKids

/// Spatial questions used to show only a generic icon, so choices such as "A" or "B"
/// pointed at pictures that didn't exist. These check that every question gets them.
struct SpatialPictureTests {
    private static let pictureFormats: Set<ItemFormat> = [
        .rotateToMatch, .symmetryMirror, .netPreview, .positionWords, .gridPath, .buildShape, .solidAttributes,
    ]

    @Test @MainActor
    func everySpatialQuestionHasAFigureAndChoicePictures() throws {
        let pack = try ContentLoader.loadDefaultPack()
        var checked = 0
        for template in pack.itemTemplates where Self.pictureFormats.contains(template.format) {
            let options = template.choices ?? [template.answer]
            let item = PracticeItem(
                id: template.id, templateID: template.id, unit: template.unit, skillID: template.skill,
                format: template.format, prompt: template.prompt, spokenForm: template.spokenForm,
                answer: template.answer, supports: template.supports, payload: template.payload,
                options: options, isReview: false
            )
            if template.format != .solidAttributes {
                #expect(SpatialPictures.figure(for: item, theme: .candyland) != nil, "\(template.id) has no figure")
            }
            for option in options {
                #expect(SpatialPictures.choice(option, for: item) != nil, "\(template.id) choice \(option) has no picture")
            }
            checked += 1
        }
        #expect(checked > 400)
    }

    @Test
    func netsThatFoldAreRealCubeNets() {
        for pattern in ["cross net", "T net", "zigzag net"] {
            #expect(Self.isCubeNet(NetLayouts.cells(pattern: pattern, folds: true)), "\(pattern) should fold")
        }
        for pattern in ["cross net", "T net", "zigzag net", "missing-face net", "overlap net", "strip net"] {
            #expect(!Self.isCubeNet(NetLayouts.cells(pattern: pattern, folds: false)), "\(pattern) shouldn't fold")
        }
    }

    @Test
    func piecesAreReadFromTheChoiceText() {
        #expect(ShapePieces.parse("two squares") == ["square", "square"])
        #expect(ShapePieces.parse("one triangle and one circle") == ["triangle", "circle"])
        #expect(ShapePieces.parse("four small triangles").count == 4)
        #expect(ShapePieces.parse("one hexagon") == ["hexagon"])
    }

    /// Folds a net of unit squares around a cube and checks that its six squares land on
    /// six different faces.
    private static func isCubeNet(_ cells: [(Int, Int)]) -> Bool {
        guard cells.count == 6 else { return false }
        typealias Vector = (Int, Int, Int)
        func negate(_ v: Vector) -> Vector { (-v.0, -v.1, -v.2) }

        // Each square's orientation on the cube: which face it's on, and which cube
        // directions its right and down edges point.
        var placed: [String: (face: Vector, right: Vector, down: Vector)] = [:]
        let first = cells[0]
        placed["\(first.0),\(first.1)"] = ((0, 0, 1), (1, 0, 0), (0, 1, 0))
        var queue = [first]
        while !queue.isEmpty {
            let (x, y) = queue.removeFirst()
            guard let here = placed["\(x),\(y)"] else { continue }
            let steps: [((Int, Int), (face: Vector, right: Vector, down: Vector))] = [
                ((x + 1, y), (here.right, negate(here.face), here.down)),
                ((x - 1, y), (negate(here.right), here.face, here.down)),
                ((x, y + 1), (here.down, here.right, negate(here.face))),
                ((x, y - 1), (negate(here.down), here.right, here.face)),
            ]
            for (cell, orientation) in steps where placed["\(cell.0),\(cell.1)"] == nil {
                if cells.contains(where: { $0 == cell }) {
                    placed["\(cell.0),\(cell.1)"] = orientation
                    queue.append(cell)
                }
            }
        }
        let faces = Set(placed.values.map { "\($0.face.0),\($0.face.1),\($0.face.2)" })
        return placed.count == 6 && faces.count == 6
    }
}
