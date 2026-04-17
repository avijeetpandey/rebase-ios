import XCTest
@testable import rebase_ios

final class APIClientTests: XCTestCase {
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

    override func tearDown() {
        super.tearDown()
        MockURLProtocol.requestHandler = nil
    }

    func testSendDecodesPayload() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/test")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = try JSONEncoder().encode(SamplePayload(value: "ok"))
            return (response, data)
        }

        let tokenStore = InMemoryTokenStore(accessToken: "token", refreshToken: "refresh")
        let client = APIClient(baseURL: URL(string: "http://localhost:8080")!, tokenStore: tokenStore, urlSession: session)

        let response: SamplePayload = try await client.send(APIRequest(path: "/test"))
        XCTAssertEqual(response, SamplePayload(value: "ok"))
    }

    func test401TriggersRefreshAndRetry() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        var primaryCallCount = 0

        MockURLProtocol.requestHandler = { request in
            let path = request.url?.path

            if path == "/api/v1/auth/refresh" {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let data = try JSONEncoder().encode(
                    APIEnvelope(data: TokenPair(accessToken: "new-access", refreshToken: "new-refresh"))
                )
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
                let data = try JSONEncoder().encode(SamplePayload(value: "retried"))
                return (response, data)
            }

            XCTFail("Unexpected path: \(path ?? "nil")")
            throw APIError.invalidURL
        }

        let tokenStore = InMemoryTokenStore(accessToken: "expired", refreshToken: "refresh")
        let client = APIClient(baseURL: URL(string: "http://localhost:8080")!, tokenStore: tokenStore, urlSession: session)

        let response: SamplePayload = try await client.send(APIRequest(path: "/protected"))

        XCTAssertEqual(response, SamplePayload(value: "retried"))
        XCTAssertEqual(tokenStore.accessToken, "new-access")
        XCTAssertEqual(tokenStore.refreshToken, "new-refresh")
    }
}
