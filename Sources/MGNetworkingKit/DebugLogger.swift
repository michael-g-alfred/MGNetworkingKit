import Foundation

enum DebugLogger {
    
    enum Color: String {
        case reset  = "\u{001B}[0m"
        
        case red    = "\u{001B}[0;31m"
        case green  = "\u{001B}[0;32m"
        case yellow = "\u{001B}[0;33m"
        case blue   = "\u{001B}[0;34m"
        case purple = "\u{001B}[0;35m"
        case cyan   = "\u{001B}[0;36m"
        case white  = "\u{001B}[0;37m"
    }
    
    static func log(_ message: String, color: Color = .reset) {
#if DEBUG
        print("\(color.rawValue)\(message)\(Color.reset.rawValue)")
#endif
    }
}
