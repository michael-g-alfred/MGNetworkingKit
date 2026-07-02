import Foundation

enum DebugLogger {

    static func log(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }
}
