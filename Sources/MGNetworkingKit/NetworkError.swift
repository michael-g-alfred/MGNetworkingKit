import Foundation

    // MARK: - Network Error

public enum NetworkError: Error, LocalizedError, Sendable {
    case invalidURL
    case noData
    case decodingFailed(Error)
    case encodingFailed(Error)
    case requestFailed(Error)
    case serverError(statusCode: Int, data: Data?)
    case unknown
    
    @available(macOS 13, *)
    @available(iOS 16, *)
    public var errorDescription: LocalizedStringResource? {
        switch self {
            case .invalidURL:
                return "The URL is invalid"
            case .noData:
                return "No data was received from the server"
            case .decodingFailed(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .encodingFailed(let error):
                return "Failed to encode request body: \(error.localizedDescription)"
            case .requestFailed(let error):
                return "Request failed: \(error.localizedDescription)"
            case .serverError(let statusCode, _):
                return "Server returned error, status code: \(statusCode)"
            case .unknown:
                return "An unknown error occurred"
        }
    }
}
