import Foundation

struct AuthService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func login(username: String, password: String) async throws -> AuthResponse {
        try await client.send(APIEndpoints.login(username: username, password: password))
    }

    func register(username: String, email: String, password: String) async throws {
        _ = try await client.send(
            APIEndpoints.register(username: username, email: email, password: password)
        ) as EmptyResponse
    }

    func me() async throws -> User {
        try await client.send(APIEndpoints.me())
    }

    func logout() async throws {
        _ = try await client.send(APIEndpoints.logout()) as EmptyResponse
    }

    func refresh(refreshToken: String) async throws -> AuthResponse {
        try await client.send(APIEndpoints.refresh(refreshToken: refreshToken))
    }
}
