import Foundation
import os

enum LogLevel: String {
    case debug = "🐛 DEBUG"
    case info = "ℹ️ INFO"
    case warning = "⚠️ WARNING"
    case error = "❌ ERROR"
}

struct Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "OurPet"

    static func log(
        _ message: String,
        level: LogLevel = .debug,
        tag: String = "App",
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) {
        let fileName = (file as NSString).lastPathComponent
        let thread = Thread.isMainThread ? "Main" : "BG"
        let formatted = "[\(level.rawValue)][\(tag)][\(fileName):\(line):\(column) \(function)] [\(thread)] \(message)"
        #if DEBUG
        print(formatted)
        #else
        os_log("%@", log: OSLog(subsystem: subsystem, category: tag), type: osLogType(for: level), formatted)
        #endif
    }

    static func debug(_ message: String, tag: String = "App", file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        log(message, level: .debug, tag: tag, file: file, function: function, line: line, column: column)
    }

    static func info(_ message: String, tag: String = "App", file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        log(message, level: .info, tag: tag, file: file, function: function, line: line, column: column)
    }

    static func warning(_ message: String, tag: String = "App", file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        log(message, level: .warning, tag: tag, file: file, function: function, line: line, column: column)
    }

    static func error(_ message: String, tag: String = "App", file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        log(message, level: .error, tag: tag, file: file, function: function, line: line, column: column)
    }

    private static func osLogType(for level: LogLevel) -> OSLogType {
        switch level {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
}

extension String {
    var decodingUnicodeEscapes: String {
        let mutable = NSMutableString(string: self)
        if CFStringTransform(mutable, nil, "Any-Hex/Java" as NSString, true) {
            return mutable as String
        }
        let jsonString = "\"\(self)\""
        if let data = jsonString.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(String.self, from: data) {
            return decoded
        }
        return self
    }
}

extension Date {
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    var iso8601: String {
        Date.iso8601Formatter.string(from: self)
    }
}
