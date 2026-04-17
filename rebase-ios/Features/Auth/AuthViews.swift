import SwiftUI

struct AuthContainerView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(Color.ghAccent)
                    Text("Rebase")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Color.ghPrimaryText)
                    Text("Developer social network")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color.ghSecondaryText)
                }
                .padding(.top, 60)

                if showSignUp {
                    SignUpView(
                        viewModel: AuthViewModel(
                            mode: .signup,
                            apiClient: appState.apiClient,
                            sessionStore: appState.sessionStore
                        ),
                        showSignUp: $showSignUp
                    )
                } else {
                    LoginView(
                        viewModel: AuthViewModel(
                            mode: .login,
                            apiClient: appState.apiClient,
                            sessionStore: appState.sessionStore
                        ),
                        showSignUp: $showSignUp
                    )
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.ghBackground)
        }
    }
}

private struct LoginView: View {
    @StateObject var viewModel: AuthViewModel
    @Binding var showSignUp: Bool

    var body: some View {
        VStack(spacing: 14) {
            RebaseTextField(title: "Username", text: $viewModel.username)
            RebaseSecureField(title: "Password", text: $viewModel.password)

            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.red.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: {
                Task { await viewModel.submit() }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color.ghPrimaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                } else {
                    Text("Sign in")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
            }
            .buttonStyle(RebasePrimaryButtonStyle())
            .disabled(viewModel.isLoading)

            Button("Need an account? Sign up") {
                showSignUp = true
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.ghSecondaryText)
            .padding(.top, 6)
        }
    }
}

private struct SignUpView: View {
    @StateObject var viewModel: AuthViewModel
    @Binding var showSignUp: Bool

    var body: some View {
        VStack(spacing: 14) {
            RebaseTextField(title: "Username", text: $viewModel.username)
            RebaseTextField(title: "Email", text: $viewModel.email, keyboard: .emailAddress)
            RebaseSecureField(title: "Password", text: $viewModel.password)

            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.red.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: {
                Task { await viewModel.submit() }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color.ghPrimaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                } else {
                    Text("Create account")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
            }
            .buttonStyle(RebasePrimaryButtonStyle())
            .disabled(viewModel.isLoading)

            Button("Already have an account? Sign in") {
                showSignUp = false
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.ghSecondaryText)
            .padding(.top, 6)
        }
    }
}
