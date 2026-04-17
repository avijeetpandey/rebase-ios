import SwiftUI

struct MainTabView: View {
    enum Tab {
        case feed
        case compose
        case profile
    }

    @StateObject private var feedViewModel: FeedViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    @State private var selectedTab: Tab = .feed
    let apiClient: APIClient
    @ObservedObject var sessionStore: SessionStore

    init(apiClient: APIClient, sessionStore: SessionStore) {
        self.apiClient = apiClient
        self.sessionStore = sessionStore
        _feedViewModel = StateObject(wrappedValue: FeedViewModel(apiClient: apiClient))
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(apiClient: apiClient, sessionStore: sessionStore))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView(viewModel: feedViewModel)
            .tag(Tab.feed)
            .tabItem {
                Label("Feed", systemImage: "list.bullet.rectangle")
            }

            ComposeCommitView(
                viewModel: ComposeCommitViewModel(apiClient: apiClient),
                showsCancel: false,
                onCreated: { newPost in
                    feedViewModel.prepend(post: newPost)
                    selectedTab = .feed
                }
            )
            .tag(Tab.compose)
            .tabItem {
                Label("Create", systemImage: "square.and.pencil")
            }

            ProfileView(
                viewModel: profileViewModel,
                onLogout: {
                    Task {
                        _ = try? await apiClient.send(APIEndpoints.logout()) as EmptyResponse
                        await MainActor.run {
                            sessionStore.clear()
                            selectedTab = .feed
                        }
                    }
                }
            )
            .tag(Tab.profile)
            .tabItem {
                Label("Profile", systemImage: "person.circle")
            }
        }
        .background(Color.ghBackground)
        .tint(.ghAccent)
    }
}
