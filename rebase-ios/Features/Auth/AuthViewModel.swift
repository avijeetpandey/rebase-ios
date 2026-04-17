import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    enum Mode {
        case login
        case signup
    }

    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let mode: Mode
    private let apiClient: APIClient
    private let sessionStore: SessionStore

    init(mode: Mode, apiClient: APIClient, sessionStore: SessionStore) {
        self.mode = mode
        self.apiClient = apiClient
        self.sessionStore = sessionStore
    }

    func submit() async {
        errorMessage = nil

        guard !password.isEmpty else {
            errorMessage = "Please fill in all required fields."
            return
        }

        if mode == .login {
            guard !username.isEmpty else {
                errorMessage = "Username is required."
                return
            }
        } else {
            guard !username.isEmpty, !email.isEmpty else {
                errorMessage = "Please fill in all required fields."
                return
            }
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let tokens: TokenPair
            switch mode {
            case .login:
                let loginEnvelope: APIEnvelope<TokenPair> = try await apiClient.send(
                    APIEndpoints.login(username: username, password: password)
                )
                tokens = loginEnvelope.data
            case .signup:
                _ = try await apiClient.send(APIEndpoints.signup(username: username, email: email, password: password)) as EmptyResponse
                let loginEnvelope: APIEnvelope<TokenPair> = try await apiClient.send(
                    APIEndpoints.login(username: username, password: password)
                )
                tokens = loginEnvelope.data
            }

            sessionStore.save(tokens: tokens)

            let meEnvelope: APIEnvelope<User> = try await apiClient.send(APIEndpoints.me())
            sessionStore.currentUser = meEnvelope.data
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Unable to authenticate."
        }
    }
}
