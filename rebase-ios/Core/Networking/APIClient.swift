import Foundation

actor RefreshCoordinator {
    private var refreshTask: Task<TokenPair, Error>?

    func token(using operation: @escaping () async throws -> TokenPair) async throws -> TokenPair {
        if let refreshTask {
            return try await refreshTask.value
        }

        let task = Task { try await operation() }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }
}

final class APIClient {
    private let baseURL: URL
    private weak var tokenStore: TokenStore?
    private let urlSession: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let refreshCoordinator = RefreshCoordinator()

    init(
        baseURL: URL = AppConfig.baseURL,
        tokenStore: TokenStore,
        urlSession: URLSession = .shared,
        decoder: JSONDecoder = .init(),
        encoder: JSONEncoder = .init()
    ) {
        self.baseURL = baseURL
        self.tokenStore = tokenStore
        self.urlSession = urlSession

        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        self.decoder = decoder
        self.encoder = encoder
    }

    func send<Response: Decodable>(_ request: APIRequest<Response>) async throws -> Response {
        var urlRequest = try makeURLRequest(from: request)
        let (data, response) = try await perform(urlRequest)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if http.statusCode == 401 && request.requiresAuth {
            try await refreshTokens()
            urlRequest = try makeURLRequest(from: request)
            let (retryData, retryResponse) = try await perform(urlRequest)
            guard let retryHTTP = retryResponse as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            return try decodeResponse(retryData, statusCode: retryHTTP.statusCode)
        }

        return try decodeResponse(data, statusCode: http.statusCode)
    }

    func upload(data: Data, to signedURL: URL, mimeType: String) async throws {
        var request = URLRequest(url: signedURL)
        request.httpMethod = HTTPMethod.put.rawValue
        request.setValue(mimeType, forHTTPHeaderField: "Content-Type")

        let (_, response) = try await urlSession.upload(for: request, from: data)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.server(statusCode: http.statusCode, message: nil)
        }
    }

    private func makeURLRequest<Response: Decodable>(from request: APIRequest<Response>) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(request.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }

        if !request.queryItems.isEmpty {
            components.queryItems = request.queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = request.body {
            urlRequest.httpBody = try encoder.encode(body)
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if request.requiresAuth, let token = tokenStore?.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        return urlRequest
    }

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await urlSession.data(for: request)
        } catch {
            throw APIError.network
        }
    }

    private func decodeResponse<Response: Decodable>(_ data: Data, statusCode: Int) throws -> Response {
        guard (200...299).contains(statusCode) else {
            if statusCode == 401 {
                throw APIError.unauthorized
            }
            let message = String(data: data, encoding: .utf8)
            throw APIError.server(statusCode: statusCode, message: message)
        }

        if Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    private func refreshTokens() async throws {
        guard let tokenStore else { throw APIError.unauthorized }
        guard let refresh = tokenStore.refreshToken else {
            tokenStore.clear()
            throw APIError.unauthorized
        }

        struct RefreshBody: Codable {
            let refreshToken: String
        }

        let tokens = try await refreshCoordinator.token {
            let request = APIRequest<APIEnvelope<TokenPair>>(
                path: "/api/v1/auth/refresh",
                method: .post,
                body: AnyEncodable(RefreshBody(refreshToken: refresh)),
                requiresAuth: false
            )

            let urlRequest = try self.makeURLRequest(from: request)
            let (data, response) = try await self.perform(urlRequest)

            guard let http = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            let envelope: APIEnvelope<TokenPair> = try self.decodeResponse(data, statusCode: http.statusCode)
            return envelope.data
        }

        await MainActor.run {
            tokenStore.save(tokens: tokens)
        }
    }
}
