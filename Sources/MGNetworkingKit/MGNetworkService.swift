import Foundation

    // MARK: - Network Service

public final class MGNetworkService: MGNetworkServiceProtocol, Sendable {
    
        // MARK: Shared
    
    public static let shared = MGNetworkService()
    
        // MARK: Properties
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
        // MARK: Initialization
    
    public init(
        session: URLSession = .shared,
        decoder: JSONDecoder = MGNetworkService.defaultDecoder(),
        encoder: JSONEncoder = MGNetworkService.defaultEncoder()
    ) {
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }
    
        // MARK: Decoder
    
    public static func defaultDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
        // MARK: Encoder
    
    public static func defaultEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    
        // MARK: Request
    
    public func request<T: Decodable>(
        _ config: MGRequestConfig
    ) async throws -> T {
        
        let request = try buildURLRequest(config)
        
        let (data, response) = try await session.data(
            for: request
        )
        
        try validate(
            response: response,
            data: data
        )
        
        guard !data.isEmpty else {
            throw NetworkError.noData
        }
        
        do {
            return try decoder.decode(
                T.self,
                from: data
            )
        } catch let error as DecodingError {
            throw NetworkError.decodingFailed(error)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
    
        // MARK: Request Without Response
    
    public func requestWithoutResponse(
        _ config: MGRequestConfig
    ) async throws {
        
        let request = try buildURLRequest(config)
        
        let (data, response) = try await session.data(
            for: request
        )
        
        try validate(
            response: response,
            data: data
        )
    }
    
        // MARK: Build URLRequest
    
    private func buildURLRequest(
        _ config: MGRequestConfig
    ) throws -> URLRequest {
        
        guard var components = URLComponents(
            string: config.baseURL + config.path
        ) else {
            throw NetworkError.invalidURL
        }
        
            // MARK: Query
        
        if let queryItems = config.queryItems,
           !queryItems.isEmpty {
            
            components.queryItems = queryItems
            
            queryItems.forEach {
                DebugLogger.network(
                    "\($0.name)=\($0.value ?? "")"
                )
            }
        }
        
            // MARK: URL
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = config.method.rawValue
        
            // MARK: Default Headers
        
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )
        
            // MARK: Custom Headers
        
        config.headers?.forEach { key, value in
            request.setValue(
                value,
                forHTTPHeaderField: key
            )
        }
        
            // MARK: Body
        
        try configureBody(
            config.body,
            for: &request
        )
        
        return request
    }
    
        // MARK: Configure Body
    
    private func configureBody(
        _ body: MGRequestBody,
        for request: inout URLRequest
    ) throws {
        
        switch body {
                
            case .none:
                break
                
                    // MARK: JSON
                
            case .json(let encodable):
                
                request.setValue(
                    "application/json",
                    forHTTPHeaderField: "Content-Type"
                )
                
                do {
                    request.httpBody = try encoder.encode(
                        encodable
                    )
                } catch {
                    throw NetworkError.encodingFailed(error)
                }
                
                    // MARK: Raw
                
            case .raw(let data):
                
                request.httpBody = data
                
                    // MARK: Multipart
                
            case .multipart(let multipart):
                
                request.setValue(
                    multipart.contentType,
                    forHTTPHeaderField: "Content-Type"
                )
                
                request.httpBody = multipart.finalizedData()
        }
    }
    
        // MARK: Validate
    
    private func validate(
        response: URLResponse,
        data: Data?
    ) throws {
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        
        guard (200...299).contains(
            httpResponse.statusCode
        ) else {
            throw NetworkError.serverError(
                statusCode: httpResponse.statusCode,
                data: data
            )
        }
    }
}
