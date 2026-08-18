import Foundation

    // MARK: - Request Body

public enum MGRequestBody: Sendable {
    
    case none
    
        /// JSON body encoded using JSONEncoder.
    case json(MGAnyEncodable)
    
        /// Raw pre-encoded bytes.
    case raw(Data)
    
        /// Multipart/form-data body.
    case multipart(MultipartFormData)
}
