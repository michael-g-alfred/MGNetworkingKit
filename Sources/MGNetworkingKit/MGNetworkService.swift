import Foundation

    // MARK: - Network Service

/// A concrete, `URLSession`-backed implementation of ``MGNetworkServiceProtocol``.
///
/// `MGNetworkService` builds a `URLRequest` from an ``MGRequestConfig``, executes it,
/// validates the HTTP status code, and decodes the response body into the
/// requested `Decodable` type. All failure paths are surfaced as ``NetworkError``,
/// so callers only ever need to handle a single error type.
///
/// ### Usage
/// ```swift
/// let config = MGRequestConfig(
///     baseURL: "https://api.example.com",
///     path: "/users/42",
///     method: .get
/// )
///
/// let user: User = try await MGNetworkService.shared.request(config)
/// ```
///
/// - Note: `MGNetworkService` is `Sendable` and safe to use from any concurrency context.
public final class MGNetworkService: MGNetworkServiceProtocol, Sendable {
    
        // MARK: Shared
    
    /// A shared, ready-to-use instance configured with `URLSession.shared`
    /// and the default JSON encoder/decoder.
    ///
    /// Use this for convenience; create your own instance instead if you
    /// need a custom `URLSession` (for example, one with a custom
    /// `URLSessionConfiguration` or a mock session for testing).
    public static let shared = MGNetworkService()
    
        // MARK: Properties
    
    /// The underlying session used to execute network requests.
    private let session: URLSession
    
    /// The decoder used to decode successful JSON responses.
    private let decoder: JSONDecoder
    
    /// The encoder used to encode `.json` request bodies.
    private let encoder: JSONEncoder
    
        // MARK: Initialization
    
    /// Creates a new network service.
    ///
    /// - Parameters:
    ///   - session: The `URLSession` used to perform requests. Defaults to `.shared`.
    ///     Inject a custom session (e.g. one built from a mock `URLProtocol`) for testing.
    ///   - decoder: The `JSONDecoder` used to decode response bodies. Defaults to
    ///     ``defaultDecoder()``.
    ///   - encoder: The `JSONEncoder` used to encode `.json` request bodies. Defaults to
    ///     ``defaultEncoder()``.
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
    
    /// Returns the default `JSONDecoder` used by ``MGNetworkService``.
    ///
    /// The default decoder uses `.iso8601` for `dateDecodingStrategy`.
    ///
    /// - Returns: A pre-configured `JSONDecoder` instance.
    public static func defaultDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
        // MARK: Encoder
    
    /// Returns the default `JSONEncoder` used by ``MGNetworkService``.
    ///
    /// The default encoder uses `.iso8601` for `dateEncodingStrategy`.
    ///
    /// - Returns: A pre-configured `JSONEncoder` instance.
    public static func defaultEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    
        // MARK: Request
    
    /// Performs a network request and decodes the response into `T`.
    ///
    /// This method builds the `URLRequest` from `config`, executes it, validates
    /// the HTTP status code, and decodes the response body as `T`.
    ///
    /// - Parameter config: The configuration describing the request to perform.
    /// - Returns: The decoded value of type `T`.
    /// - Throws: ``NetworkError``:
    ///   - `.invalidURL` if the URL cannot be constructed from `config`.
    ///   - `.encodingFailed` if a `.json` request body fails to encode.
    ///   - `.requestFailed` if the underlying transport fails (e.g. no connectivity, timeout).
    ///   - `.serverError` if the response status code is outside `200...299`.
    ///   - `.noData` if the response body is empty.
    ///   - `.decodingFailed` if the response body cannot be decoded as `T`.
    public func request<T: Decodable>(
        _ config: MGRequestConfig
    ) async throws -> T {
        
        let request = try buildURLRequest(config)
        
        let (data, response) = try await performRequest(request)
        
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
    
    /// Performs a network request that does not return a decodable response body.
    ///
    /// Use this for endpoints such as `DELETE` calls where the response body
    /// is irrelevant or empty; the response is still validated for a
    /// successful status code.
    ///
    /// - Parameter config: The configuration describing the request to perform.
    /// - Throws: ``NetworkError``:
    ///   - `.invalidURL` if the URL cannot be constructed from `config`.
    ///   - `.encodingFailed` if a `.json` request body fails to encode.
    ///   - `.requestFailed` if the underlying transport fails (e.g. no connectivity, timeout).
    ///   - `.serverError` if the response status code is outside `200...299`.
    public func requestWithoutResponse(
        _ config: MGRequestConfig
    ) async throws {
        
        let request = try buildURLRequest(config)
        
        let (data, response) = try await performRequest(request)
        
        try validate(
            response: response,
            data: data
        )
    }
    
        // MARK: Perform Request
    
    /// Executes the given `URLRequest` on `session`, normalizing any thrown
    /// error into a ``NetworkError``.
    ///
    /// Any transport-level failure (no internet, timeout, cancellation, etc.)
    /// is wrapped as ``NetworkError/requestFailed(_:)`` so that callers can
    /// reliably pattern-match on `NetworkError` alone, rather than also
    /// handling raw `URLError` values.
    ///
    /// - Parameter request: The request to execute.
    /// - Returns: A tuple of the response `Data` and `URLResponse`.
    /// - Throws: ``NetworkError/requestFailed(_:)`` if the underlying session call fails.
    private func performRequest(
        _ request: URLRequest
    ) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }
    
        // MARK: Build URLRequest
    
    /// Builds a `URLRequest` from the given configuration.
    ///
    /// This assembles the URL (including query items), sets the HTTP method,
    /// applies default and custom headers, logs outgoing query items via
    /// ``DebugLogger``, and configures the request body.
    ///
    /// - Parameter config: The configuration describing the request to build.
    /// - Returns: A fully configured `URLRequest`.
    /// - Throws: ``NetworkError/invalidURL`` if the URL cannot be constructed, or
    ///   ``NetworkError/encodingFailed(_:)`` if the request body fails to encode.
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
    
    /// Applies the given ``MGRequestBody`` to `request`, setting the
    /// appropriate `Content-Type` header and `httpBody` as needed.
    ///
    /// - Parameters:
    ///   - body: The body to apply.
    ///   - request: The request to mutate in place.
    /// - Throws: ``NetworkError/encodingFailed(_:)`` if a `.json` body fails to encode.
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
                
            case .raw(let data, let contentType):
                
                if let contentType {
                    request.setValue(
                        contentType,
                        forHTTPHeaderField: "Content-Type"
                    )
                }
                
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
    
    /// Validates that `response` represents a successful HTTP response.
    ///
    /// - Parameters:
    ///   - response: The `URLResponse` returned by the session.
    ///   - data: The response body, included in the thrown error for
    ///     non-2xx responses so callers can attempt to extract a server-provided
    ///     error message.
    /// - Throws: ``NetworkError/unknown`` if `response` is not an `HTTPURLResponse`,
    ///   or ``NetworkError/serverError(statusCode:data:)`` if the status code is
    ///   outside `200...299`.
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
