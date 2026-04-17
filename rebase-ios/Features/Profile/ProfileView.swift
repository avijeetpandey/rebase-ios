import SwiftUI

struct ProfileView: View {
    @StateObject var viewModel: ProfileViewModel
    let onLogout: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let user = viewModel.user {
                        HStack(alignment: .top, spacing: 14) {
                            AvatarView(url: user.avatarURL, size: 74)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(user.username)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(Color.ghPrimaryText)

                                if let bio = user.bio, !bio.isEmpty {
                                    Text(bio)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.ghSecondaryText)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.ghCard))
                    }

                    Text("Recent Commits")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.ghPrimaryText)

                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.commits) { post in
                            ReusableCommitCard(post: post)
                        }
                    }
                }
                .padding(12)
            }
            .background(Color.ghBackground)
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Logout", action: onLogout)
                        .foregroundStyle(Color.ghSecondaryText)
                }
            }
            .task {
                await viewModel.load()
            }
        }
    }
}

private struct ReusableCommitCard: View {
    let post: CommitPost

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.ghPrimaryText)
            Text(post.createdAt.relativeTimestamp)
                .font(.system(size: 12))
                .foregroundStyle(Color.ghSecondaryText)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.ghCard))
    }
}
