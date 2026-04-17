import PhotosUI
import SwiftUI

struct ComposeCommitView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: ComposeCommitViewModel
    let onCreated: (CommitPost) -> Void
    @State private var pickerItem: PhotosPickerItem?
    @State private var previewImage: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("New Commit")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.ghPrimaryText)

                    TextField("What did you ship?", text: $viewModel.message, axis: .vertical)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.ghPrimaryText)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.ghCard))

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo")
                            Text("Attach image")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.ghPrimaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.ghSurface))
                    }
                    .onChange(of: pickerItem) { _, item in
                        Task {
                            guard let item else { viewModel.setImageData(nil); previewImage = nil; return }
                            do {
                                let data = try await item.loadTransferable(type: Data.self)
                                viewModel.setImageData(data)
                                if let data { previewImage = UIImage(data: data) }
                            } catch {
                                viewModel.errorMessage = "Unable to load selected image."
                            }
                        }
                    }

                    if let preview = previewImage {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Text("Code Snippet")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.ghSecondaryText)

                    TextField("Language (swift, js, go...)", text: $viewModel.snippetLanguage)
                        .font(.system(size: 14))
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.ghCard))

                    TextField("Paste code", text: $viewModel.snippetCode, axis: .vertical)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color.ghPrimaryText)
                        .padding(12)
                        .frame(minHeight: 120, alignment: .topLeading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.ghCodeBackground))

                    if let message = viewModel.errorMessage {
                        Text(message)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.red)
                    }
                }
                .padding(16)
            }
            .background(Color.ghBackground)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.ghSecondaryText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            do {
                                let post = try await viewModel.submit()
                                onCreated(post)
                                dismiss()
                            } catch {
                                viewModel.errorMessage =
                                    (error as? LocalizedError)?.errorDescription ?? "Unable to publish commit."
                            }
                        }
                    } label: {
                        if viewModel.isSubmitting {
                            ProgressView()
                        } else {
                            Text("Publish")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundStyle(Color.ghPrimaryText)
                    .disabled(viewModel.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSubmitting)
                }
            }
        }
    }
}
