import Foundation

    // MARK: - Network Error

/// The set of errors that can be thrown by ``MGNetworkServiceProtocol`` implementations.
///
/// Every failure produced by ``MGNetworkService`` is normalized to one of
/// these cases, so callers can handle networking failures without needing
/// to inspect underlying `URLError` or `DecodingError` types directly.
public enum NetworkError: Error, LocalizedError, Sendable {
    
    /// The request's URL could not be constructed from the supplied ``MGRequestConfig``.
    case invalidURL
    
    /// The server returned a successful status code but an empty response body
    /// where a decodable value was expected.
    case noData
    
    /// The response body could not be decoded into the requested type.
    ///
    /// - Parameter error: The underlying decoding error, typically a `DecodingError`.
    case decodingFailed(Error)
    
    /// The request body could not be encoded.
    ///
    /// - Parameter error: The underlying encoding error.
    case encodingFailed(Error)
    
    /// The underlying network transport failed, e.g. due to no connectivity,
    /// a timeout, or cancellation.
    ///
    /// - Parameter error: The underlying error thrown by `URLSession`.
    case requestFailed(Error)
    
    /// The server responded with a status code outside the `200...299` range.
    ///
    /// - Parameters:
    ///   - statusCode: The HTTP status code returned by the server.
    ///   - data: The raw response body, if any, which may contain a
    ///     server-provided error message.
    case serverError(statusCode: Int, data: Data?)
    
    /// An error occurred that doesn't fit any other case, such as receiving
    /// a non-HTTP `URLResponse`.
    case unknown
    
    /// A human-readable description of the error, suitable for display or logging.
    public var errorDescription: String? {
        switch self {
            case .invalidURL:
                return "The URL is invalid"
            case .noData:
                return "No data was received from the server"
            case .decodingFailed(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .encodingFailed(let error):
                return "Failed to encode request body: \(error.localizedDescription)"
            case .requestFailed(let error):
                return "Request failed: \(error.localizedDescription)"
            case .serverError(let statusCode, let data):
                if let data, let message = Self.extractMessage(from: data) {
                    return message
                }
                return "Server returned error, status code: \(statusCode)"
            case .unknown:
                return "An unknown error occurred"
        }
    }
    
    /// Attempts to extract a human-readable message from a JSON error body.
    ///
    /// Looks for a top-level `"message"` or `"error"` string key, e.g.
    /// `{"message": "..."}` or `{"error": "..."}`.
    ///
    /// - Parameter data: The raw response body to inspect.
    /// - Returns: The extracted message, or `nil` if `data` isn't a JSON object
    ///   containing one of the recognized keys.
    private static func extractMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return (json["message"] as? String) ?? (json["error"] as? String)
    }
}
