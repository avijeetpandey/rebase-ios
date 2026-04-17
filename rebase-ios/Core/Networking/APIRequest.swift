import Foundation

struct APIRequest<Response: Decodable> {
    let path: String
    var method: HTTPMethod = .get
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: AnyEncodable?
    var requiresAuth: Bool = true
}

struct AnyEncodable: Encodable {
    private let encoder: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        encoder = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try self.encoder(encoder)
    }
}
