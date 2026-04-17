import XCTest
@testable import rebase_ios

/// Tests the 401 → refresh → retry flow and the failed-refresh → logout path.
final class AuthRefreshFlowTests: XCTestCase {

    private final class InMemoryTokenStore: TokenStore {
        var accessToken: String?
        var refreshToken: String?
        var clearCalled = false

        init(accessToken: String?, refreshToken: String?) {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
        }

        func save(tokens: TokenPair) {
            accessToken = tokens.accessToken
            refreshToken = tokens.refreshToken
        }

        func clear() {
            clearCalled = true
            accessToken = nil
            refreshToken = nil
        }
    }

    private struct SamplePayload: Codable, Equatable { let value: String }

    private func makeSession() -> URLSession {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: cfg)
    }

    private func wrappedJSON<T: Encodable>(_ payload: T, isError: Bool = false) throws -> Data {
        struct W<T: Encodable>: Encodable { let isError: Bool; let message: String; let data: T }
        return try JSONEncoder().encode(W(isError: isError, message: isError ? "error" : "ok", data: payload))
    }

    override func tearDown() {
        super.tearDown()
        MockURLProtocol.requestHandler = nil
    }

    // MARK: - 401 triggers single refresh and retries original request

    func test401TriggersRefreshAndSingleRetry() async throws {
        var primaryCount = 0

        MockURLProtocol.requestHandler = { [self] request in
            let path = request.url?.path ?? ""

            if path.hasSuffix("/api/v1/auth/refresh") {
                let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let auth = AuthResponse(accessToken: "fresh-token", refreshToken: "fresh-refresh", tokenType: nil, expiresIn: nil)
                return (resp, try wrappedJSON(auth))
            }

            if path.hasSuffix("/data") {
                primaryCount += 1
                if primaryCount == 1 {
                    let resp = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
                    return (resp, Data())
                }
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer fresh-token",
                               "Retry must use refreshed token")
                let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (resp, try wrappedJSON(SamplePayload(value: "success")))
            }

            XCTFail("Unexpected request: \(path)")
            throw APIError.invalidURL
        }

        let store = InMemoryTokenStore(accessToken: "expired", refreshToken: "valid-refresh")
        let client = APIClient(baseURL: URL(string: "http://localhost:9000")!,
                               tokenStore: store, urlSession: makeSession())

        let result: SamplePayload = try await client.send(APIRequest(path: "/data"))

        XCTAssertEqual(result.value, "success")
        XCTAssertEqual(primaryCount, 2, "Protected endpoint must be called exactly twice (original + retry)")
        XCTAssertEqual(store.accessToken, "fresh-token")
        XCTAssertEqual(store.refreshToken, "fresh-refresh")
    }

    // MARK: - Failed refresh clears session

    func testFailedRefreshClearsTokenStoreAndThrowsUnauthorized() async throws {
        MockURLProtocol.requestHandler = { request in
            // Everything returns 401 — simulates refresh failing too
            let resp = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (resp, Data())
        }

        let store = InMemoryTokenStore(accessToken: "expired", refreshToken: "expired-refresh")
        let client = APIClient(baseURL: URL(string: "http://localhost:9000")!,
                               tokenStore: store, urlSession: makeSession())

        do {
            let _: SamplePayload = try await client.send(APIRequest(path: "/protected"))
            XCTFail("Expected APIError.unauthorized")
        } catch APIError.unauthorized {
            XCTAssertNil(store.accessToken, "Access token must be cleared after failed refresh")
            XCTAssertNil(store.refreshToken, "Refresh token must be cleared after failed refresh")
        }
    }

    // MARK: - No token → not retried, just fails

    func testRequestWithNoTokenDoesNotTriggerRefresh() async throws {
        var refreshCalled = false

        MockURLProtocol.requestHandler = { request in
            if request.url?.path.hasSuffix("/api/v1/auth/refresh") == true {
                refreshCalled = true
            }
            let resp = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (resp, Data())
        }

        let store = InMemoryTokenStore(accessToken: nil, refreshToken: nil)
        let client = APIClient(baseURL: URL(string: "http://localhost:9000")!,
                               tokenStore: store, urlSession: makeSession())

        do {
            let _: SamplePayload = try await client.send(APIRequest(path: "/protected"))
            XCTFail("Expected error")
        } catch {
            XCTAssertFalse(refreshCalled, "Refresh must not be attempted when there is no refresh token")
        }
    }
}
