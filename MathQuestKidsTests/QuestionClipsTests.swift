import Foundation
import Testing
@testable import MathQuestKids

/// A recorded question clip plays only when it says the question on screen. Questions get
/// reworded after they're recorded, and the old clip would read out different numbers.
struct QuestionClipsTests {
    @Test @MainActor
    func rewordedQuestionIsNotReadByItsOldClip() {
        // as100-001 was a story problem when it was recorded; the screen now shows 25 + 45.
        let clips = QuestionClips(recordedTexts: ["as100-001": "A box has 41 cats. You add 22 more. How many?"])
        #expect(!clips.clip("as100-001", says: "What is 25 plus 45?"))
        #expect(clips.clip("as100-001", says: "A box has 41 cats.  You add 22 more. How many? "))
    }

    @Test @MainActor
    func clipWithoutRecordedWordsIsNotPlayed() {
        let clips = QuestionClips(recordedTexts: [:])
        #expect(!clips.clip("add5-001", says: "What is 2 plus 1?"))
    }

    @Test @MainActor
    func bundledClipsSayTheirQuestions() throws {
        let pack = try ContentLoader.loadDefaultPack()
        let index = try NarrationAudioIndex.load(bundle: .main)
        let clips = QuestionClips.load(bundle: .main)

        let voiced = pack.itemTemplates.filter { index[$0.audioID ?? $0.id] != nil }
        let silent = voiced.filter { !clips.clip($0.audioID ?? $0.id, says: $0.narrationText) }.map(\.id)
        #expect(voiced.count > 2_000)
        #expect(silent.isEmpty, "\(silent.count) bundled clips don't say their question: \(silent.prefix(10))")

        let diagnostics = DiagnosticService.questionBank.filter { !clips.clip($0.id, says: $0.prompt) }.map(\.id)
        #expect(diagnostics.isEmpty, "Placement questions without a matching clip: \(diagnostics)")
    }
}
