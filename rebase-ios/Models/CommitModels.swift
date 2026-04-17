import Foundation

struct CodeSnippet: Codable, Hashable {
    let language: String
    let code: String
}

struct CommitPost: Codable, Identifiable, Hashable {
    let id: String
    let author: User
    let message: String
    let imageURL: URL?
    let codeSnippet: CodeSnippet?
    let createdAt: Date
    var lgtmCount: Int
    var commentCount: Int
    var isLGTMd: Bool
}

struct CommentModel: Codable, Identifiable, Hashable {
    let id: String
    let author: User
    let body: String
    let createdAt: Date
}

struct PresignedUploadResponse: Codable {
    let uploadURL: URL
    let publicURL: URL
}
