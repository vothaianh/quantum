import SwiftUI

struct CodeView: View {
    let content: String
    let fileExtension: String
    let zoom: Double

    var body: some View {
        let lineCount = max(content.components(separatedBy: "\n").count, 1)
        let digits = max(String(lineCount).count, 3)
        let gutterW = CGFloat(digits) * 8.0 * zoom + 20
        let fontSize = 11.0 * zoom

        GeometryReader { geo in
            ScrollView([.horizontal, .vertical]) {
                HStack(alignment: .top, spacing: 0) {
                    // Line numbers — single Text with newlines for perfect alignment
                    Text(lineNumbersText(count: lineCount))
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundStyle(Theme.textMuted)
                        .lineSpacing(3)
                        .multilineTextAlignment(.trailing)
                        .frame(width: gutterW, alignment: .trailing)
                        .padding(.vertical, 4)
                        .background(Theme.bgGutter)

                    // Separator
                    Rectangle()
                        .fill(Theme.border)
                        .frame(width: 1)

                    // Syntax-highlighted code
                    codeText(fontSize: fontSize)
                        .textSelection(.enabled)
                        .lineSpacing(3)
                        .fixedSize(horizontal: true, vertical: true)
                        .padding(.leading, 12)
                        .padding(.trailing, 20)
                        .padding(.vertical, 4)
                }
                .frame(minHeight: geo.size.height, alignment: .top)
            }
        }
        .background(Theme.bg)
    }

    // MARK: - Helpers

    private func lineNumbersText(count: Int) -> String {
        (1...count).map(String.init).joined(separator: "\n")
    }

    @ViewBuilder
    private func codeText(fontSize: CGFloat) -> some View {
        let font = NSFont(name: "Menlo", size: fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let ns = SyntaxHighlighter.highlight(content, fileExtension: fileExtension, font: font)

        if let attributed = try? AttributedString(ns, including: \.appKit) {
            Text(attributed)
        } else {
            Text(content)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
        }
    }
}
