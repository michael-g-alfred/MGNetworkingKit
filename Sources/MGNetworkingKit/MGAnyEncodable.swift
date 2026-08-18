import Foundation

// MARK: - Type Erased Encodable

public struct MGAnyEncodable: Encodable, Sendable {
    
    private let encodeHandler: @Sendable (Encoder) throws -> Void
    
    public init<T: Encodable & Sendable>(_ value: T) {
        self.encodeHandler = { encoder in
            try value.encode(to: encoder)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        try encodeHandler(encoder)
    }
}
