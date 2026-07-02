import Foundation

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
        
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("🌍 NETWORK REQUEST")
        DebugLogger.log("➡️ URL: \(urlRequest.url?.absoluteString ?? "nil")")
        DebugLogger.log("📨 Method: \(urlRequest.httpMethod ?? "")")
        
        if let headers = urlRequest.allHTTPHeaderFields {
            DebugLogger.log("📋 Headers:")
            headers.forEach { key, value in
                DebugLogger.log("   \(key): \(value)")
            }
        }
        
        if let body = urlRequest.httpBody,
           let json = String(data: body, encoding: .utf8) {
            DebugLogger.log("📦 Request Body:")
            DebugLogger.log(json)
        } else {
            DebugLogger.log("📦 Request Body: <Empty>")
        }
        
        do {
            
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DebugLogger.log("❌ Invalid HTTP Response")
                throw NetworkError.unknown
            }
            
            DebugLogger.log("⬅️ Status Code: \(httpResponse.statusCode)")
            DebugLogger.log("📦 Response Size: \(data.count) bytes")
            
            if let json = String(data: data, encoding: .utf8) {
                DebugLogger.log("📄 Response Body:")
                DebugLogger.log(json)
            } else {
                DebugLogger.log("📄 Response Body: <Unable to decode UTF8>")
            }
            
            try validate(response: response, data: data)
            
            guard !data.isEmpty else {
                DebugLogger.log("⚠️ Response data is empty.")
                throw NetworkError.noData
            }
            
            DebugLogger.log("🔄 Decoding -> \(T.self)")
            
            do {
                
                let decoded = try decoder.decode(T.self, from: data)
                
                DebugLogger.log("✅ Decode Success")
                DebugLogger.log("══════════════════════════════════════")
                
                return decoded
                
            } catch let error as DecodingError {
                
                DebugLogger.log("❌ DecodingError")
                
                switch error {
                        
                    case .keyNotFound(let key, let context):
                        DebugLogger.log("🔑 Missing Key: \(key.stringValue)")
                        DebugLogger.log("📍 \(context.debugDescription)")
                        DebugLogger.log("🛣️ CodingPath: \(context.codingPath.map(\.stringValue).joined(separator: "."))")
                        
                    case .typeMismatch(let type, let context):
                        DebugLogger.log("⚠️ Type Mismatch")
                        DebugLogger.log("Expected: \(type)")
                        DebugLogger.log("📍 \(context.debugDescription)")
                        DebugLogger.log("🛣️ CodingPath: \(context.codingPath.map(\.stringValue).joined(separator: "."))")
                        
                    case .valueNotFound(let type, let context):
                        DebugLogger.log("⚠️ Value Not Found")
                        DebugLogger.log("Type: \(type)")
                        DebugLogger.log("📍 \(context.debugDescription)")
                        DebugLogger.log("🛣️ CodingPath: \(context.codingPath.map(\.stringValue).joined(separator: "."))")
                        
                    case .dataCorrupted(let context):
                        DebugLogger.log("⚠️ Data Corrupted")
                        DebugLogger.log("📍 \(context.debugDescription)")
                        DebugLogger.log("🛣️ CodingPath: \(context.codingPath.map(\.stringValue).joined(separator: "."))")
                        
                    @unknown default:
                        DebugLogger.log("❌ Unknown Decoding Error")
                }
                
                DebugLogger.log("══════════════════════════════════════")
                
                throw NetworkError.decodingFailed(error)
                
            } catch {
                
                DebugLogger.log("❌ Decode Failed")
                DebugLogger.log(error.localizedDescription)
                DebugLogger.log("══════════════════════════════════════")
                
                throw NetworkError.decodingFailed(error)
            }
            
        } catch {
            
            DebugLogger.log("💥 Request Failed")
            DebugLogger.log(error.localizedDescription)
            DebugLogger.log("══════════════════════════════════════")
            
            throw error
        }
    }
    
    public func requestWithoutResponse(_ config: MGRequestConfig) async throws {
        
        let urlRequest = try buildURLRequest(config)
        
        DebugLogger.log("🌍 REQUEST (Void)")
        DebugLogger.log("➡️ \(urlRequest.httpMethod ?? "") \(urlRequest.url?.absoluteString ?? "")")
        
        let (data, response) = try await session.data(for: urlRequest)
        
        if let http = response as? HTTPURLResponse {
            DebugLogger.log("⬅️ Status Code: \(http.statusCode)")
        }
        
        if let json = String(data: data, encoding: .utf8) {
            DebugLogger.log(json)
        }
        
        try validate(response: response, data: data)
        
        DebugLogger.log("✅ Completed")
    }
    
        // MARK: - Private Helpers
    
    private func buildURLRequest(_ config: MGRequestConfig) throws -> URLRequest {
        
        guard var components = URLComponents(string: config.baseURL + config.path) else {
            DebugLogger.log("❌ Invalid URL")
            throw NetworkError.invalidURL
        }
        
        if let queryItems = config.queryItems,
           !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            DebugLogger.log("❌ Failed to create URL")
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = config.method.rawValue
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        config.headers?.forEach {
            request.setValue($1, forHTTPHeaderField: $0)
        }
        
        if let body = config.body {
            do {
                request.httpBody = try encode(body)
            } catch {
                DebugLogger.log("❌ Encoding Failed")
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
        
        DebugLogger.log("🔍 Validating Status: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            
            if let data,
               let json = String(data: data, encoding: .utf8) {
                
                DebugLogger.log("📄 Error Response:")
                DebugLogger.log(json)
            }
            
            throw NetworkError.serverError(
                statusCode: httpResponse.statusCode,
                data: data
            )
        }
        
        DebugLogger.log("✅ Response Valid")
    }
}
