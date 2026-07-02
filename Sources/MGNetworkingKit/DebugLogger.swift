import Foundation

enum DebugLogger {
    
    enum Level {
        case info
        case success
        case warning
        case error
        case network
        
        var emoji: String {
            switch self {
                case .info:    return "ℹ️"
                case .success: return "✅"
                case .warning: return "⚠️"
                case .error:   return "❌"
                case .network: return "🌐"
            }
        }
        
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
    
    private static let reset = "\u{001B}[0m"
    
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
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
    
    static func info(
        _ message: String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    static func success(
        _ message: String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .success, file: file, function: function, line: line)
    }
    
    static func warning(
        _ message: String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    static func error(
        _ message: String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    static func network(
        _ message: String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .network, file: file, function: function, line: line)
    }
}
