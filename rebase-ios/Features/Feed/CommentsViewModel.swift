import Foundation

@MainActor
final class CommentsViewModel: ObservableObject {
    @Published var comments: [CommentModel] = []
    @Published var input = ""
    @Published var isSending = false

    private let apiClient: APIClient
    private let post: CommitPost

    init(apiClient: APIClient, post: CommitPost) {
        self.apiClient = apiClient
        self.post = post
    }

    func load() async {
        do {
            comments = try await apiClient.send(APIEndpoints.fetchComments(postID: post.id))
        } catch {
            comments = []
        }
    }

    func sendComment() async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true
        defer { isSending = false }

        do {
            let comment = try await apiClient.send(APIEndpoints.createComment(postID: post.id, text: trimmed))
            comments.append(comment)
            input = ""
        } catch {
            // No-op. Add alert/banner if needed.
        }
    }
}
