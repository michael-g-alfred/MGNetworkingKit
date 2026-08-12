import Foundation

    // MARK: - Generic Request Config

public struct MGRequestConfig: Sendable {
    public var baseURL: String
    public var path: String
    public var method: HTTPMethod
    public var queryItems: [URLQueryItem]?
    public var headers: [String: String]?

        /// JSON-encodable body. Goes through `JSONEncoder` — do NOT pass raw
        /// `Data` here (e.g. multipart bytes), since `Data` itself conforms
        /// to `Encodable` and would get base64-wrapped inside a JSON string
        /// instead of being sent as-is.
    public var body: (Encodable & Sendable)?

        /// Raw, pre-encoded body (e.g. multipart/form-data, file uploads).
        /// When set, this is sent verbatim as `request.httpBody` and bypasses
        /// `JSONEncoder` entirely. Takes priority over `body` if both are set.
    public var rawBody: Data?

    public init(
        baseURL: String,
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem]? = nil,
        headers: [String: String]? = nil,
        body: (Encodable & Sendable)? = nil,
        rawBody: Data? = nil
    ) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.rawBody = rawBody
    }
}
