import Foundation

    // MARK: - Request Body

/// The body of an HTTP request sent by ``MGNetworkService``.
///
/// Use this enum to describe how the request body should be constructed and,
/// where applicable, what `Content-Type` header should accompany it.
public enum MGRequestBody: Sendable {
    
    /// No request body. Appropriate for methods like `GET` or `DELETE`.
    case none
    
    /// A JSON body encoded using the service's `JSONEncoder`.
    ///
    /// Sets the `Content-Type` header to `application/json`.
    ///
    /// - Parameter value: A type-erased ``MGAnyEncodable`` wrapping the value to encode.
    case json(MGAnyEncodable)
    
    /// Raw, pre-encoded bytes sent as-is.
    ///
    /// Use this when you already have a serialized payload (e.g. Protocol
    /// Buffers, an image, or a pre-built JSON string) that shouldn't be
    /// re-encoded.
    ///
    /// - Parameters:
    ///   - data: The raw bytes to send as the request body.
    ///   - contentType: An optional `Content-Type` header value to apply.
    ///     Pass `nil` to leave the `Content-Type` header unset.
    case raw(Data, contentType: String? = nil)
    
    /// A `multipart/form-data` body, typically used for file uploads.
    ///
    /// Sets the `Content-Type` header to the multipart boundary derived from
    /// the supplied ``MultipartFormData``.
    ///
    /// - Parameter multipart: The multipart form data to send.
    case multipart(MGMultipartFormData)
}
