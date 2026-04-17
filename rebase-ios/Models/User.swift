import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: String
    let username: String
    let email: String?
    let bio: String?
    let avatarUrl: String?

    var avatarURL: URL? { avatarUrl.flatMap(URL.init) }
}

extension User {
    init(from decoder: Decoder) throws {
        enum Keys: String, CodingKey {
            case id, username, email, bio, avatarUrl
        }
        let c = try decoder.container(keyedBy: Keys.self)
        if let str = try? c.decode(String.self, forKey: .id) {
            id = str
        } else {
            id = String(try c.decode(Int.self, forKey: .id))
        }
        username = try c.decode(String.self, forKey: .username)
        email = try c.decodeIfPresent(String.self, forKey: .email)
        bio = try c.decodeIfPresent(String.self, forKey: .bio)
        avatarUrl = try c.decodeIfPresent(String.self, forKey: .avatarUrl)
    }
}
