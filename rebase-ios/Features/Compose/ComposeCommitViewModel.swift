import Foundation

@MainActor
final class ComposeCommitViewModel: ObservableObject {
    @Published var message = ""
    @Published var snippetCode = ""
    @Published var snippetLanguage = "swift"
    @Published var selectedImageData: Data?
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func setImageData(_ data: Data?) {
        selectedImageData = data
    }

    func submit() async throws -> CommitPost {
        isSubmitting = true
        defer { isSubmitting = false }

        var uploadedImageURL: URL?
        if let imageData = selectedImageData {
            let uploadResponse = try await apiClient.send(
                APIEndpoints.requestPresignedUpload(
                    fileName: "commit-\(UUID().uuidString).jpg",
                    mimeType: "image/jpeg"
                )
            )

            try await apiClient.upload(data: imageData, to: uploadResponse.uploadURL, mimeType: "image/jpeg")
            uploadedImageURL = uploadResponse.publicURL
        }

        let snippet: CodeSnippet?
        if snippetCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            snippet = nil
        } else {
            snippet = CodeSnippet(language: snippetLanguage, code: snippetCode)
        }

        return try await apiClient.send(
            APIEndpoints.createCommit(
                message: message,
                imageURL: uploadedImageURL,
                codeSnippet: snippet
            )
        )
    }
}
