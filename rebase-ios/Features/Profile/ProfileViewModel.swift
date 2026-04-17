import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var commits: [CommitPost] = []

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func load() async {
        do {
            async let me = apiClient.send(APIEndpoints.fetchProfile())
            async let recent = apiClient.send(APIEndpoints.fetchRecentCommits())
            user = try await me
            commits = try await recent
        } catch {
            user = MockData.sampleUser
            commits = MockData.sampleCommits
        }
    }
}
