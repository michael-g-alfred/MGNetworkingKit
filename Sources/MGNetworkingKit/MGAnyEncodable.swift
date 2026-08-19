import Foundation

// MARK: - Type Erased Encodable

/// A type-erased wrapper around any `Encodable & Sendable` value.
///
/// `MGAnyEncodable` allows heterogeneous encodable values to be stored and
/// passed around as a single concrete type — most notably as the associated
/// value of ``MGRequestBody/json(_:)`` — while still encoding exactly as the
/// wrapped value would.
///
/// ### Usage
/// ```swift
/// struct NewUser: Encodable, Sendable {
///     let name: String
/// }
///
/// let body = MGRequestBody.json(MGAnyEncodable(NewUser(name: "Michael")))
/// ```
public struct MGAnyEncodable: Encodable, Sendable {
    
    /// The closure that performs the actual encoding of the wrapped value.
    private let encodeHandler: @Sendable (Encoder) throws -> Void
    
    /// Wraps `value` for type-erased encoding.
    ///
    /// - Parameter value: The concrete `Encodable & Sendable` value to wrap.
    public init<T: Encodable & Sendable>(_ value: T) {
        self.encodeHandler = { encoder in
            try value.encode(to: encoder)
        }
    }
    
    /// Encodes the wrapped value using the given encoder.
    ///
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: Any error thrown by the wrapped value's own `encode(to:)` implementation.
    public func encode(to encoder: Encoder) throws {
        try encodeHandler(encoder)
    }
}
