import Foundation
import OSLog

enum DiagnosticsLoggerError: LocalizedError {
    case invalidExportData

    var errorDescription: String? {
        switch self {
        case .invalidExportData:
            return "Unable to encode diagnostics text."
        }
    }
}

private enum DiagnosticsLevel {
    case debug
    case info
    case warning
    case error

    var osType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }

    var label: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARN"
        case .error: return "ERROR"
        }
    }
}

final class DiagnosticsLogger {
    static let shared = DiagnosticsLogger()

    private let logger: Logger
    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "NP.SproutMath.DiagnosticsLogger")
    private let logsDirectoryURL: URL
    private let liveLogURL: URL
    private let isoFormatter = ISO8601DateFormatter()
    private let maxLogSizeBytes = 1_000_000

    init(fileManager: FileManager = .default, subsystem: String = Bundle.main.bundleIdentifier ?? "NP.SproutMath") {
        self.fileManager = fileManager
        logger = Logger(subsystem: subsystem, category: "Diagnostics")

        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        logsDirectoryURL = baseDirectory.appendingPathComponent("SproutMath/Diagnostics", isDirectory: true)
        liveLogURL = logsDirectoryURL.appendingPathComponent("diagnostics.log")

        queue.sync {
            createStoreIfNeeded()
        }
    }

    func debug(_ message: String, metadata: [String: String] = [:], file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
        record(.debug, message, metadata: metadata, file: file, function: function, line: line)
    }

    func info(_ message: String, metadata: [String: String] = [:], file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
        record(.info, message, metadata: metadata, file: file, function: function, line: line)
    }

    func warning(_ message: String, metadata: [String: String] = [:], file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
        record(.warning, message, metadata: metadata, file: file, function: function, line: line)
    }

    func error(_ message: String, metadata: [String: String] = [:], file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
        record(.error, message, metadata: metadata, file: file, function: function, line: line)
    }

    func exportDiagnosticsFile() throws -> URL {
        var snapshot = ""

        queue.sync {
            createStoreIfNeeded()
            let body = (try? String(contentsOf: liveLogURL, encoding: .utf8)) ?? "No diagnostics events have been captured yet.\n"
            snapshot = exportHeader() + "\n\n" + body
        }

        guard let data = snapshot.data(using: .utf8) else {
            throw DiagnosticsLoggerError.invalidExportData
        }

        let timestamp = fileTimestamp(Date())
        let url = fileManager.temporaryDirectory.appendingPathComponent("SproutMath-Diagnostics-\(timestamp).txt")
        try data.write(to: url, options: .atomic)
        info("Prepared diagnostics export", metadata: ["file": url.lastPathComponent])
        return url
    }

    private func record(
        _ level: DiagnosticsLevel,
        _ message: String,
        metadata: [String: String],
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        let entry = makeEntry(level: level, message: message, metadata: metadata, file: file, function: function, line: line)
        logger.log(level: level.osType, "\(entry, privacy: .public)")
        queue.async { [weak self] in
            self?.appendEntry(entry)
        }
    }

    private func makeEntry(
        level: DiagnosticsLevel,
        message: String,
        metadata: [String: String],
        file: StaticString,
        function: StaticString,
        line: UInt
    ) -> String {
        let timestamp = isoFormatter.string(from: Date())
        let source = "\(file):\(line) \(function)"
        let cleanedMetadata = metadata
            .mapValues { $0.replacingOccurrences(of: "\n", with: " ") }
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")

        if cleanedMetadata.isEmpty {
            return "\(timestamp) [\(level.label)] \(message) [\(source)]"
        }
        return "\(timestamp) [\(level.label)] \(message) [\(source)] \(cleanedMetadata)"
    }

    private func appendEntry(_ entry: String) {
        createStoreIfNeeded()

        guard let data = "\(entry)\n".data(using: .utf8) else { return }
        guard let handle = try? FileHandle(forWritingTo: liveLogURL) else { return }
        defer { try? handle.close() }

        do {
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
        } catch {
            return
        }

        trimIfNeeded()
    }

    private func createStoreIfNeeded() {
        if !fileManager.fileExists(atPath: logsDirectoryURL.path) {
            try? fileManager.createDirectory(at: logsDirectoryURL, withIntermediateDirectories: true)
        }

        if !fileManager.fileExists(atPath: liveLogURL.path) {
            let banner = "Sprout Math local diagnostics log\n"
            if let data = banner.data(using: .utf8) {
                try? data.write(to: liveLogURL, options: .atomic)
            }
        }
    }

    private func trimIfNeeded() {
        guard
            let attrs = try? fileManager.attributesOfItem(atPath: liveLogURL.path),
            let fileSize = attrs[.size] as? NSNumber,
            fileSize.intValue > maxLogSizeBytes,
            let data = try? Data(contentsOf: liveLogURL)
        else {
            return
        }

        var trimmed = Data("... older diagnostics truncated ...\n".utf8)
        trimmed.append(data.suffix(maxLogSizeBytes / 2))
        try? trimmed.write(to: liveLogURL, options: .atomic)
    }

    private func exportHeader() -> String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = info?["CFBundleVersion"] as? String ?? "unknown"
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        let generatedAt = isoFormatter.string(from: Date())
        let locale = Locale.current.identifier
        let timeZone = TimeZone.current.identifier
        let os = ProcessInfo.processInfo.operatingSystemVersionString

        return """
        Sprout Math Diagnostics Snapshot
        GeneratedAt: \(generatedAt)
        BundleID: \(bundleID)
        Version: \(version)
        Build: \(build)
        OS: \(os)
        Locale: \(locale)
        TimeZone: \(timeZone)
        OfflineOnlyMode: \(FeatureFlags.networkDisabled)
        """
    }

    private func fileTimestamp(_ date: Date) -> String {
        let raw = isoFormatter.string(from: date)
        return raw.replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: ".", with: "-")
    }
}
