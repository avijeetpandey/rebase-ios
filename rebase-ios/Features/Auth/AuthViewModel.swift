import Foundation
import OSLog

private let authLogger = Logger(subsystem: "com.rebase.rebase-ios", category: "Auth")

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
                authLogger.debug("Login attempt for: \(self.username)")
                let authResponse: AuthResponse = try await apiClient.send(
                    APIEndpoints.login(username: self.username, password: password)
                )
                tokens = TokenPair(from: authResponse)

            case .signup:
                authLogger.debug("Register attempt for: \(self.username)")
                _ = try await apiClient.send(
                    APIEndpoints.register(username: self.username, email: self.email, password: self.password)
                ) as EmptyResponse
                let authResponse: AuthResponse = try await apiClient.send(
                    APIEndpoints.login(username: self.username, password: self.password)
                )
                tokens = TokenPair(from: authResponse)
            }

            sessionStore.save(tokens: tokens)

            let user: User = try await apiClient.send(APIEndpoints.me())
            sessionStore.currentUser = user
            authLogger.info("Auth succeeded for: \(user.username)")
        } catch {
            authLogger.error("Auth failed: \(error.localizedDescription)")
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Unable to authenticate."
        }
    }
}
