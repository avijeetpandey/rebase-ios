import Foundation
import OSLog
import UIKit

private let feedLogger = Logger(subsystem: "com.rebase.rebase-ios", category: "Feed")

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var posts: [CommitPost] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMore = true
    @Published var errorMessage: String?
    @Published var showComposer = false
    @Published var selectedPostForComments: CommitPost?

    private var currentPage = 0
    private let pageSize = 20
    let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func loadFeed() async {
        currentPage = 0
        hasMore = true
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        feedLogger.debug("Loading feed page 0")

        do {
            let page = try await apiClient.send(APIEndpoints.fetchFeed(page: 0, size: pageSize))
            posts = page.content
            hasMore = !page.last
            currentPage = 1
            feedLogger.info("Feed loaded: \(page.content.count) posts")
        } catch {
            feedLogger.error("Feed load failed: \(error.localizedDescription)")
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load feed."
        }
    }

    func loadMore() async {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        feedLogger.debug("Loading feed page \(self.currentPage)")

        do {
            let page = try await apiClient.send(APIEndpoints.fetchFeed(page: self.currentPage, size: pageSize))
            posts.append(contentsOf: page.content)
            hasMore = !page.last
            self.currentPage += 1
            feedLogger.debug("Appended \(page.content.count) more posts")
        } catch {
            feedLogger.warning("Load more failed: \(error.localizedDescription)")
        }
    }

    func refresh() async {
        await loadFeed()
    }

    func optimisticToggleLGTM(post: CommitPost) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        let previous = posts[index]

        posts[index].isLGTMd.toggle()
        posts[index].lgtmCount += posts[index].isLGTMd ? 1 : -1

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        Task {
            do {
                let result = try await apiClient.send(APIEndpoints.toggleLGTM(postID: post.id))
                await MainActor.run {
                    if let updatedIndex = posts.firstIndex(where: { $0.id == post.id }) {
                        posts[updatedIndex].likedByCurrentUser = result.lgtmed
                        posts[updatedIndex].lgtmCount = result.lgtmCount
                    }
                }
            } catch {
                await MainActor.run {
                    if let rollbackIndex = posts.firstIndex(where: { $0.id == post.id }) {
                        posts[rollbackIndex] = previous
                    }
                }
            }
        }
    }

    func incrementCommentCount(for postID: String) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index].commentCount += 1
    }

    func prepend(post: CommitPost) {
        posts.insert(post, at: 0)
    }
}
