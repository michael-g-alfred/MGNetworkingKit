import Foundation

public final class MGNetworkService: MGNetworkServiceProtocol, Sendable {
    
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
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
    public static func defaultEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    
    public func request<T: Decodable>(_ config: MGRequestConfig) async throws -> T {
        let urlRequest = try buildURLRequest(config)
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown
            }
            _ = httpResponse
            
            try validate(response: response, data: data)
            
            guard !data.isEmpty else {
                throw NetworkError.noData
            }
            
            do {
                let decoded = try decoder.decode(T.self, from: data)
                return decoded
            } catch let error as DecodingError {
                throw NetworkError.decodingFailed(error)
            } catch {
                throw NetworkError.decodingFailed(error)
            }
        } catch {
            throw error
        }
    }
    
    public func requestWithoutResponse(_ config: MGRequestConfig) async throws {
        let urlRequest = try buildURLRequest(config)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        try validate(response: response, data: data)
    }
    
    private func buildURLRequest(_ config: MGRequestConfig) throws -> URLRequest {
        guard var components = URLComponents(string: config.baseURL + config.path) else {
            throw NetworkError.invalidURL
        }
        
        if let queryItems = config.queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
            queryItems.forEach {
                DebugLogger.network("\($0.name)=\($0.value ?? "")")
            }
        }
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = config.method.rawValue
        
            // Only default to JSON content-type when this isn't a raw-body
            // request (e.g. multipart/form-data uploads set their own
            // Content-Type with boundary via config.headers below).
        if config.rawBody == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        config.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
            // Raw body (e.g. multipart/form-data) takes priority and is sent
            // verbatim — never passed through JSONEncoder, since Data itself
            // conforms to Encodable and would otherwise be base64-wrapped
            // inside a JSON string, corrupting the multipart boundary bytes.
        if let rawBody = config.rawBody {
            request.httpBody = rawBody
        } else if let body = config.body {
            do {
                let encodedBody = try encode(body)
                request.httpBody = encodedBody
            } catch {
                throw NetworkError.encodingFailed(error)
            }
        }
        
        return request
    }
    
    private func encode<E: Encodable>(_ value: E) throws -> Data {
        return try encoder.encode(value)
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
