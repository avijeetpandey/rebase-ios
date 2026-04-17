import XCTest
@testable import rebase_ios

final class APIClientTests: XCTestCase {

    // MARK: - Helpers

    private final class InMemoryTokenStore: TokenStore {
        var accessToken: String?
        var refreshToken: String?

        init(accessToken: String?, refreshToken: String?) {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
        }

        func save(tokens: TokenPair) {
            accessToken = tokens.accessToken
            refreshToken = tokens.refreshToken
        }

        func clear() {
            accessToken = nil
            refreshToken = nil
        }
    }

    private struct SamplePayload: Codable, Equatable {
        let value: String
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    private func wrapped<T: Encodable>(_ payload: T, isError: Bool = false, message: String = "ok") throws -> Data {
        struct Wrapper<T: Encodable>: Encodable {
            let isError: Bool
            let message: String
            let data: T
        }
        return try JSONEncoder().encode(Wrapper(isError: isError, message: message, data: payload))
    }

    override func tearDown() {
        super.tearDown()
        MockURLProtocol.requestHandler = nil
    }

    // MARK: - Tests

    func testSendDecodesWrappedPayload() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/test")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = try self.wrapped(SamplePayload(value: "ok"))
            return (response, data)
        }

        let client = APIClient(
            baseURL: URL(string: "http://localhost:9000")!,
            tokenStore: InMemoryTokenStore(accessToken: "token", refreshToken: "refresh"),
            urlSession: makeSession()
        )

        let result: SamplePayload = try await client.send(APIRequest(path: "/test"))
        XCTAssertEqual(result, SamplePayload(value: "ok"))
    }

    func testIsErrorTrueThrowsServerError() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil)!
            struct ErrPayload: Encodable { let message: String; let details: String?; let timestamp: String? }
            let data = try self.wrapped(ErrPayload(message: "Bad input", details: nil, timestamp: nil), isError: true, message: "error")
            return (response, data)
        }

        let client = APIClient(
            baseURL: URL(string: "http://localhost:9000")!,
            tokenStore: InMemoryTokenStore(accessToken: "token", refreshToken: "refresh"),
            urlSession: makeSession()
        )

        do {
            let _: SamplePayload = try await client.send(APIRequest(path: "/bad", requiresAuth: false))
            XCTFail("Expected error")
        } catch APIError.server(let code, let msg) {
            XCTAssertEqual(code, 400)
            XCTAssertEqual(msg, "Bad input")
        }
    }

    func test401TriggersRefreshAndRetry() async throws {
        var primaryCallCount = 0

        MockURLProtocol.requestHandler = { request in
            let path = request.url?.path

            if path == "/api/v1/auth/refresh" {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let authResp = AuthResponse(accessToken: "new-access", refreshToken: "new-refresh",
                                            tokenType: "Bearer", expiresIn: 3600)
                let data = try self.wrapped(authResp)
                return (response, data)
            }

            if path == "/protected" {
                primaryCallCount += 1
                if primaryCallCount == 1 {
                    let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
                    return (response, Data())
                }
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer new-access")
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let data = try self.wrapped(SamplePayload(value: "retried"))
                return (response, data)
            }

            XCTFail("Unexpected path: \(path ?? "nil")")
            throw APIError.invalidURL
        }

        let tokenStore = InMemoryTokenStore(accessToken: "expired", refreshToken: "refresh")
        let client = APIClient(
            baseURL: URL(string: "http://localhost:9000")!,
            tokenStore: tokenStore,
            urlSession: makeSession()
        )

        let result: SamplePayload = try await client.send(APIRequest(path: "/protected"))

        XCTAssertEqual(result, SamplePayload(value: "retried"))
        XCTAssertEqual(tokenStore.accessToken, "new-access")
        XCTAssertEqual(tokenStore.refreshToken, "new-refresh")
    }

    func testFailedRefreshClearsSession() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let tokenStore = InMemoryTokenStore(accessToken: "expired", refreshToken: "bad-refresh")
        let client = APIClient(
            baseURL: URL(string: "http://localhost:9000")!,
            tokenStore: tokenStore,
            urlSession: makeSession()
        )

        do {
            let _: SamplePayload = try await client.send(APIRequest(path: "/protected"))
            XCTFail("Expected unauthorized error")
        } catch APIError.unauthorized {
            XCTAssertNil(tokenStore.accessToken)
            XCTAssertNil(tokenStore.refreshToken)
        }
    }
}
