import SwiftUI
import SwiftTerm

struct TerminalTabView: NSViewRepresentable {
    let tab: TerminalTab
    @Environment(\.fontZoom) private var zoom

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let termView = LocalProcessTerminalView(frame: .zero)

        // Dark theme colors
        let bgColor = NSColor(srgbRed: 0.059, green: 0.059, blue: 0.059, alpha: 1)  // #0F0F0F
        let fgColor = NSColor(srgbRed: 0.847, green: 0.910, blue: 0.875, alpha: 1)  // #D8E8DF

        termView.nativeBackgroundColor = bgColor
        termView.nativeForegroundColor = fgColor

        let fontSize = 11.0 * zoom
        termView.font = NSFont(name: "Menlo", size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

        // Start shell as login shell so it sources ~/.zprofile, ~/.zshrc, etc.
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"

        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env.removeValue(forKey: "CLAUDECODE")

        let cwd = tab.workingDirectory?.path ?? NSHomeDirectory()
        env["HOME"] = NSHomeDirectory()

        termView.startProcess(
            executable: shell,
            args: ["--login"],
            environment: env.map { "\($0.key)=\($0.value)" },
            execName: "-" + (shell as NSString).lastPathComponent,
            currentDirectory: cwd
        )

        if tab.workingDirectory != nil {
            termView.send(txt: "clear\n")
        }

        return termView
    }

    func updateNSView(_ termView: LocalProcessTerminalView, context: Context) {
        let fontSize = 11.0 * zoom
        termView.font = NSFont(name: "Menlo", size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }
}
