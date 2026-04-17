import Foundation
import OSLog

private let profileLogger = Logger(subsystem: "com.rebase.rebase-ios", category: "Profile")

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var commits: [CommitPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient: APIClient
    private let sessionStore: SessionStore

    init(apiClient: APIClient, sessionStore: SessionStore) {
        self.apiClient = apiClient
        self.sessionStore = sessionStore
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        profileLogger.debug("Loading profile")

        do {
            let currentUserID: String
            if let existingUser = sessionStore.currentUser {
                currentUserID = existingUser.id
            } else {
                let me: User = try await apiClient.send(APIEndpoints.me())
                sessionStore.currentUser = me
                currentUserID = me.id
            }

            let profile: User = try await apiClient.send(APIEndpoints.profile(userID: currentUserID))
            user = profile
            sessionStore.currentUser = profile
            profileLogger.info("Profile loaded for user: \(profile.username)")

            let page = try await apiClient.send(APIEndpoints.fetchFeed(page: 0, size: 20))
            commits = page.content.filter { $0.author.id == currentUserID }
        } catch {
            profileLogger.error("Profile load failed: \(error.localizedDescription)")
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load profile."
        }
    }
}
