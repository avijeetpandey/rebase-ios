import Foundation

@MainActor
final class SessionStore: ObservableObject, @preconcurrency TokenStore {
    @Published private(set) var accessToken: String?
    @Published private(set) var refreshToken: String?
    @Published var currentUser: User?

    var isAuthenticated: Bool {
        accessToken != nil && refreshToken != nil
    }

    private enum Keys {
        static let access = "rebase.jwt.access"
        static let refresh = "rebase.jwt.refresh"
    }

    init() {
        accessToken = KeychainService.read(key: Keys.access)
        refreshToken = KeychainService.read(key: Keys.refresh)
    }

    func save(tokens: TokenPair) {
        accessToken = tokens.accessToken
        refreshToken = tokens.refreshToken
        KeychainService.save(value: tokens.accessToken, key: Keys.access)
        KeychainService.save(value: tokens.refreshToken, key: Keys.refresh)
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
        currentUser = nil
        KeychainService.delete(key: Keys.access)
        KeychainService.delete(key: Keys.refresh)
    }
}
