import SwiftUI

struct CommentsSheetView: View {
    @StateObject var viewModel: CommentsViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List(viewModel.comments) { comment in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(comment.author.username)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.ghPrimaryText)
                        Text(comment.body)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.ghPrimaryText)
                        Text(comment.createdAt.relativeTimestamp)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.ghSecondaryText)
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Color.ghCard)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.ghBackground)

                HStack(spacing: 10) {
                    TextField("Add a comment", text: $viewModel.input, axis: .vertical)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.ghPrimaryText)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.ghCard)
                        )

                    Button {
                        Task { await viewModel.sendComment() }
                    } label: {
                        if viewModel.isSending {
                            ProgressView().tint(.ghPrimaryText)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .foregroundStyle(Color.ghPrimaryText)
                        }
                    }
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.ghAccent))
                }
                .padding(12)
                .background(Color.ghBackground)
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.load()
            }
        }
    }
}
