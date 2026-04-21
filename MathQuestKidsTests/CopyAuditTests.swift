import Foundation
import Testing

struct CopyAuditTests {
    /// Source tree location relative to the test bundle. Uses environment to find repo root.
    private var featuresDir: URL {
        let here = URL(fileURLWithPath: #filePath)
        // MathQuestKidsTests/CopyAuditTests.swift -> repo root -> MathQuestKids/Features
        return here.deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("MathQuestKids/Features")
    }

    private var appDir: URL {
        let here = URL(fileURLWithPath: #filePath)
        return here.deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("MathQuestKids/App")
    }

    private func swiftFiles(in dir: URL) -> [URL] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: dir, includingPropertiesForKeys: nil) else { return [] }
        return enumerator.compactMap { ($0 as? URL).flatMap { $0.pathExtension == "swift" ? $0 : nil } }
    }

    @Test
    func childFeaturesHaveNoCaption2() throws {
        // Exclude files that are explicitly parent-mode.
        let parentOnly = ["ParentDashboardView.swift", "DomainCoverageCard.swift"]
        for file in swiftFiles(in: featuresDir) where !parentOnly.contains(file.lastPathComponent) {
            let source = try String(contentsOf: file)
            #expect(!source.contains(".caption2"), "Child-facing file \(file.lastPathComponent) uses .caption2; must be ≥13pt.")
        }
    }

    @Test
    func childFeaturesHaveNoTextCaseUpper() throws {
        let parentOnly = ["ParentDashboardView.swift", "DomainCoverageCard.swift"]
        for file in swiftFiles(in: featuresDir) where !parentOnly.contains(file.lastPathComponent) {
            let source = try String(contentsOf: file)
            #expect(!source.contains(".textCase(.uppercase)"), "Child-facing file \(file.lastPathComponent) uses .textCase(.uppercase); forbidden by design system.")
        }
    }

    @Test
    func childFeaturesHaveNoAccuracyPercentString() throws {
        // Accuracy % belongs in Parent Mode only.
        let parentOnly = ["ParentDashboardView.swift", "DomainCoverageCard.swift"]
        for file in swiftFiles(in: featuresDir) where !parentOnly.contains(file.lastPathComponent) {
            let source = try String(contentsOf: file)
            #expect(!source.contains("\"Accuracy\""),
                    "Child file \(file.lastPathComponent) renders an 'Accuracy' label; move to parent mode.")
        }
    }

    @Test
    func childFeaturesHaveNoGradeLabelInText() throws {
        let parentOnly = ["ParentDashboardView.swift", "DomainCoverageCard.swift"]
        let regex = try Regex(#"Text\(\s*"Grade \d"#)
        for file in swiftFiles(in: featuresDir) where !parentOnly.contains(file.lastPathComponent) {
            let source = try String(contentsOf: file)
            #expect(source.firstMatch(of: regex) == nil,
                    "Child file \(file.lastPathComponent) hardcodes a 'Grade N' label.")
        }
    }

    @Test
    func childFeaturesHaveNoKindergartenLabelInText() throws {
        // Specific catch for the literal "Kindergarten" — the critique flagged this on the question screen.
        let parentOnly = ["ParentDashboardView.swift", "DomainCoverageCard.swift"]
        for file in swiftFiles(in: featuresDir) where !parentOnly.contains(file.lastPathComponent) {
            let source = try String(contentsOf: file)
            #expect(!source.contains("\"Kindergarten\""),
                    "Child file \(file.lastPathComponent) uses literal 'Kindergarten' label; move to parent mode.")
        }
    }

    @Test
    func childFeaturesHaveNoForbiddenWords() throws {
        let parentOnly = ["ParentDashboardView.swift", "DomainCoverageCard.swift"]
        let forbidden = [
            "\"Wrong\"", "\"Incorrect\"",
            "\"CPA\"", "\"Spiral Review\"", "\"Variation Theory\"",
            "\"Domain\"",
        ]
        for file in swiftFiles(in: featuresDir) where !parentOnly.contains(file.lastPathComponent) {
            let source = try String(contentsOf: file)
            for word in forbidden {
                #expect(!source.contains(word),
                        "Child file \(file.lastPathComponent) contains forbidden literal \(word)")
            }
        }
    }

    @Test
    func companionPhrasesAreAtMost12Words() throws {
        let source = try String(contentsOf: appDir.appendingPathComponent("CompanionPhrases.swift"))
        // Match: a line like `return "..."` where the string is up to 200 chars.
        // Extracts the string literal between quotes.
        let regex = try Regex(#"return "([^"]{1,200})""#)
        for match in source.matches(of: regex) {
            // Regex<AnyRegexOutput>.Match — access the first captured group.
            let matchedText = String(match.output[1].substring ?? "")
            let words = matchedText.split(separator: " ").count
            #expect(words <= 12, "CompanionPhrases phrase exceeds 12 words: \"\(matchedText)\"")
        }
    }
}
