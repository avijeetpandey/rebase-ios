import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.sessionStore.isAuthenticated {
                MainTabView()
            } else {
                AuthContainerView()
            }
        }
        .preferredColorScheme(.dark)
        .background(Color.ghBackground.ignoresSafeArea())
    }
}
