import Foundation

enum MockData {
    static let sampleUser = User(
        id: "u1",
        username: "octocat",
        email: nil,
        bio: "Shipping clean diffs, one commit at a time.",
        avatarUrl: "https://avatars.githubusercontent.com/u/583231?v=4"
    )

    static let sampleCommits: [CommitPost] = [
        CommitPost(
            id: "c1",
            author: sampleUser,
            content: "Refactored auth interceptor to make token refresh race-safe.",
            imageUrl: nil,
            codeSnippet: "guard response.statusCode == 401 else {\n    return data\n}\nlet refreshed = try await refreshAccessToken()\nreturn try await retryOriginalRequest(refreshed: refreshed)",
            language: "swift",
            createdAt: Date().addingTimeInterval(-3600),
            lgtmCount: 42,
            commentCount: 7,
            likedByCurrentUser: false
        ),
        CommitPost(
            id: "c2",
            author: User(
                id: "u2",
                username: "kernelpanic",
                email: nil,
                bio: nil,
                avatarUrl: "https://avatars.githubusercontent.com/u/19864447?v=4"
            ),
            content: "Benchmarked image loading path and removed UI hitching in feed cells.",
            imageUrl: "https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=1200",
            codeSnippet: nil,
            language: nil,
            createdAt: Date().addingTimeInterval(-7200),
            lgtmCount: 18,
            commentCount: 3,
            likedByCurrentUser: true
        )
    ]
}
