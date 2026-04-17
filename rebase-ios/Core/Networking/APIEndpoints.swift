import Foundation

enum APIEndpoints {
    static func login(username: String, password: String) -> APIRequest<AuthResponse> {
        APIRequest(
            path: "/api/v1/auth/login",
            method: .post,
            body: AnyEncodable(LoginRequest(username: username, password: password)),
            requiresAuth: false
        )
    }

    static func register(username: String, email: String, password: String) -> APIRequest<EmptyResponse> {
        APIRequest(
            path: "/api/v1/auth/register",
            method: .post,
            body: AnyEncodable(RegisterRequest(username: username, email: email, password: password)),
            requiresAuth: false
        )
    }

    static func refresh(refreshToken: String) -> APIRequest<AuthResponse> {
        APIRequest(
            path: "/api/v1/auth/refresh",
            method: .post,
            body: AnyEncodable(RefreshTokenRequest(refreshToken: refreshToken)),
            requiresAuth: false
        )
    }

    static func me() -> APIRequest<User> {
        APIRequest(path: "/api/v1/auth/me")
    }

    static func profile(userID: String) -> APIRequest<User> {
        APIRequest(path: "/api/v1/profiles/\(userID)")
    }

    static func logout() -> APIRequest<EmptyResponse> {
        APIRequest(path: "/api/v1/auth/logout", method: .post)
    }

    static func fetchFeed(page: Int = 0, size: Int = 20) -> APIRequest<PageResponse<CommitPost>> {
        var req = APIRequest<PageResponse<CommitPost>>(path: "/api/v1/posts")
        req.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "size", value: "\(size)")
        ]
        return req
    }

    static func createPost(
        content: String,
        codeSnippet: String? = nil,
        language: String? = nil,
        imageData: Data? = nil
    ) throws -> APIRequest<CommitPost> {
        let requestPart = CreatePostRequest(content: content, codeSnippet: codeSnippet, language: language)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let jsonData = try encoder.encode(requestPart)

        let builder = MultipartFormDataBuilder()
        let multipartData = builder.build(requestJSON: jsonData, imageData: imageData)

        var req = APIRequest<CommitPost>(path: "/api/v1/posts", method: .post)
        req.requestBody = .multipart(data: multipartData, contentType: builder.contentType)
        return req
    }

    static func fetchComments(postID: String, page: Int = 0, size: Int = 20) -> APIRequest<PageResponse<CommentModel>> {
        var req = APIRequest<PageResponse<CommentModel>>(path: "/api/v1/posts/\(postID)/comments")
        req.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "size", value: "\(size)")
        ]
        return req
    }

    static func createComment(postID: String, text: String) -> APIRequest<CommentModel> {
        struct Body: Encodable { let content: String }
        return APIRequest(
            path: "/api/v1/posts/\(postID)/comments",
            method: .post,
            body: AnyEncodable(Body(content: text))
        )
    }

    static func toggleLGTM(postID: String) -> APIRequest<LGTMResponse> {
        APIRequest(path: "/api/v1/posts/\(postID)/lgtm", method: .post)
    }

    static func signup(username: String, email: String, password: String) -> APIRequest<EmptyResponse> {
        register(username: username, email: email, password: password)
    }
}
