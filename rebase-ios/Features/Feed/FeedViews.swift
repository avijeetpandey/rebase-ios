import SwiftUI

struct FeedView: View {
    @StateObject var viewModel: FeedViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.posts) { post in
                        CommitCardView(
                            post: post,
                            onLGTM: { viewModel.optimisticToggleLGTM(post: post) },
                            onComments: { viewModel.selectedPostForComments = post }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(Color.ghBackground)
            .navigationTitle("Rebase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showComposer = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Color.ghPrimaryText)
                    }
                }
            }
            .task {
                guard viewModel.posts.isEmpty else { return }
                await viewModel.loadFeed()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(item: $viewModel.selectedPostForComments) { post in
                CommentsSheetView(viewModel: CommentsViewModel(apiClient: viewModel.apiClient, post: post))
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $viewModel.showComposer) {
                ComposeCommitView(viewModel: ComposeCommitViewModel(apiClient: viewModel.apiClient)) { newPost in
                    viewModel.prepend(post: newPost)
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
}

private struct CommitCardView: View {
    let post: CommitPost
    let onLGTM: () -> Void
    let onComments: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                AvatarView(url: post.author.avatarURL, size: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(post.author.username)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.ghPrimaryText)
                    Text(post.createdAt.relativeTimestamp)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.ghSecondaryText)
                }

                Spacer()
                Image(systemName: "git.commit")
                    .foregroundStyle(Color.ghSecondaryText)
            }

            Text(post.message)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.ghPrimaryText)
                .fixedSize(horizontal: false, vertical: true)

            if let snippet = post.codeSnippet {
                CodeSnippetView(snippet: snippet)
            }

            if let imageURL = post.imageURL {
                AsyncImage(url: imageURL, transaction: .init(animation: .easeInOut(duration: 0.2))) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.ghSurface)
                            .frame(height: 220)
                            .overlay(ProgressView().tint(.ghSecondaryText))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    case .failure:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.ghSurface)
                            .frame(height: 220)
                            .overlay(Image(systemName: "photo").foregroundStyle(Color.ghSecondaryText))
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            HStack(spacing: 16) {
                Button(action: onLGTM) {
                    Label(
                        "\(post.lgtmCount)",
                        systemImage: post.isLGTMd ? "hand.thumbsup.fill" : "hand.thumbsup"
                    )
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(post.isLGTMd ? Color.ghAccent : Color.ghSecondaryText)
                }

                Button(action: onComments) {
                    Label("\(post.commentCount)", systemImage: "bubble.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.ghSecondaryText)
                }

                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.ghCard)
        )
    }
}
