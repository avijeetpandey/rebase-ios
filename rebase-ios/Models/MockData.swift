import Foundation

enum MockData {
    static let sampleUser = User(
        id: "u1",
        username: "octocat",
        bio: "Shipping clean diffs, one commit at a time.",
        avatarURL: URL(string: "https://avatars.githubusercontent.com/u/583231?v=4")
    )

    static let sampleCommits: [CommitPost] = [
        CommitPost(
            id: "c1",
            author: sampleUser,
            message: "Refactored auth interceptor to make token refresh race-safe.",
            imageURL: nil,
            codeSnippet: CodeSnippet(
                language: "swift",
                code: "guard response.statusCode == 401 else {\n    return data\n}\nlet refreshed = try await refreshAccessToken()\nreturn try await retryOriginalRequest(refreshed: refreshed)"
            ),
            createdAt: Date().addingTimeInterval(-3600),
            lgtmCount: 42,
            commentCount: 7,
            isLGTMd: false
        ),
        CommitPost(
            id: "c2",
            author: User(
                id: "u2",
                username: "kernelpanic",
                bio: nil,
                avatarURL: URL(string: "https://avatars.githubusercontent.com/u/19864447?v=4")
            ),
            message: "Benchmarked image loading path and removed UI hitching in feed cells.",
            imageURL: URL(string: "https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=1200"),
            codeSnippet: nil,
            createdAt: Date().addingTimeInterval(-7200),
            lgtmCount: 18,
            commentCount: 3,
            isLGTMd: true
        )
    ]
}
