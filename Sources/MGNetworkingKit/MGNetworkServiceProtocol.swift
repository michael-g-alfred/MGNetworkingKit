import Foundation

    // MARK: - Network Service Protocol

public protocol MGNetworkServiceProtocol: Sendable {
    func request<T: Decodable>(_ config: MGRequestConfig) async throws -> T
    func requestWithoutResponse(_ config: MGRequestConfig) async throws
}
