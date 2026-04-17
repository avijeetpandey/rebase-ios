import SwiftUI

struct CodeSnippetView: View {
    let snippet: CodeSnippet

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .foregroundStyle(Color.ghSecondaryText)
                    .font(.system(size: 12, weight: .semibold))
                Text(snippet.language.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.ghSecondaryText)
            }

            SyntaxHighlightedText(code: snippet.code)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.ghCodeBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.ghSurface, lineWidth: 1)
        )
    }
}

private struct SyntaxHighlightedText: View {
    let code: String

    var body: some View {
        let segments = SimpleSyntaxHighlighter.highlight(code)
        segments.reduce(Text("")) { partial, segment in
            partial + Text(segment.text)
                .foregroundStyle(segment.color)
                .font(.system(size: 12.5, weight: .regular, design: .monospaced))
        }
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HighlightSegment {
    let text: String
    let color: Color
}

private enum SimpleSyntaxHighlighter {
    private static let keywords: Set<String> = [
        "func", "let", "var", "if", "else", "for", "while", "switch", "case", "class", "struct",
        "enum", "import", "return", "async", "await", "throws", "throw", "protocol", "extension",
        "public", "private", "internal", "true", "false", "nil", "const", "function", "new", "try",
        "catch", "package", "interface", "type", "guard", "in"
    ]

    static func highlight(_ code: String) -> [HighlightSegment] {
        var result: [HighlightSegment] = []
        let chars = Array(code)
        var i = 0

        while i < chars.count {
            let ch = chars[i]

            if ch == "/", i + 1 < chars.count, chars[i + 1] == "/" {
                let start = i
                while i < chars.count, chars[i] != "\n" { i += 1 }
                result.append(HighlightSegment(text: String(chars[start..<i]), color: .ghSyntaxComment))
                continue
            }

            if ch == "\"" {
                let start = i
                i += 1
                while i < chars.count {
                    if chars[i] == "\\", i + 1 < chars.count {
                        i += 2
                        continue
                    }
                    if chars[i] == "\"" {
                        i += 1
                        break
                    }
                    i += 1
                }
                result.append(HighlightSegment(text: String(chars[start..<i]), color: .ghSyntaxString))
                continue
            }

            if ch.isNumber {
                let start = i
                i += 1
                while i < chars.count, (chars[i].isNumber || chars[i] == ".") { i += 1 }
                result.append(HighlightSegment(text: String(chars[start..<i]), color: .ghSyntaxNumber))
                continue
            }

            if ch.isLetter || ch == "_" {
                let start = i
                i += 1
                while i < chars.count, chars[i].isLetter || chars[i].isNumber || chars[i] == "_" { i += 1 }
                let token = String(chars[start..<i])
                if keywords.contains(token) {
                    result.append(HighlightSegment(text: token, color: .ghSyntaxKeyword))
                } else {
                    result.append(HighlightSegment(text: token, color: .ghPrimaryText))
                }
                continue
            }

            if ["(", ")", "{", "}", "[", "]", ".", ",", ":", "+", "-", "*", "=", "<", ">", "!", "&", "|"].contains(ch) {
                result.append(HighlightSegment(text: String(ch), color: .ghSyntaxOperator))
                i += 1
                continue
            }

            result.append(HighlightSegment(text: String(ch), color: .ghPrimaryText))
            i += 1
        }

        return result
    }
}
