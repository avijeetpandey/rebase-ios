import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            FeedView(
                viewModel: FeedViewModel(apiClient: appState.apiClient)
            )
            .tabItem {
                Label("Feed", systemImage: "list.bullet.rectangle")
            }

            ProfileView(
                viewModel: ProfileViewModel(apiClient: appState.apiClient),
                onLogout: {
                    Task {
                        _ = try? await appState.apiClient.send(APIEndpoints.logout()) as EmptyResponse
                        await MainActor.run {
                            appState.sessionStore.clear()
                        }
                    }
                }
            )
            .tabItem {
                Label("Profile", systemImage: "person.circle")
            }
        }
        .background(Color.ghBackground)
        .tint(.ghAccent)
    }
}
