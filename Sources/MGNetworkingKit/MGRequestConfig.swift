import Foundation

    // MARK: - Generic Request Config

/// A complete description of a single network request, consumed by
/// ``MGNetworkServiceProtocol`` implementations to build and execute a `URLRequest`.
///
/// ### Usage
/// ```swift
/// let config = MGRequestConfig(
///     baseURL: "https://api.example.com",
///     path: "/users",
///     method: .post,
///     headers: ["Authorization": "Bearer \(token)"],
///     body: .json(MGAnyEncodable(newUser))
/// )
/// ```
public struct MGRequestConfig: Sendable {
    
        // MARK: Properties
    
    /// The scheme and host portion of the request URL, e.g. `"https://api.example.com"`.
    public var baseURL: String
    
    /// The path appended to `baseURL`, e.g. `"/users/42"`.
    public var path: String
    
    /// The HTTP method to use for the request. Defaults to ``HTTPMethod/get``.
    public var method: HTTPMethod
    
    /// Query items appended to the request URL. `nil` or empty means no query string.
    public var queryItems: [URLQueryItem]?
    
    /// Additional headers to apply on top of the service's default headers.
    ///
    /// Keys in this dictionary overwrite any default header with the same name.
    public var headers: [String: String]?
    
    /// The request body to send. Defaults to ``MGRequestBody/none``.
    public var body: MGRequestBody
    
        // MARK: Initialization
    
    /// Creates a new request configuration.
    ///
    /// - Parameters:
    ///   - baseURL: The scheme and host portion of the request URL.
    ///   - path: The path appended to `baseURL`.
    ///   - method: The HTTP method to use. Defaults to ``HTTPMethod/get``.
    ///   - queryItems: Query items to append to the URL. Defaults to `nil`.
    ///   - headers: Additional headers to apply. Defaults to `nil`.
    ///   - body: The request body to send. Defaults to ``MGRequestBody/none``.
    public init(
        baseURL: String,
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem]? = nil,
        headers: [String: String]? = nil,
        body: MGRequestBody = .none
    ) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
    }
}
