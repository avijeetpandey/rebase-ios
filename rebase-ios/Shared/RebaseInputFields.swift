import SwiftUI
import UIKit

struct RebaseTextField: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        TextField(title, text: $text)
            .textInputAutocapitalization(.never)
            .keyboardType(keyboard)
            .autocorrectionDisabled(true)
            .font(.system(size: 15, weight: .regular))
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.ghCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.ghSurface, lineWidth: 1)
            )
    }
}

struct RebaseSecureField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        SecureField(title, text: $text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .font(.system(size: 15, weight: .regular))
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.ghCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.ghSurface, lineWidth: 1)
            )
    }
}

struct RebasePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.ghPrimaryText)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(configuration.isPressed ? Color.ghAccent.opacity(0.7) : Color.ghAccent)
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}
