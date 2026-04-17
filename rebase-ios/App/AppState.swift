import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var sessionStore: SessionStore
    let apiClient: APIClient

    init() {
        let sessionStore = SessionStore()
        self.sessionStore = sessionStore
        self.apiClient = APIClient(tokenStore: sessionStore)
    }
}
