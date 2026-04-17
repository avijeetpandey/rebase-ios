import Foundation

enum RequestBody {
    case json(AnyEncodable)
    case multipart(data: Data, contentType: String)
}

struct APIRequest<Response: Decodable> {
    let path: String
    var method: HTTPMethod = .get
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: AnyEncodable? {
        get {
            if case .json(let enc) = requestBody { return enc }
            return nil
        }
        set {
            if let enc = newValue { requestBody = .json(enc) }
            else { requestBody = nil }
        }
    }
    var requestBody: RequestBody?
    var requiresAuth: Bool = true

    init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: AnyEncodable? = nil,
        requiresAuth: Bool = true
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.requestBody = body.map { .json($0) }
        self.requiresAuth = requiresAuth
    }
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
