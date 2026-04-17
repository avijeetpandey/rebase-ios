import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: String
    let username: String
    let bio: String?
    let avatarURL: URL?
}
