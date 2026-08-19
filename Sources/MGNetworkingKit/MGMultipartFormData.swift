import Foundation

// MARK: - Multipart Form Data

/// Builds a `multipart/form-data` request body from files and plain fields.
///
/// ### Usage
/// ```swift
/// var form = MultipartFormData()
/// form.appendField(name: "title", value: "My Upload")
/// form.appendFile(
///     fieldName: "photo",
///     fileName: "avatar.jpg",
///     mimeType: "image/jpeg",
///     data: imageData
/// )
///
/// let body = MGRequestBody.multipart(form)
/// ```
public struct MGMultipartFormData: Sendable {
    
    // MARK: Properties
    
    /// The boundary string used to separate parts of the multipart body.
    public let boundary: String
    
    /// The accumulated body data as parts are appended.
    private var body = Data()
    
    // MARK: Initialization
    
    /// Creates a new multipart form data builder.
    ///
    /// - Parameter boundary: The boundary string used to separate parts.
    ///   Defaults to a randomly generated UUID string, which is sufficient
    ///   for virtually all use cases.
    public init(
        boundary: String = UUID().uuidString
    ) {
        self.boundary = boundary
    }
    
    // MARK: File
    
    /// Appends a file part to the form data.
    ///
    /// - Parameters:
    ///   - fieldName: The form field name the server expects for this file.
    ///   - fileName: The file name reported in the `Content-Disposition` header.
    ///   - mimeType: The MIME type reported in the `Content-Type` header for this part,
    ///     e.g. `"image/jpeg"`.
    ///   - data: The raw file bytes.
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
    
    /// Appends a plain text field part to the form data.
    ///
    /// - Parameters:
    ///   - name: The form field name.
    ///   - value: The field's string value.
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
    
    /// Returns the completed multipart body, including the closing boundary.
    ///
    /// Call this once all fields and files have been appended, to obtain the
    /// `Data` that should be assigned to `URLRequest.httpBody`.
    ///
    /// - Returns: The finalized multipart/form-data payload.
    public func finalizedData() -> Data {
        var result = body
        
        result.append(
            Data("--\(boundary)--\r\n".utf8)
        )
        
        return result
    }
    
    // MARK: Content Type
    
    /// The `Content-Type` header value for this multipart body, including its boundary.
    ///
    /// Assign this to the `Content-Type` header of the request that sends
    /// the result of ``finalizedData()``.
    public var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }
    
    // MARK: Private
    
    /// Appends the UTF-8 bytes of `string` to the accumulated body.
    ///
    /// - Parameter string: The string to append.
    private mutating func append(
        _ string: String
    ) {
        body.append(
            Data(string.utf8)
        )
    }
}
