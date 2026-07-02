import Foundation

    // MARK: - Network Service Implementation

public final class MGNetworkService: MGNetworkServiceProtocol, Sendable {
    
    public static let shared = MGNetworkService()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    public init(
        session: URLSession = .shared,
        decoder: JSONDecoder = MGNetworkService.defaultDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }
    
    public static func defaultDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
        // MARK: - Public Request Methods
    
    public func request<T: Decodable>(_ config: MGRequestConfig) async throws -> T {
        let urlRequest = try buildURLRequest(config)
        let (data, response) = try await session.data(for: urlRequest)
        
        try validate(response: response, data: data)
        
        guard !data.isEmpty else { throw NetworkError.noData }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
    
    public func requestWithoutResponse(_ config: MGRequestConfig) async throws {
        let urlRequest = try buildURLRequest(config)
        let (data, response) = try await session.data(for: urlRequest)
        try validate(response: response, data: data)
    }
    
        // MARK: - Private Helpers
    
    private func buildURLRequest(_ config: MGRequestConfig) throws -> URLRequest {
        guard var components = URLComponents(string: config.baseURL + config.path) else {
            throw NetworkError.invalidURL
        }
        
        if let queryItems = config.queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else { throw NetworkError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = config.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        config.headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        if let body = config.body {
            do {
                request.httpBody = try encode(body)
            } catch {
                throw NetworkError.encodingFailed(error)
            }
        }
        
        return request
    }
    
    private func encode<E: Encodable>(_ value: E) throws -> Data {
        try encoder.encode(value)
    }
    
    private func validate(response: URLResponse, data: Data?) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode, data: data)
        }
    }
}
