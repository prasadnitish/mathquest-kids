import Testing
@testable import MathQuestKids

struct MascotVoiceTests {
    @Test
    func everyPhraseIsAtMost12Words() {
        for ctx in MascotVoice.Context.allCases {
            for tone in CompanionTone.allCases {
                let phrase = MascotVoice.phrase(for: ctx, tone: tone)
                let wordCount = phrase.split(separator: " ").count
                #expect(wordCount <= 12, "Phrase exceeds 12 words (\(wordCount)): \"\(phrase)\" [\(ctx), \(tone)]")
            }
        }
    }

    @Test
    func phraseIsNotEmpty() {
        for ctx in MascotVoice.Context.allCases {
            for tone in CompanionTone.allCases {
                let phrase = MascotVoice.phrase(for: ctx, tone: tone)
                #expect(!phrase.isEmpty)
            }
        }
    }

    @Test
    func phraseNeverContainsForbiddenWords() {
        let forbidden = ["Wrong", "Incorrect", "incorrect", "wrong"]
        for ctx in MascotVoice.Context.allCases {
            for tone in CompanionTone.allCases {
                let phrase = MascotVoice.phrase(for: ctx, tone: tone)
                for word in forbidden {
                    #expect(!phrase.contains(word), "Phrase \"\(phrase)\" contains forbidden '\(word)'")
                }
            }
        }
    }
}
