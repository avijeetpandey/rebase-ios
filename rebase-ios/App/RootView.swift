import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        RootContentView(sessionStore: appState.sessionStore, apiClient: appState.apiClient)
        .task {
            await appState.restoreSessionIfNeeded()
        }
        .preferredColorScheme(.dark)
        .background(Color.ghBackground.ignoresSafeArea())
    }
}

private struct RootContentView: View {
    @ObservedObject var sessionStore: SessionStore
    let apiClient: APIClient

    var body: some View {
        Group {
            if sessionStore.isAuthenticated {
                MainTabView(apiClient: apiClient, sessionStore: sessionStore)
            } else {
                AuthContainerView()
            }
        }
    }
}
