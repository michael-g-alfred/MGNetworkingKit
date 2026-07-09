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
        
        DebugLogger.network("══════════════════════════════════════")
        DebugLogger.network("NETWORK REQUEST")
        DebugLogger.network("URL: \(urlRequest.url?.absoluteString ?? "nil")")
        DebugLogger.network("Method: \(urlRequest.httpMethod ?? "")")
        
        if let headers = urlRequest.allHTTPHeaderFields {
            DebugLogger.network("Headers:")
            headers.forEach { key, value in
                DebugLogger.network("\(key): \(value)")
            }
        }
        
        if let body = urlRequest.httpBody,
           let json = String(data: body, encoding: .utf8) {
            DebugLogger.network("Request Body:")
            DebugLogger.network(json)
        } else {
            DebugLogger.warning("Request Body: <Empty>")
        }
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DebugLogger.error("Invalid HTTP Response")
                throw NetworkError.unknown
            }
            
            DebugLogger.network("Status Code: \(httpResponse.statusCode)")
            DebugLogger.network("Response Size: \(data.count) bytes")
            
            if let json = String(data: data, encoding: .utf8) {
                DebugLogger.network("Response Body:")
                DebugLogger.network(json)
            } else {
                DebugLogger.warning("Response Body: <Unable to decode UTF8>")
            }
            
            try validate(response: response, data: data)
            
            guard !data.isEmpty else {
                DebugLogger.warning("Response data is empty.")
                throw NetworkError.noData
            }
            
            DebugLogger.network("Decoding -> \(T.self)")
            
            do {
                let decoded = try decoder.decode(T.self, from: data)
                DebugLogger.success("Decode Success")
                DebugLogger.success("══════════════════════════════════════")
                return decoded
            } catch let error as DecodingError {
                DebugLogger.error("DecodingError")
                
                switch error {
                    case .keyNotFound(let key, let context):
                        DebugLogger.error("Missing Key: \(key.stringValue)")
                        DebugLogger.error(context.debugDescription)
                        DebugLogger.error("CodingPath: \(context.codingPath.map(\.stringValue).joined(separator: "."))")
                        
                    case .typeMismatch(let type, let context):
                        DebugLogger.error("Type Mismatch")
                        DebugLogger.error("Expected: \(type)")
                        DebugLogger.error(context.debugDescription)
                        DebugLogger.error("CodingPath: \(context.codingPath.map(\.stringValue).joined(separator: "."))")
                        
                    case .valueNotFound(let type, let context):
                        DebugLogger.error("Value Not Found")
                        DebugLogger.error("Type: \(type)")
                        DebugLogger.error(context.debugDescription)
                        DebugLogger.error("CodingPath: \(context.codingPath.map(\.stringValue).joined(separator: "."))")
                        
                    case .dataCorrupted(let context):
                        DebugLogger.error("Data Corrupted")
                        DebugLogger.error(context.debugDescription)
                        DebugLogger.error("CodingPath: \(context.codingPath.map(\.stringValue).joined(separator: "."))")
                        
                    @unknown default:
                        DebugLogger.error("Unknown Decoding Error")
                }
                
                DebugLogger.error("══════════════════════════════════════")
                throw NetworkError.decodingFailed(error)
            } catch {
                DebugLogger.error("Decode Failed")
                DebugLogger.error(error.localizedDescription)
                DebugLogger.error("══════════════════════════════════════")
                throw NetworkError.decodingFailed(error)
            }
        } catch {
            DebugLogger.error("Request Failed")
            DebugLogger.error(error.localizedDescription)
            DebugLogger.error("══════════════════════════════════════")
            throw error
        }
    }
    
    public func requestWithoutResponse(_ config: MGRequestConfig) async throws {
        let urlRequest = try buildURLRequest(config)
        
        DebugLogger.network("REQUEST (Void)")
        DebugLogger.network("\(urlRequest.httpMethod ?? "") \(urlRequest.url?.absoluteString ?? "")")
        
        let (data, response) = try await session.data(for: urlRequest)
        
        if let http = response as? HTTPURLResponse {
            DebugLogger.network("Status Code: \(http.statusCode)")
        }
        
        if let json = String(data: data, encoding: .utf8) {
            DebugLogger.network(json)
        }
        
        try validate(response: response, data: data)
        DebugLogger.success("Completed")
    }
    
    private func buildURLRequest(_ config: MGRequestConfig) throws -> URLRequest {
        guard var components = URLComponents(string: config.baseURL + config.path) else {
            DebugLogger.error("Invalid URL: \(config.baseURL + config.path)")
            throw NetworkError.invalidURL
        }
        
        if let queryItems = config.queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
            DebugLogger.network("Query Items:")
            queryItems.forEach {
                DebugLogger.network("\($0.name)=\($0.value ?? "")")
            }
        }
        
        guard let url = components.url else {
            DebugLogger.error("Failed to create URL from URLComponents")
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
                let encodedBody = try encode(body)
                request.httpBody = encodedBody
                
                if let json = String(data: encodedBody, encoding: .utf8) {
                    DebugLogger.network("Encoded Request Body:")
                    DebugLogger.network(json)
                }
            } catch {
                DebugLogger.error("Encoding Failed")
                DebugLogger.error(error.localizedDescription)
                throw NetworkError.encodingFailed(error)
            }
        }
        
        return request
    }
    
    private func encode<E: Encodable>(_ value: E) throws -> Data {
        do {
            let data = try encoder.encode(value)
            DebugLogger.success("Body encoded successfully")
            return data
        } catch {
            DebugLogger.error("JSON Encoding Failed")
            DebugLogger.error(error.localizedDescription)
            throw error
        }
    }
    
    private func validate(response: URLResponse, data: Data?) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            DebugLogger.error("Response is not HTTPURLResponse")
            throw NetworkError.unknown
        }
        
        DebugLogger.network("Validating Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            DebugLogger.error("Server Error: \(httpResponse.statusCode)")
            
            if let data, let json = String(data: data, encoding: .utf8) {
                DebugLogger.error("Error Response:")
                DebugLogger.error(json)
            }
            
            throw NetworkError.serverError(statusCode: httpResponse.statusCode, data: data)
        }
        
        DebugLogger.success("Response Valid")
    }
}
