import Foundation

protocol TokenStore: AnyObject {
    var accessToken: String? { get }
    var refreshToken: String? { get }
    func save(tokens: TokenPair)
    func clear()
}
