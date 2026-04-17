import Foundation
import OSLog

private let networkLogger = Logger(subsystem: "com.rebase.rebase-ios", category: "Networking")

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
        networkLogger.debug("→ \(request.method.rawValue) \(request.path)")
        let (data, response) = try await perform(urlRequest)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        networkLogger.debug("← \(http.statusCode) \(request.path)")

        if http.statusCode == 401, request.requiresAuth {
            do {
                try await refreshTokens()
            } catch {
                networkLogger.warning("Token refresh failed, clearing session")
                await MainActor.run { tokenStore?.clear() }
                throw APIError.unauthorized
            }
            urlRequest = try makeURLRequest(from: request)
            let (retryData, retryResponse) = try await perform(urlRequest)
            guard let retryHTTP = retryResponse as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            networkLogger.debug("← retry \(retryHTTP.statusCode) \(request.path)")
            return try decodeResponse(retryData, statusCode: retryHTTP.statusCode)
        }

        return try decodeResponse(data, statusCode: http.statusCode)
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

        guard let url = components.url else { throw APIError.invalidURL }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        switch request.requestBody {
        case .json(let encodable):
            urlRequest.httpBody = try encoder.encode(encodable)
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        case .multipart(let data, let contentType):
            urlRequest.httpBody = data
            urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        case nil:
            break
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
            networkLogger.error("Network error: \(error.localizedDescription)")
            throw APIError.network
        }
    }

    private func decodeResponse<Response: Decodable>(_ data: Data, statusCode: Int) throws -> Response {
        if let envelope = try? decoder.decode(ResponseEnvelope.self, from: data), envelope.isError {
            let message: String?
            if let errResp = try? decoder.decode(ApiResponse<ErrorPayload>.self, from: data) {
                message = errResp.data?.message ?? (envelope.message.isEmpty ? nil : envelope.message)
            } else {
                message = envelope.message.isEmpty ? nil : envelope.message
            }
            networkLogger.warning("Server error \(statusCode): \(message ?? "(no message)")")
            throw APIError.server(statusCode: statusCode, message: message)
        }

        guard (200...299).contains(statusCode) else {
            let message = String(data: data, encoding: .utf8)
            if statusCode == 401 { throw APIError.unauthorized }
            networkLogger.warning("HTTP \(statusCode): \(message ?? "")")
            throw APIError.server(statusCode: statusCode, message: message)
        }

        if Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }

        // Try direct decode first (flat response), then envelope-wrapped.
        if let direct = try? decoder.decode(Response.self, from: data) {
            return direct
        }

        do {
            let apiResp = try decoder.decode(ApiResponse<Response>.self, from: data)
            if let result = apiResp.data { return result }
            throw APIError.decoding
        } catch let err as APIError {
            throw err
        } catch {
            networkLogger.error("Decode error: \(error)")
            throw APIError.decoding
        }
    }

    private func refreshTokens() async throws {
        guard let tokenStore else { throw APIError.unauthorized }
        guard let refreshToken = tokenStore.refreshToken else {
            await MainActor.run { tokenStore.clear() }
            throw APIError.unauthorized
        }

        struct RefreshBody: Encodable { let refreshToken: String }

        networkLogger.info("Token refresh initiated")
        let newPair = try await refreshCoordinator.token {
            let req = APIRequest<AuthResponse>(
                path: "/api/v1/auth/refresh",
                method: .post,
                body: AnyEncodable(RefreshBody(refreshToken: refreshToken)),
                requiresAuth: false
            )
            let urlRequest = try self.makeURLRequest(from: req)
            let (data, response) = try await self.perform(urlRequest)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
            let authResp: AuthResponse = try self.decodeResponse(data, statusCode: http.statusCode)
            return TokenPair(from: authResp)
        }

        networkLogger.info("Token refresh succeeded")
        await MainActor.run { tokenStore.save(tokens: newPair) }
    }
}
