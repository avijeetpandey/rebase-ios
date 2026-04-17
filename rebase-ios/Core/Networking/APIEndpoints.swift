import Foundation

enum APIEndpoints {
    static func login(username: String, password: String) -> APIRequest<APIEnvelope<TokenPair>> {
        struct Body: Codable {
            let username: String
            let password: String
        }

        return APIRequest(
            path: "/api/v1/auth/login",
            method: .post,
            body: AnyEncodable(Body(username: username, password: password)),
            requiresAuth: false
        )
    }

    static func signup(username: String, email: String, password: String) -> APIRequest<EmptyResponse> {
        struct Body: Codable {
            let username: String
            let email: String
            let password: String
        }

        return APIRequest(
            path: "/api/v1/auth/register",
            method: .post,
            body: AnyEncodable(Body(username: username, email: email, password: password)),
            requiresAuth: false
        )
    }

    static func me() -> APIRequest<APIEnvelope<User>> {
        APIRequest(path: "/api/v1/auth/me")
    }

    static func logout() -> APIRequest<EmptyResponse> {
        APIRequest(path: "/api/v1/auth/logout", method: .post)
    }

    static func fetchFeed() -> APIRequest<[CommitPost]> {
        APIRequest(path: "/commits")
    }

    static func fetchProfile() -> APIRequest<User> {
        APIRequest(path: "/users/me")
    }

    static func fetchRecentCommits() -> APIRequest<[CommitPost]> {
        APIRequest(path: "/users/me/commits")
    }

    static func toggleLGTM(postID: String) -> APIRequest<EmptyResponse> {
        APIRequest(path: "/commits/\(postID)/lgtm", method: .post)
    }

    static func fetchComments(postID: String) -> APIRequest<[CommentModel]> {
        APIRequest(path: "/commits/\(postID)/comments")
    }

    static func createComment(postID: String, text: String) -> APIRequest<CommentModel> {
        struct Body: Codable {
            let text: String
        }

        return APIRequest(
            path: "/commits/\(postID)/comments",
            method: .post,
            body: AnyEncodable(Body(text: text))
        )
    }

    static func requestPresignedUpload(fileName: String, mimeType: String) -> APIRequest<PresignedUploadResponse> {
        struct Body: Codable {
            let fileName: String
            let mimeType: String
        }

        return APIRequest(
            path: "/uploads/presigned-url",
            method: .post,
            body: AnyEncodable(Body(fileName: fileName, mimeType: mimeType))
        )
    }

    static func createCommit(message: String, imageURL: URL?, codeSnippet: CodeSnippet?) -> APIRequest<CommitPost> {
        struct Body: Codable {
            let message: String
            let imageURL: URL?
            let codeSnippet: CodeSnippet?
        }

        return APIRequest(
            path: "/commits",
            method: .post,
            body: AnyEncodable(Body(message: message, imageURL: imageURL, codeSnippet: codeSnippet))
        )
    }
}
