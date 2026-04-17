import Foundation

extension Date {
    var relativeTimestamp: String {
        RelativeDateTimeFormatter().localizedString(for: self, relativeTo: Date())
    }
}
