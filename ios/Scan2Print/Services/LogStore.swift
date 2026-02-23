import Foundation
import os
import SwiftUI

enum LogLevel: String {
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
}

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let category: String
    let message: String

    var color: Color {
        switch level {
        case .info: return .primary
        case .warning: return .orange
        case .error: return .red
        }
    }
}

@MainActor
class LogStore: ObservableObject {
    static let shared = LogStore()

    @Published private(set) var entries: [LogEntry] = []

    private let maxEntries = 500
    private var loggers: [String: Logger] = [:]

    private init() {}

    private func logger(for category: String) -> Logger {
        if let existing = loggers[category] { return existing }
        let l = Logger(subsystem: "com.scan2print", category: category)
        loggers[category] = l
        return l
    }

    func info(_ message: String, category: String) {
        logger(for: category).info("\(message)")
        append(level: .info, category: category, message: message)
    }

    func warning(_ message: String, category: String) {
        logger(for: category).warning("\(message)")
        append(level: .warning, category: category, message: message)
    }

    func error(_ message: String, category: String) {
        logger(for: category).error("\(message)")
        append(level: .error, category: category, message: message)
    }

    func clear() {
        entries.removeAll()
    }

    private func append(level: LogLevel, category: String, message: String) {
        let entry = LogEntry(timestamp: Date(), level: level, category: category, message: message)
        entries.append(entry)
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }

    func allText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return entries.map { entry in
            "[\(formatter.string(from: entry.timestamp))] [\(entry.level.rawValue)] [\(entry.category)] \(entry.message)"
        }.joined(separator: "\n")
    }
}
