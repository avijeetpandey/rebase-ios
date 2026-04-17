import Foundation
import UIKit

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var posts: [CommitPost] = []
    @Published var isLoading = false
    @Published var showComposer = false
    @Published var selectedPostForComments: CommitPost?

    let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func loadFeed() async {
        isLoading = true
        defer { isLoading = false }

        do {
            posts = try await apiClient.send(APIEndpoints.fetchFeed())
        } catch {
            posts = MockData.sampleCommits
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

        let haptics = UIImpactFeedbackGenerator(style: .light)
        haptics.impactOccurred()

        Task {
            do {
                _ = try await apiClient.send(APIEndpoints.toggleLGTM(postID: post.id)) as EmptyResponse
            } catch {
                await MainActor.run {
                    if let rollbackIndex = posts.firstIndex(where: { $0.id == post.id }) {
                        posts[rollbackIndex] = previous
                    }
                }
            }
        }
    }

    func prepend(post: CommitPost) {
        posts.insert(post, at: 0)
    }
}
