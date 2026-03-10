import AVFoundation
import Foundation

enum NarrationStyle: String, CaseIterable, Identifiable {
    case calm
    case playful
    case energetic
    case storyteller

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm: return "Calm"
        case .playful: return "Playful"
        case .energetic: return "Energetic"
        case .storyteller: return "Storyteller"
        }
    }
}

final class NarrationService {
    private let synthesizer = AVSpeechSynthesizer()

    func speakQuestion(_ text: String, style: NarrationStyle, interrupt: Bool = true) {
        speak(
            questionLeadIn(for: style) + text,
            style: style,
            role: .question,
            interrupt: interrupt
        )
    }

    func speakFeedback(_ text: String, style: NarrationStyle, interrupt: Bool = false) {
        speak(text, style: style, role: .feedback, interrupt: interrupt)
    }

    func preview(style: NarrationStyle) {
        speak("Hi explorer. I can read your math quests in this voice.", style: style, role: .feedback, interrupt: true)
    }

    private enum SpeechRole {
        case question
        case feedback
    }

    private func speak(_ text: String, style: NarrationStyle, role: SpeechRole, interrupt: Bool) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if interrupt, synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = bestVoice(for: style)
        utterance.volume = 0.95

        switch (style, role) {
        case (.calm, .question):
            utterance.rate = 0.42
            utterance.pitchMultiplier = 0.95
        case (.calm, .feedback):
            utterance.rate = 0.43
            utterance.pitchMultiplier = 0.98
        case (.playful, .question):
            utterance.rate = 0.43
            utterance.pitchMultiplier = 1.08
        case (.playful, .feedback):
            utterance.rate = 0.45
            utterance.pitchMultiplier = 1.12
        case (.energetic, .question):
            utterance.rate = 0.46
            utterance.pitchMultiplier = 1.14
        case (.energetic, .feedback):
            utterance.rate = 0.48
            utterance.pitchMultiplier = 1.18
        case (.storyteller, .question):
            utterance.rate = 0.45
            utterance.pitchMultiplier = 1.04
        case (.storyteller, .feedback):
            utterance.rate = 0.46
            utterance.pitchMultiplier = 1.08
        }

        utterance.preUtteranceDelay = role == .question ? 0.03 : 0
        utterance.postUtteranceDelay = role == .question ? 0.08 : 0.0
        synthesizer.speak(utterance)
    }

    private func questionLeadIn(for style: NarrationStyle) -> String {
        switch style {
        case .calm:
            return "Let's think together. "
        case .playful:
            return ["Math mission. ", "Puzzle time. ", "Your turn. "].randomElement() ?? "Your turn. "
        case .energetic:
            return ["Challenge time. ", "Here comes the next one. ", "Let's solve this. "].randomElement() ?? "Challenge time. "
        case .storyteller:
            return ["In this quest, ", "Our story begins: ", "Listen closely, "].randomElement() ?? "In this quest, "
        }
    }

    private func bestVoice(for style: NarrationStyle) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }

        let preferredNames: [String]
        switch style {
        case .calm:
            preferredNames = ["Samantha", "Allison", "Ava", "Victoria"]
        case .playful:
            preferredNames = ["Ava", "Nicky", "Samantha", "Karen"]
        case .energetic:
            preferredNames = ["Nicky", "Samantha", "Ava", "Moira"]
        case .storyteller:
            preferredNames = ["Daniel", "Alex", "Samantha", "Ava"]
        }

        for name in preferredNames {
            if let enhanced = voices.first(where: { $0.name == name && $0.quality == .enhanced }) {
                return enhanced
            }
        }

        for name in preferredNames {
            if let match = voices.first(where: { $0.name == name }) {
                return match
            }
        }

        return AVSpeechSynthesisVoice(language: "en-US")
    }
}
