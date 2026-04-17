import SwiftUI

extension Color {
    static let ghBackground = Color(hex: "#000000")
    static let ghCard = Color(hex: "#161B22")
    static let ghSurface = Color(hex: "#21262D")
    static let ghAccent = Color(hex: "#2F81F7")
    static let ghPrimaryText = Color.white
    static let ghSecondaryText = Color(hex: "#8B949E")
    static let ghCodeBackground = Color(hex: "#0D1117")
    static let ghSyntaxKeyword = Color(hex: "#FF7B72")
    static let ghSyntaxString = Color(hex: "#A5D6FF")
    static let ghSyntaxComment = Color(hex: "#8B949E")
    static let ghSyntaxNumber = Color(hex: "#79C0FF")
    static let ghSyntaxOperator = Color(hex: "#C9D1D9")
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)

        let r: UInt64
        let g: UInt64
        let b: UInt64

        switch cleaned.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (255, 255, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
