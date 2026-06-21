import Foundation

    // MARK: - Generic Request Config

public struct MGRequestConfig: Sendable {
    public var baseURL: String
    public var path: String
    public var method: HTTPMethod
    public var queryItems: [URLQueryItem]?
    public var headers: [String: String]?
    public var body: (Encodable & Sendable)?
    
    public init(
        baseURL: String,
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem]? = nil,
        headers: [String: String]? = nil,
        body: (Encodable & Sendable)? = nil
    ) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
    }
}
