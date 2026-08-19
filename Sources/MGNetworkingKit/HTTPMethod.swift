import Foundation

    // MARK: - HTTP Method

/// The HTTP method used for a network request.
///
/// The raw value of each case matches the corresponding HTTP verb exactly,
/// so it can be assigned directly to `URLRequest.httpMethod`.
public enum HTTPMethod: String, Sendable {
    
    /// Corresponds to `GET`. Used to retrieve a resource without side effects.
    case get = "GET"
    
    /// Corresponds to `POST`. Used to create a resource or submit data for processing.
    case post = "POST"
    
    /// Corresponds to `PUT`. Used to replace a resource in its entirety.
    case put = "PUT"
    
    /// Corresponds to `PATCH`. Used to apply a partial update to a resource.
    case patch = "PATCH"
    
    /// Corresponds to `DELETE`. Used to remove a resource.
    case delete = "DELETE"
}
