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
    
    public var errorDescription: String? {
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
            case .serverError(let statusCode, let data):
                if let data, let message = Self.extractMessage(from: data) {
                    return message
                }
                return "Server returned error, status code: \(statusCode)"
            case .unknown:
                return "An unknown error occurred"
        }
    }
    
        // Tries to extract a human-readable message from a JSON error body,
        // e.g. {"message": "..."} or {"error": "..."}
    private static func extractMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return (json["message"] as? String) ?? (json["error"] as? String)
    }
}
