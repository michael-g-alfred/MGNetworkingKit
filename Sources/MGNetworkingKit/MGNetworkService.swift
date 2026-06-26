import Foundation

    // MARK: - Network Service Implementation

public final class MGNetworkService: MGNetworkServiceProtocol, @unchecked Sendable {
    
    public static let shared = MGNetworkService()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    public init(
        session: URLSession = .shared,
        decoder: JSONDecoder = MGNetworkService.defaultDecoder(),
        encoder: JSONEncoder = MGNetworkService.defaultEncoder()
    ) {
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }
    
    public static func defaultDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if let date = formatter.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Invalid date format: \(str)")
        }
        
        return decoder
    }
    
    public static func defaultEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
    
        // MARK: - Request that decodes a response (T is inferred from how you call it)
    
    public func request<T: Decodable>(_ config: MGRequestConfig) async throws -> T {
        let urlRequest = try buildURLRequest(config)
        return try await execute(urlRequest)
    }
    
        // MARK: - Request with no decoded response (e.g. 204 No Content)
    
    public func requestWithoutResponse(_ config: MGRequestConfig) async throws {
        let urlRequest = try buildURLRequest(config)
        let (data, response) = try await performRequest(urlRequest)
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
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = config.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        config.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = config.body {
            do {
                request.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw NetworkError.encodingFailed(error)
            }
        }
        
        return request
    }
    
    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }
    
    private func validate(response: URLResponse, data: Data?) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode, data: data)
        }
    }
    
    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await performRequest(request)
        try validate(response: response, data: data)
        
        guard !data.isEmpty else {
            throw NetworkError.noData
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
}
