import Foundation

@Observable
final class TerminalTab: Identifiable {
    let id = UUID()
    let title: String
    let workingDirectory: URL?

    init(title: String = "zsh", workingDirectory: URL? = nil) {
        self.title = title
        self.workingDirectory = workingDirectory
    }
}
