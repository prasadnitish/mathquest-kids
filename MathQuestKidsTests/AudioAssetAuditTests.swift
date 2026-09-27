import Foundation
import Testing

/// Guards narration assets against mismatches the Simulator cannot catch.
///
/// The Simulator reads the bundle from the Mac's case-insensitive file system, but
/// iOS devices are case-sensitive. An index path that differs from the real file only
/// by case (e.g. `pvm-001.mp3` vs `pvM-001.mp3`) plays in the Simulator and silently
/// falls back to TTS on device, so these checks compare names exactly.
struct AudioAssetAuditTests {
    private var repoRoot: URL {
        // MathQuestKidsTests/AudioAssetAuditTests.swift -> repo root
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private var audioDir: URL {
        repoRoot.appendingPathComponent("MathQuestKids/Audio")
    }

    /// Same index files `NarrationAudioIndex.load` merges at runtime.
    private var indexFiles: [URL] {
        [
            audioDir.appendingPathComponent("audio_index.json"),
            audioDir.appendingPathComponent("future/audio_recording_set_2026_04_26_index.json"),
        ]
    }

    /// Exact-case basenames (without extension) of every bundled mp3.
    private func bundledClipNames() -> Set<String> {
        guard let enumerator = FileManager.default.enumerator(at: audioDir, includingPropertiesForKeys: nil) else {
            return []
        }
        var names = Set<String>()
        for case let url as URL in enumerator where url.pathExtension == "mp3" {
            names.insert(url.deletingPathExtension().lastPathComponent)
        }
        return names
    }

    /// Mirrors `NarrationAudioIndex.load`: values are a path string or `{"file": path}`.
    private func loadIndex() throws -> [String: String] {
        var merged: [String: String] = [:]
        for url in indexFiles {
            let raw = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any] ?? [:]
            for (key, value) in raw {
                if let path = value as? String {
                    merged[key] = path
                } else if let dict = value as? [String: Any], let path = dict["file"] as? String {
                    merged[key] = path
                }
            }
        }
        return merged
    }

    /// The words each clip was recorded from: the `text` of `{"file", "text"}` index entries,
    /// then the recording set's clips (mirrors `QuestionClips`).
    private func loadRecordedTexts() throws -> [String: String] {
        var texts: [String: String] = [:]
        for url in indexFiles {
            let raw = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any] ?? [:]
            for (key, value) in raw {
                if let text = (value as? [String: Any])?["text"] as? String {
                    texts[key] = text
                }
            }
        }
        let setURL = audioDir.appendingPathComponent("future/audio_recording_set_2026_04_26.json")
        let set = try JSONSerialization.jsonObject(with: Data(contentsOf: setURL)) as? [String: Any] ?? [:]
        for clip in set["clips"] as? [[String: Any]] ?? [] {
            if let id = clip["id"] as? String, let text = clip["text"] as? String, texts[id] == nil {
                texts[id] = text
            }
        }
        return texts
    }

    private func loadTemplates() throws -> [[String: Any]] {
        let packURL = repoRoot.appendingPathComponent("MathQuestKids/Content/content-pack-v1.json")
        let pack = try JSONSerialization.jsonObject(with: Data(contentsOf: packURL)) as? [String: Any] ?? [:]
        return pack["itemTemplates"] as? [[String: Any]] ?? []
    }

    /// Questions reworded since their clip was recorded, waiting to be recorded again
    /// (`scripts/generate_missing_audio.py` records them and keeps this list).
    private func loadAwaitingAudio() throws -> Set<String> {
        let url = repoRoot.appendingPathComponent("scripts/questions_awaiting_audio.json")
        let list = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [[String: Any]] ?? []
        return Set(list.compactMap { $0["id"] as? String })
    }

    private func words(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    private func clipName(forIndexPath path: String) -> String {
        ((path as NSString).lastPathComponent as NSString).deletingPathExtension
    }

    @Test
    func everyIndexEntryMatchesAFileWithExactCase() throws {
        let clips = bundledClipNames()
        #expect(!clips.isEmpty, "No mp3 files found under \(audioDir.path)")

        let unmatched = try loadIndex()
            .filter { !clips.contains(clipName(forIndexPath: $0.value)) }
            .map(\.key)
            .sorted()
        #expect(unmatched.isEmpty,
                "\(unmatched.count) audio index entries have no exact-case mp3 and will fall back to TTS on device: \(unmatched.prefix(10))")
    }

    @Test
    func everyPracticeItemHasNarration() throws {
        let templates = try loadTemplates()
        #expect(!templates.isEmpty, "No item templates found in content-pack-v1.json")

        // Matches `PracticeItem.audioLookupID`: an explicit audioID wins over the template id.
        let index = try loadIndex()
        let awaiting = try loadAwaitingAudio()
        let unvoiced = templates
            .compactMap { template -> String? in
                guard let id = template["id"] as? String else { return nil }
                let lookupID = template["audioID"] as? String ?? id
                return index[lookupID] == nil ? id : nil
            }
        let unexpected = unvoiced.filter { !awaiting.contains($0) }.sorted()
        #expect(unexpected.isEmpty,
                "\(unexpected.count) practice items have no narration entry and will use TTS: \(unexpected.prefix(10))")
        let recorded = awaiting.subtracting(unvoiced).sorted()
        #expect(recorded.isEmpty,
                "\(recorded.count) items in questions_awaiting_audio.json have clips now; run scripts/generate_missing_audio.py --list: \(recorded.prefix(10))")
    }

    /// A clip is recorded once, by question id. If the question is reworded later, the clip
    /// reads out the old question (different numbers from the screen), so the app won't play
    /// it: record it again or take its entry out of the index.
    @Test
    func everyQuestionClipSaysTheQuestionOnScreen() throws {
        let index = try loadIndex()
        let recordedTexts = try loadRecordedTexts()
        var checked = 0
        var mismatched: [String] = []
        for template in try loadTemplates() {
            guard let id = template["id"] as? String,
                  let spoken = template["spokenForm"] as? String ?? template["prompt"] as? String else { continue }
            let lookupID = template["audioID"] as? String ?? id
            guard index[lookupID] != nil else { continue }
            checked += 1
            if recordedTexts[lookupID].map(words) != words(spoken) {
                mismatched.append("\(id): clip says \"\(recordedTexts[lookupID] ?? "(unknown)")\", question is \"\(spoken)\"")
            }
        }
        #expect(checked > 2_000, "Only \(checked) question clips checked")
        #expect(mismatched.isEmpty,
                "\(mismatched.count) question clips don't say their question; re-record them with scripts/generate_missing_audio.py: \(mismatched.prefix(5))")
    }
}
