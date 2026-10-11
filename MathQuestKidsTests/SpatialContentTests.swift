import Foundation
import Testing
@testable import MathQuestKids

/// Guards the data contract between content-pack-v1.json and the spatial screens:
/// every picture the screen draws must be present in the item's payload.
struct SpatialContentTests {
    @Test
    func everySpatialItemCarriesTheDataItsScreenDraws() throws {
        let pack = try ContentLoader.loadDefaultPack()
        var checked = 0

        for template in pack.itemTemplates {
            let payload = template.payload
            switch template.format {
            case .positionWords, .gridPath:
                #expect(payload.objects?.isEmpty == false, "\(template.id) has no objects to draw")
                #expect(payload.gridSize != nil, "\(template.id) has no grid size")
                checked += 1
            case .netPreview:
                let options = payload.options ?? []
                #expect(options.count == 4, "\(template.id) should have four net options")
                #expect(options.allSatisfy { $0.cells?.isEmpty == false }, "\(template.id) has a net option with nothing to draw")
                checked += 1
            case .symmetryMirror:
                let options = payload.options ?? []
                #expect(payload.halfCells?.isEmpty == false, "\(template.id) has no half-picture")
                #expect(options.count == 4, "\(template.id) should have four mirror options")
                #expect(options.allSatisfy { $0.cells?.isEmpty == false }, "\(template.id) has a mirror option with nothing to draw")
                checked += 1
            case .rotateToMatch:
                let options = payload.options ?? []
                #expect(payload.shape != nil, "\(template.id) has no shape to draw")
                #expect(options.count == 4, "\(template.id) should have four rotation options")
                checked += 1
            default:
                break
            }
        }

        #expect(checked > 0)
    }

    @Test
    func gridPathPromptStatesTheMovesOnScreen() throws {
        let pack = try ContentLoader.loadDefaultPack()
        let gridPaths = pack.itemTemplates.filter { $0.format == .gridPath }
        #expect(!gridPaths.isEmpty)

        for template in gridPaths {
            let moves = template.payload.moves ?? ""
            #expect(!moves.isEmpty, "\(template.id) has no moves")
            #expect(template.prompt.contains(moves), "\(template.id) prompt does not show its moves")
        }
    }

    @Test
    func mirrorPictureJoinsTheHalfToTheCandidate() {
        let vertical = SpatialMirrorPictureView.combine(half: ["#.", "##"], other: ["##", "#."], axis: "vertical")
        #expect(vertical.rows == ["#.##", "###."])
        #expect(vertical.split == 2)

        let horizontal = SpatialMirrorPictureView.combine(half: ["#.", "##"], other: ["##", "#."], axis: "horizontal")
        #expect(horizontal.rows == ["#.", "##", "##", "#."])
        #expect(horizontal.split == 2)

        let blank = SpatialMirrorPictureView.combine(half: ["#."], other: nil, axis: "vertical")
        #expect(blank.rows == ["#..."])
    }
}
