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

    // MARK: - Audio playback (pre-generated MP3s)

    private var audioPlayer: AVAudioPlayer?
    private let audioIndex: [String: String]  // id → relative path

    // MARK: - Fallback TTS

    private let synthesizer = AVSpeechSynthesizer()

    /// Whether any audio (pre-generated or TTS) is currently playing.
    var isSpeaking: Bool {
        (audioPlayer?.isPlaying ?? false) || synthesizer.isSpeaking
    }

    // MARK: - Init

    init() {
        // Load the audio index that maps IDs to file paths
        // Try subdirectory first (folder reference), then root (flattened copy)
        let url = Bundle.main.url(forResource: "audio_index", withExtension: "json", subdirectory: "Audio")
            ?? Bundle.main.url(forResource: "audio_index", withExtension: "json")

        if let url,
           let data = try? Data(contentsOf: url),
           let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Support both flat strings ("id": "path") and dicts ("id": {"file": "path", ...})
            var resolved: [String: String] = [:]
            for (key, value) in raw {
                if let str = value as? String {
                    resolved[key] = str
                } else if let dict = value as? [String: Any], let file = dict["file"] as? String {
                    resolved[key] = file
                }
            }
            audioIndex = resolved
            print("[NarrationService] Loaded audio index: \(resolved.count) entries")
        } else {
            audioIndex = [:]
            print("[NarrationService] audio_index.json not found in bundle")
        }
    }

    // MARK: - Public API

    /// Speak a question — tries pre-generated audio first, falls back to TTS.
    /// Pass the item ID to look up pre-generated audio.
    func speakQuestion(_ text: String, style: NarrationStyle, interrupt: Bool = true, itemID: String? = nil) {
        if interrupt {
            stopAll()
        }

        // Try pre-generated audio by item ID
        if let itemID, playPreGenerated(id: itemID) {
            return
        }

        // Fallback to system TTS
        speakWithTTS(questionLeadIn(for: style) + text, style: style, role: .question)
    }

    /// Speak feedback text — tries to match known feedback phrases, falls back to TTS.
    func speakFeedback(_ text: String, style: NarrationStyle, interrupt: Bool = false) {
        if interrupt {
            stopAll()
        }

        // Try known feedback audio by scanning for matching text
        if playPreGeneratedByText(text, categories: ["feedback", "companion", "diagnostic"]) {
            return
        }

        // Fallback to system TTS
        speakWithTTS(text, style: style, role: .feedback)
    }

    /// Preview voice for settings screen.
    func preview(style: NarrationStyle) {
        stopAll()
        if playPreGenerated(id: "preview-voice") {
            return
        }
        speakWithTTS("Hi explorer. I can read your math problems in this voice.", style: style, role: .feedback)
    }

    /// Stop all audio playback.
    func stopAll() {
        audioPlayer?.stop()
        audioPlayer = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    // MARK: - Pre-generated audio playback

    private func playPreGenerated(id: String) -> Bool {
        guard let relativePath = audioIndex[id] else {
            return false
        }

        let filename = ((relativePath as NSString).lastPathComponent as NSString).deletingPathExtension
        let subdir = (relativePath as NSString).deletingLastPathComponent

        // Try multiple bundle layouts — Xcode may preserve or flatten the directory structure
        let url = Bundle.main.url(forResource: filename, withExtension: "mp3", subdirectory: "Audio/\(subdir)")
            ?? Bundle.main.url(forResource: (relativePath as NSString).deletingPathExtension, withExtension: "mp3", subdirectory: "Audio")
            ?? Bundle.main.url(forResource: filename, withExtension: "mp3", subdirectory: "Audio")
            ?? Bundle.main.url(forResource: filename, withExtension: "mp3")

        guard let url else {
            return false
        }

        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 0.95
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            return true
        } catch {
            print("[NarrationService] AVAudioPlayer init failed for id: \(error.localizedDescription)")
            return false
        }
    }

    /// Search for pre-generated audio by matching text content.
    /// Used for feedback phrases where we don't have an item ID.
    private func playPreGeneratedByText(_ text: String, categories: [String]) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Direct lookup from known text-to-audio-ID mappings
        let knownMappings: [String: String] = [
            // Session completion
            "Great finish!": "session-end-00",
            "Nice persistence. You did it!": "session-end-01",
            // Hint encouragement
            "Nice effort. Let us use a visual helper.": "hint-encourage-00",
            "Good thinking. Try this strategy hint.": "hint-encourage-01",
            "You are learning. Let us do one step together.": "hint-encourage-02",
            // Preview
            "Hi explorer. I can read your math problems in this voice.": "preview-voice",
            // Diagnostic feedback
            "Thanks for showing your thinking. I will use that to choose the next challenge.": "diag-feedback-00",
            "Thanks for telling me. I will use that to find a better starting point.": "diag-feedback-01",
            "Nice number sense. I am noting how confidently that was solved.": "diag-feedback-02",
            "Strong thinking. I am using that strategy signal for the next question.": "diag-feedback-03",
            "Nice place-value thinking. That helps tune the next level.": "diag-feedback-04",
            "Good reasoning. I am checking how stories and equations connect.": "diag-feedback-05",
            "Nice noticing. That helps me place the next shape or measurement task.": "diag-feedback-06",
            "Careful measurement thinking. I am using that to shape the next task.": "diag-feedback-07",
            "Nice fraction reasoning. That gives me a clearer picture of the right level.": "diag-feedback-08",
        ]

        let companionMappings: [String: String] = [
            "Awesome job!": "companion-correct_encouraging-00",
            "You got it!": "companion-correct_encouraging-01",
            "Way to go!": "companion-correct_encouraging-02",
            "Super!": "companion-correct_encouraging-03",
            "You did it!": "companion-correct_encouraging-04",
            "Boom! Nailed it!": "companion-correct_energetic-00",
            "Yes! Crushed it!": "companion-correct_energetic-01",
            "Woo-hoo!": "companion-correct_energetic-02",
            "Incredible!": "companion-correct_energetic-03",
            "Amazing!": "companion-correct_energetic-04",
            "Well done.": "companion-correct_calm-00",
            "Nicely solved.": "companion-correct_calm-01",
            "That is correct.": "companion-correct_calm-02",
            "Good work.": "companion-correct_calm-03",
            "Right answer.": "companion-correct_calm-04",
            "Almost there!": "companion-incorrect_encouraging-00",
            "Try again!": "companion-incorrect_encouraging-01",
            "You can do it!": "companion-incorrect_encouraging-02",
            "Keep going!": "companion-incorrect_encouraging-03",
            "Nice try!": "companion-incorrect_encouraging-04",
            "Oops! Try once more!": "companion-incorrect_energetic-00",
            "So close! Give it another shot!": "companion-incorrect_energetic-01",
            "Not quite! You got this!": "companion-incorrect_energetic-02",
            "Not quite. Try again.": "companion-incorrect_calm-00",
            "Close. Think it through.": "companion-incorrect_calm-01",
            "Let us try once more.": "companion-incorrect_calm-02",
            "Here is a hint.": "companion-hint_intros-00",
            "Let me help.": "companion-hint_intros-01",
            "Try thinking about it this way.": "companion-hint_intros-02",
            "Want a clue?": "companion-hint_intros-03",
            "How about a little help?": "companion-hint_intros-04",
            "You earned a sticker!": "companion-sticker_earned-00",
            "New sticker unlocked!": "companion-sticker_earned-01",
            "Check out your new sticker!": "companion-sticker_earned-02",
            "A sticker just for you!": "companion-sticker_earned-03",
        ]

        let praiseMappings: [String: String] = [
            "Great strategy!": "praise-00",
            "You kept trying and solved it!": "praise-01",
            "Nice math thinking!": "praise-02",
            "Strong effort, nice job!": "praise-03",
            "That was careful math work!": "praise-04",
            "You noticed the important part. Nice job!": "praise-05",
            "Nice try. Let us look again.": "retry-00",
            "You are learning. Try one more time.": "retry-01",
            "Good effort. Use the hint if you want.": "retry-02",
            "Keep going. You can do this step.": "retry-03",
            "You are close. Check one part and try again.": "retry-04",
            "Good thinking. Adjust one step and test it again.": "retry-05",
        ]

        let allMappings = knownMappings
            .merging(companionMappings) { a, _ in a }
            .merging(praiseMappings) { a, _ in a }

        if let id = allMappings[trimmed] {
            return playPreGenerated(id: id)
        }

        return false
    }

    // MARK: - Fallback TTS (AVSpeechSynthesizer)

    private enum SpeechRole {
        case question
        case feedback
    }

    private func speakWithTTS(_ text: String, style: NarrationStyle, role: SpeechRole) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif

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

        // Prefer premium > enhanced > default
        for name in preferredNames {
            if let premium = voices.first(where: { $0.name == name && $0.quality == .premium }) {
                return premium
            }
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
