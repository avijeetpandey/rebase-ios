import Foundation

enum APIError: LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case unauthorized
    case server(statusCode: Int, message: String?)
    case decoding
    case network

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .invalidResponse:
            return "Invalid server response."
        case .unauthorized:
            return "Session expired. Please sign in again."
        case .server(let statusCode, let message):
            if let message,
               message.localizedCaseInsensitiveContains("maximum upload size exceeded") {
                return "Image is too large. Please upload an image under 1 MB."
            }
            if statusCode == 413 {
                return "Image is too large. Please upload an image under 1 MB."
            }
            if let message, !message.isEmpty {
                return "Server error (\(statusCode)): \(message)"
            }
            return "Server error (\(statusCode))."
        case .decoding:
            return "Unable to parse server response."
        case .network:
            return "Network request failed."
        }
    }
}
