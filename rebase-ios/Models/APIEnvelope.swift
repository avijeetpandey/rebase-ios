import Foundation

struct APIEnvelope<T: Codable>: Codable {
    let data: T
}
