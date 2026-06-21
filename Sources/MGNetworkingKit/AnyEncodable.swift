import Foundation

    // MARK: - AnyEncodable
    // Lets you pass any concrete Encodable as a request body, type-erased,
    // since `Encodable` alone can't be used as an existential for encoding directly.

public struct AnyEncodable: Encodable, Sendable {
    private let encodeClosure: @Sendable (Encoder) throws -> Void
    
    public init(_ encodable: Encodable & Sendable) {
        self.encodeClosure = encodable.encode
    }
    
    public func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
