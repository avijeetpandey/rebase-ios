import Foundation

struct CommitPost: Codable, Identifiable, Hashable {
    let id: String
    let author: User
    let content: String
    let imageUrl: String?
    let codeSnippet: String?
    let language: String?
    let createdAt: Date
    var lgtmCount: Int
    var commentCount: Int
    var likedByCurrentUser: Bool

    var message: String { content }
    var imageURL: URL? { imageUrl.flatMap(URL.init) }
    var isLGTMd: Bool {
        get { likedByCurrentUser }
        set { likedByCurrentUser = newValue }
    }
    var snippet: CodeSnippet? {
        guard let code = codeSnippet, !code.isEmpty else { return nil }
        return CodeSnippet(language: language ?? "text", code: code)
    }
}

struct CodeSnippet: Codable, Hashable {
    let language: String
    let code: String
}

struct CommentModel: Codable, Identifiable, Hashable {
    let id: String
    let author: User
    let content: String
    let createdAt: Date
}

struct LGTMResponse: Codable {
    let lgtmCount: Int
    let lgtmed: Bool
}

extension CommitPost {
    init(from decoder: Decoder) throws {
        enum Keys: String, CodingKey {
            case id, author, content, imageUrl, codeSnippet, language, codeLanguage
            case createdAt, lgtmCount, commentCount, likedByCurrentUser
        }
        let c = try decoder.container(keyedBy: Keys.self)
        if let str = try? c.decode(String.self, forKey: .id) {
            id = str
        } else {
            id = String(try c.decode(Int.self, forKey: .id))
        }
        author = try c.decode(User.self, forKey: .author)
        content = try c.decode(String.self, forKey: .content)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        codeSnippet = try c.decodeIfPresent(String.self, forKey: .codeSnippet)
        language = try c.decodeIfPresent(String.self, forKey: .codeLanguage)
            ?? c.decodeIfPresent(String.self, forKey: .language)

        if let date = try? c.decode(Date.self, forKey: .createdAt) {
            createdAt = date
        } else {
            let rawDate = try c.decode(String.self, forKey: .createdAt)
            guard let parsedDate = DateParser.parse(rawDate) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .createdAt,
                    in: c,
                    debugDescription: "Unsupported date format: \(rawDate)"
                )
            }
            createdAt = parsedDate
        }
        lgtmCount = try c.decode(Int.self, forKey: .lgtmCount)
        commentCount = try c.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        likedByCurrentUser = try c.decodeIfPresent(Bool.self, forKey: .likedByCurrentUser) ?? false
    }
}

extension CommentModel {
    init(from decoder: Decoder) throws {
        enum Keys: String, CodingKey {
            case id, author, body, content, createdAt
        }
        let c = try decoder.container(keyedBy: Keys.self)
        if let str = try? c.decode(String.self, forKey: .id) {
            id = str
        } else {
            id = String(try c.decode(Int.self, forKey: .id))
        }
        author = try c.decode(User.self, forKey: .author)
        content = try c.decodeIfPresent(String.self, forKey: .content)
            ?? c.decode(String.self, forKey: .body)

        if let date = try? c.decode(Date.self, forKey: .createdAt) {
            createdAt = date
        } else {
            let rawDate = try c.decode(String.self, forKey: .createdAt)
            guard let parsedDate = DateParser.parse(rawDate) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .createdAt,
                    in: c,
                    debugDescription: "Unsupported date format: \(rawDate)"
                )
            }
            createdAt = parsedDate
        }
    }
}

struct PageResponse<T: Codable>: Codable {
    private enum CodingKeys: String, CodingKey {
        case content, totalPages, totalElements, number, size, last, first, numberOfElements, empty
    }

    let content: [T]
    let totalPages: Int
    let totalElements: Int
    let number: Int
    let size: Int
    let last: Bool
    let first: Bool
    let numberOfElements: Int
    let empty: Bool

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode([T].self, forKey: .content)
        totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages) ?? 1
        totalElements = try container.decodeIfPresent(Int.self, forKey: .totalElements) ?? content.count
        number = try container.decodeIfPresent(Int.self, forKey: .number) ?? 0
        size = try container.decodeIfPresent(Int.self, forKey: .size) ?? content.count
        last = try container.decodeIfPresent(Bool.self, forKey: .last) ?? true
        first = try container.decodeIfPresent(Bool.self, forKey: .first) ?? (number == 0)
        numberOfElements = try container.decodeIfPresent(Int.self, forKey: .numberOfElements) ?? content.count
        empty = try container.decodeIfPresent(Bool.self, forKey: .empty) ?? content.isEmpty
    }
}

struct CreatePostRequest: Encodable {
    let content: String
    let codeSnippet: String?
    let language: String?
}

struct PresignedUploadResponse: Codable {
    let uploadURL: URL
    let publicURL: URL
}

private enum DateParser {
    static func parse(_ value: String) -> Date? {
        if let iso8601Date = iso8601WithFractional.date(from: value) ?? iso8601.date(from: value) {
            return iso8601Date
        }
        return backendDateFormatter.date(from: value)
    }

    private static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let backendDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
}
