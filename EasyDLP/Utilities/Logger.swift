import Foundation
import os
import Observation

// MARK: - Log Level

enum LogLevel: String, CaseIterable, Identifiable, Comparable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .debug: "🔍"
        case .info: "ℹ️"
        case .warning: "⚠️"
        case .error: "❌"
        }
    }

    // Comparable conformance for filtering
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        let order: [LogLevel] = [.debug, .info, .warning, .error]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

// MARK: - Log Category

enum LogCategory: String, CaseIterable, Identifiable {
    case service = "Service"
    case parser = "Parser"
    case downloads = "Downloads"
    case binary = "Binary"
    case ui = "UI"

    var id: String { rawValue }
}

// MARK: - Log Entry

struct LogEntry: Identifiable {
    let id = UUID()
    let date: Date
    let level: LogLevel
    let category: LogCategory
    let message: String

    var formattedDate: String {
        Self.formatter.string(from: date)
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    var copyText: String {
        "[\(formattedDate)] [\(level.rawValue)] [\(category.rawValue)] \(message)"
    }
}

// MARK: - Log Store (In-Memory Ring Buffer)

/// Observable in-memory log store that feeds the Debug Console.
/// Thread-safe via actor isolation on mutations; reads happen on MainActor.
@Observable
@MainActor
class LogStore {
    static let shared = LogStore()

    private(set) var entries: [LogEntry] = []
    private let maxEntries = 2000

    func append(_ entry: LogEntry) {
        entries.append(entry)
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }

    func clear() {
        entries.removeAll()
    }

    func filteredEntries(
        searchText: String,
        category: LogCategory?,
        minLevel: LogLevel
    ) -> [LogEntry] {
        entries.filter { entry in
            entry.level >= minLevel
                && (category == nil || entry.category == category)
                && (searchText.isEmpty
                    || entry.message.localizedCaseInsensitiveContains(searchText)
                    || entry.category.rawValue.localizedCaseInsensitiveContains(searchText))
        }
    }

    func copyAll(
        searchText: String = "",
        category: LogCategory? = nil,
        minLevel: LogLevel = .debug
    ) -> String {
        filteredEntries(searchText: searchText, category: category, minLevel: minLevel)
            .map(\.copyText)
            .joined(separator: "\n")
    }
}

// MARK: - App Logger

/// Centralised loggers using Apple's Unified Logging (`os.Logger`).
/// Each category writes to both the OS log and the in-memory `LogStore`.
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.easydlp.macos"

    static let service = os.Logger(subsystem: subsystem, category: "Service")
    static let parser = os.Logger(subsystem: subsystem, category: "Parser")
    static let downloads = os.Logger(subsystem: subsystem, category: "Downloads")
    static let binary = os.Logger(subsystem: subsystem, category: "Binary")
    static let ui = os.Logger(subsystem: subsystem, category: "UI")

    // MARK: - Convenience Methods

    /// Logs to both `os.Logger` and `LogStore`.
    static func log(
        _ level: LogLevel,
        category: LogCategory,
        _ message: String
    ) {
        let osLogger: os.Logger = {
            switch category {
            case .service: service
            case .parser: parser
            case .downloads: downloads
            case .binary: binary
            case .ui: ui
            }
        }()

        switch level {
        case .debug: osLogger.debug("\(message, privacy: .public)")
        case .info: osLogger.info("\(message, privacy: .public)")
        case .warning: osLogger.warning("\(message, privacy: .public)")
        case .error: osLogger.error("\(message, privacy: .public)")
        }

        let entry = LogEntry(date: Date(), level: level, category: category, message: message)
        Task { @MainActor in
            LogStore.shared.append(entry)
        }
    }

    // MARK: - Shorthand per Category

    static func debug(_ category: LogCategory, _ message: String) {
        log(.debug, category: category, message)
    }

    static func info(_ category: LogCategory, _ message: String) {
        log(.info, category: category, message)
    }

    static func warning(_ category: LogCategory, _ message: String) {
        log(.warning, category: category, message)
    }

    static func error(_ category: LogCategory, _ message: String) {
        log(.error, category: category, message)
    }
}
