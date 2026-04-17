import Foundation

/// Builds a `multipart/form-data` body compatible with the Spring Boot backend.
///
/// The backend expects two parts:
/// - `request` — JSON-encoded `CreatePostRequest`
/// - `image`   — optional image file (JPEG)
struct MultipartFormDataBuilder {
    let boundary: String

    init(boundary: String = "Boundary-\(UUID().uuidString)") {
        self.boundary = boundary
    }

    /// Content-Type header value to set on the request.
    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    /// Assembles the complete multipart body.
    func build(requestJSON: Data, imageData: Data? = nil, imageMimeType: String = "image/jpeg") -> Data {
        var body = Data()

        // ── JSON `request` part ──────────────────────────────────────
        body.appendLine("--\(boundary)")
        body.appendLine("Content-Disposition: form-data; name=\"request\"")
        body.appendLine("Content-Type: application/json")
        body.appendLine("")
        body.append(requestJSON)
        body.appendLine("")

        // ── Optional image part ──────────────────────────────────────
        if let imageData {
            body.appendLine("--\(boundary)")
            body.appendLine("Content-Disposition: form-data; name=\"image\"; filename=\"upload.jpg\"")
            body.appendLine("Content-Type: \(imageMimeType)")
            body.appendLine("")
            body.append(imageData)
            body.appendLine("")
        }

        // ── Closing boundary ─────────────────────────────────────────
        body.appendLine("--\(boundary)--")

        return body
    }
}

private extension Data {
    mutating func appendLine(_ string: String) {
        if let data = "\(string)\r\n".data(using: .utf8) {
            append(data)
        }
    }
}
