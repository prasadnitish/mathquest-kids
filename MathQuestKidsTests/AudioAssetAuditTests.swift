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
        let packURL = repoRoot.appendingPathComponent("MathQuestKids/Content/content-pack-v1.json")
        let pack = try JSONSerialization.jsonObject(with: Data(contentsOf: packURL)) as? [String: Any] ?? [:]
        let templates = pack["itemTemplates"] as? [[String: Any]] ?? []
        #expect(!templates.isEmpty, "No item templates found in \(packURL.lastPathComponent)")

        // Matches `PracticeItem.audioLookupID`: an explicit audioID wins over the template id.
        let index = try loadIndex()
        let unvoiced = templates
            .compactMap { template -> String? in
                guard let id = template["id"] as? String else { return nil }
                let lookupID = template["audioID"] as? String ?? id
                return index[lookupID] == nil ? id : nil
            }
            .sorted()
        #expect(unvoiced.isEmpty,
                "\(unvoiced.count) practice items have no narration entry and will use TTS: \(unvoiced.prefix(10))")
    }
}
