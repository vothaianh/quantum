import SwiftUI
import SwiftTerm

struct TerminalTabView: NSViewRepresentable {
    let tab: TerminalTab
    @Environment(\.fontZoom) private var zoom

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let termView = LocalProcessTerminalView(frame: .zero)

        // Dark theme colors
        let bgColor = NSColor(srgbRed: 0.059, green: 0.067, blue: 0.082, alpha: 1)  // #0F1115
        let fgColor = NSColor(srgbRed: 0.847, green: 0.863, blue: 0.894, alpha: 1)  // #D8DCE4

        termView.nativeBackgroundColor = bgColor
        termView.nativeForegroundColor = fgColor

        let fontSize = 11.0 * zoom
        termView.font = NSFont(name: "Menlo", size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

        // Start shell
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let dir = tab.workingDirectory?.path ?? NSHomeDirectory()

        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env.removeValue(forKey: "CLAUDECODE")

        termView.startProcess(
            executable: shell,
            args: [],
            environment: env.map { "\($0.key)=\($0.value)" },
            execName: (shell as NSString).lastPathComponent
        )

        if let cwd = tab.workingDirectory {
            let cdCmd = "cd \(cwd.path.replacingOccurrences(of: " ", with: "\\ ")) && clear\n"
            termView.send(txt: cdCmd)
        }

        return termView
    }

    func updateNSView(_ termView: LocalProcessTerminalView, context: Context) {
        let fontSize = 11.0 * zoom
        termView.font = NSFont(name: "Menlo", size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }
}
