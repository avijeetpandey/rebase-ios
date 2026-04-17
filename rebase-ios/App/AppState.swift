import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var sessionStore: SessionStore
    let apiClient: APIClient
    private var cancellables = Set<AnyCancellable>()

    init() {
        let sessionStore = SessionStore()
        self.sessionStore = sessionStore
        self.apiClient = APIClient(tokenStore: sessionStore)

        sessionStore.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func restoreSessionIfNeeded() async {
        guard sessionStore.isAuthenticated, sessionStore.currentUser == nil else { return }

        do {
            let user: User = try await apiClient.send(APIEndpoints.me())
            sessionStore.currentUser = user
        } catch {
            sessionStore.clear()
        }
    }
}
