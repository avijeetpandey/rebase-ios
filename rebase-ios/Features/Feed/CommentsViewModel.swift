import Foundation
import OSLog

private let commentsLogger = Logger(subsystem: "com.rebase.rebase-ios", category: "Comments")

@MainActor
final class CommentsViewModel: ObservableObject {
    @Published var comments: [CommentModel] = []
    @Published var input = ""
    @Published var isSending = false
    @Published var errorMessage: String?

    private let apiClient: APIClient
    private let post: CommitPost
    private let onCommentAdded: (() -> Void)?

    init(apiClient: APIClient, post: CommitPost, onCommentAdded: (() -> Void)? = nil) {
        self.apiClient = apiClient
        self.post = post
        self.onCommentAdded = onCommentAdded
    }

    func load() async {
        errorMessage = nil
        commentsLogger.debug("Loading comments for post: \(self.post.id)")
        do {
            let page = try await apiClient.send(APIEndpoints.fetchComments(postID: self.post.id))
            comments = page.content
            commentsLogger.info("Loaded \(self.comments.count) comments")
        } catch {
            commentsLogger.error("Failed to load comments: \(error.localizedDescription)")
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load comments."
        }
    }

    func sendComment() async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true
        defer { isSending = false }
        commentsLogger.debug("Sending comment on post: \(self.post.id)")

        do {
            let comment = try await apiClient.send(APIEndpoints.createComment(postID: self.post.id, text: trimmed))
            self.comments.insert(comment, at: 0)
            input = ""
            onCommentAdded?()
            commentsLogger.info("Comment sent: \(comment.id)")
        } catch {
            commentsLogger.error("Send comment failed: \(error.localizedDescription)")
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to send comment."
        }
    }
}
