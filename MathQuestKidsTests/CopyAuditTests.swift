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
}
