import Foundation

    // MARK: - Network Service Protocol

/// An abstraction over a network layer capable of performing configurable,
/// asynchronous HTTP requests.
///
/// Conform to this protocol to provide a testable seam over networking —
/// for example, to substitute a mock implementation in unit tests while
/// using ``MGNetworkService`` in production.
public protocol MGNetworkServiceProtocol: Sendable {
    
    /// Performs a network request and decodes the response into `T`.
    ///
    /// - Parameter config: The configuration describing the request to perform.
    /// - Returns: The decoded value of type `T`.
    /// - Throws: A ``NetworkError`` describing why the request failed.
    func request<T: Decodable>(_ config: MGRequestConfig) async throws -> T
    
    /// Performs a network request that does not return a decodable response body.
    ///
    /// - Parameter config: The configuration describing the request to perform.
    /// - Throws: A ``NetworkError`` describing why the request failed.
    func requestWithoutResponse(_ config: MGRequestConfig) async throws
}
