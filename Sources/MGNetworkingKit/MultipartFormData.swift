import Foundation

// MARK: - Multipart Form Data

public struct MultipartFormData: Sendable {
    
    // MARK: Properties
    
    public let boundary: String
    
    private var body = Data()
    
    // MARK: Initialization
    
    public init(
        boundary: String = UUID().uuidString
    ) {
        self.boundary = boundary
    }
    
    // MARK: File
    
    public mutating func appendFile(
        fieldName: String,
        fileName: String,
        mimeType: String,
        data: Data
    ) {
        append("--\(boundary)\r\n")
        
        append(
            "Content-Disposition: form-data; " +
            "name=\"\(fieldName)\"; " +
            "filename=\"\(fileName)\"\r\n"
        )
        
        append("Content-Type: \(mimeType)\r\n")
        append("\r\n")
        
        body.append(data)
        
        append("\r\n")
    }
    
    // MARK: Field
    
    public mutating func appendField(
        name: String,
        value: String
    ) {
        append("--\(boundary)\r\n")
        
        append(
            "Content-Disposition: form-data; " +
            "name=\"\(name)\"\r\n"
        )
        
        append("\r\n")
        append(value)
        append("\r\n")
    }
    
    // MARK: Finalize
    
    public func finalizedData() -> Data {
        var result = body
        
        result.append(
            Data("--\(boundary)--\r\n".utf8)
        )
        
        return result
    }
    
    // MARK: Content Type
    
    public var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }
    
    // MARK: Private
    
    private mutating func append(
        _ string: String
    ) {
        body.append(
            Data(string.utf8)
        )
    }
}
