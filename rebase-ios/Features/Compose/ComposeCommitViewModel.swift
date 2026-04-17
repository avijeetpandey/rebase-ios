import Foundation
import OSLog
import UIKit

private let composeLogger = Logger(subsystem: "com.rebase.rebase-ios", category: "Compose")

@MainActor
final class ComposeCommitViewModel: ObservableObject {
    private enum UploadLimits {
        static let maxImageBytes = 900_000
        static let maxPixelDimension: CGFloat = 1600
        static let minCompressionQuality: CGFloat = 0.45
    }

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
        errorMessage = nil

        guard let data else {
            selectedImageData = nil
            return
        }

        guard let optimized = optimizedImageData(from: data) else {
            selectedImageData = nil
            errorMessage = "Selected image is too large. Choose a smaller image."
            return
        }

        selectedImageData = optimized
    }

    func submit() async throws -> CommitPost {
        isSubmitting = true
        defer { isSubmitting = false }

        let trimmedCode = snippetCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let snippet: String? = trimmedCode.isEmpty ? nil : trimmedCode
        let language: String? = snippet != nil ? snippetLanguage : nil

        composeLogger.debug("Submitting post")
        let endpoint = try APIEndpoints.createPost(
            content: message,
            codeSnippet: snippet,
            language: language,
            imageData: selectedImageData
        )
        let post = try await apiClient.send(endpoint)
        composeLogger.info("Post submitted: \(post.id)")
        return post
    }

    private func optimizedImageData(from data: Data) -> Data? {
        if data.count <= UploadLimits.maxImageBytes {
            return data
        }

        guard let image = UIImage(data: data) else {
            return nil
        }

        let resizedImage = resizedImageIfNeeded(image)

        var quality: CGFloat = 0.82
        while quality >= UploadLimits.minCompressionQuality {
            if let jpegData = resizedImage.jpegData(compressionQuality: quality),
               jpegData.count <= UploadLimits.maxImageBytes {
                composeLogger.debug("Compressed image from \(data.count) to \(jpegData.count) bytes")
                return jpegData
            }
            quality -= 0.08
        }

        return nil
    }

    private func resizedImageIfNeeded(_ image: UIImage) -> UIImage {
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > UploadLimits.maxPixelDimension else {
            return image
        }

        let scale = UploadLimits.maxPixelDimension / longestSide
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
