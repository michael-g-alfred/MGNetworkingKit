import Foundation

/// A lightweight, colorized console logger for use during development.
///
/// `DebugLogger` prints structured, leveled messages tagged with the calling
/// file, function, and line number. All output is compiled only in `DEBUG`
/// builds, so calls are inert (and free) in release builds.
///
/// ### Usage
/// ```swift
/// DebugLogger.info("Fetching user profile")
/// DebugLogger.success("Profile loaded")
/// DebugLogger.error("Failed to parse response")
/// ```
enum DebugLogger {
    
    /// The severity/category of a logged message, determining its emoji and color.
    enum Level {
        
        /// General informational messages.
        case info
        
        /// Messages indicating a successful operation.
        case success
        
        /// Messages warning of a potential issue that isn't necessarily fatal.
        case warning
        
        /// Messages indicating a failure or error condition.
        case error
        
        /// Messages related to network activity, such as outgoing query parameters.
        case network
        
        /// The emoji prefix used to visually distinguish this level in console output.
        var emoji: String {
            switch self {
                case .info:    return "ℹ️"
                case .success: return "✅"
                case .warning: return "⚠️"
                case .error:   return "❌"
                case .network: return "🌐"
            }
        }
        
        /// The ANSI color escape code used to colorize this level's console output.
        var color: String {
            switch self {
                case .info:    return "\u{001B}[0;36m"
                case .success: return "\u{001B}[0;32m"
                case .warning: return "\u{001B}[0;33m"
                case .error:   return "\u{001B}[0;31m"
                case .network: return "\u{001B}[0;35m"
            }
        }
    }
    
    /// The ANSI escape code used to reset console text color after each message.
    private static let reset = "\u{001B}[0m"
    
    /// The date formatter used to render the timestamp shown in each log entry.
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    /// Logs a message at the given level, tagged with the caller's file, function, and line.
    ///
    /// This method is a no-op in non-`DEBUG` builds.
    ///
    /// - Parameters:
    ///   - message: The message to log.
    ///   - level: The severity/category of the message. Defaults to ``Level/info``.
    ///   - file: The file the call originates from. Defaults to `#fileID`; you
    ///     typically don't need to pass this explicitly.
    ///   - function: The function the call originates from. Defaults to `#function`.
    ///   - line: The line the call originates from. Defaults to `#line`.
    static func log(
        _ message: String,
        level: Level = .info,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
#if DEBUG
        let time = formatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        
        print("""
\(level.color)\(level.emoji) [\(time)]
📄 \(fileName)
🔹 \(function)
📍 Line: \(line)
\(message)
\(reset)
""")
#endif
    }
    
    /// Logs an informational message. See ``log(_:level:file:function:line:)``.
    ///
    /// - Parameters:
    ///   - message: The message to log.
    ///   - file: The file the call originates from. Defaults to `#fileID`.
    ///   - function: The function the call originates from. Defaults to `#function`.
    ///   - line: The line the call originates from. Defaults to `#line`.
    static func info(
        _ message: String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    /// Logs a success message. See ``log(_:level:file:function:line:)``.
    ///
    /// - Parameters:
    ///   - message: The message to log.
    ///   - file: The file the call originates from. Defaults to `#fileID`.
    ///   - function: The function the call originates from. Defaults to `#function`.
    ///   - line: The line the call originates from. Defaults to `#line`.
    static func success(
        _ message: String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .success, file: file, function: function, line: line)
    }
    
    /// Logs a warning message. See ``log(_:level:file:function:line:)``.
    ///
    /// - Parameters:
    ///   - message: The message to log.
    ///   - file: The file the call originates from. Defaults to `#fileID`.
    ///   - function: The function the call originates from. Defaults to `#function`.
    ///   - line: The line the call originates from. Defaults to `#line`.
    static func warning(
        _ message: String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    /// Logs an error message. See ``log(_:level:file:function:line:)``.
    ///
    /// - Parameters:
    ///   - message: The message to log.
    ///   - file: The file the call originates from. Defaults to `#fileID`.
    ///   - function: The function the call originates from. Defaults to `#function`.
    ///   - line: The line the call originates from. Defaults to `#line`.
    static func error(
        _ message: String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    /// Logs a network-related message, such as an outgoing query parameter.
    /// See ``log(_:level:file:function:line:)``.
    ///
    /// - Parameters:
    ///   - message: The message to log.
    ///   - file: The file the call originates from. Defaults to `#fileID`.
    ///   - function: The function the call originates from. Defaults to `#function`.
    ///   - line: The line the call originates from. Defaults to `#line`.
    static func network(
        _ message: String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .network, file: file, function: function, line: line)
    }
}
