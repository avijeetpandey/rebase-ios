import Foundation

struct ApiResponse<T: Decodable>: Decodable {
    let isError: Bool
    let message: String
    let data: T?
}

struct ResponseEnvelope: Decodable {
    let isError: Bool
    let message: String
}

struct ErrorPayload: Decodable {
    let message: String
    let details: String?
    let timestamp: String?
}
