import Foundation

struct PostService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func getFeed(page: Int = 0, size: Int = 20) async throws -> PageResponse<CommitPost> {
        try await client.send(APIEndpoints.fetchFeed(page: page, size: size))
    }

    func createPost(
        content: String,
        codeSnippet: String? = nil,
        language: String? = nil,
        imageData: Data? = nil
    ) async throws -> CommitPost {
        let endpoint = try APIEndpoints.createPost(
            content: content,
            codeSnippet: codeSnippet,
            language: language,
            imageData: imageData
        )
        return try await client.send(endpoint)
    }
}
