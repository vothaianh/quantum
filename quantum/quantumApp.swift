import SwiftUI

@main
struct quantumApp: App {
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var openFolderTrigger = false
    @State private var saveTrigger = false
    @State private var saveAsTrigger = false
    @State private var zoomInTrigger = false
    @State private var zoomOutTrigger = false
    @State private var zoomResetTrigger = false
    @State private var goToFileTrigger = false
    @State private var findInFilesTrigger = false
    @State private var toggleSidebarTrigger = false
    @State private var toggleTerminalTrigger = false

    var body: some Scene {
        WindowGroup {
            ContentView(
                showSettings: $showSettings,
                openFolderTrigger: $openFolderTrigger,
                saveTrigger: $saveTrigger,
                saveAsTrigger: $saveAsTrigger,
                zoomInTrigger: $zoomInTrigger,
                zoomOutTrigger: $zoomOutTrigger,
                zoomResetTrigger: $zoomResetTrigger,
                goToFileTrigger: $goToFileTrigger,
                findInFilesTrigger: $findInFilesTrigger,
                toggleSidebarTrigger: $toggleSidebarTrigger,
                toggleTerminalTrigger: $toggleTerminalTrigger
            )
                .onAppear {
                    NSApp.appearance = NSAppearance(named: .darkAqua)
                    _ = NSScroller.swizzleOnce
                    DispatchQueue.main.async {
                        guard let window = NSApplication.shared.windows.last else { return }
                        window.titlebarAppearsTransparent = true
                        window.title = ""
                        window.styleMask.insert(.fullSizeContentView)
                        window.titleVisibility = .hidden
                        window.toolbar = nil

                        window.backgroundColor = NSColor(srgbRed: 0.098, green: 0.098, blue: 0.098, alpha: 1)
                        window.isMovableByWindowBackground = true
                        if let screen = window.screen {
                            window.setFrame(screen.visibleFrame, display: true)
                        }
                    }
                }
                .sheet(isPresented: $showAbout) {
                    AboutView()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Quantum") {
                    showAbout = true
                }
            }
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    showSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            CommandGroup(replacing: .newItem) {
                Button("Open Folder...") {
                    openFolderTrigger.toggle()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    saveTrigger.toggle()
                }
                .keyboardShortcut("s", modifiers: .command)
                Button("Save As...") {
                    saveAsTrigger.toggle()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }

            CommandMenu("Edit") {
                Button("Find in Files") {
                    findInFilesTrigger.toggle()
                }
                .keyboardShortcut("f", modifiers: .command)
            }

            CommandMenu("View") {
                Button("Zoom In") {
                    zoomInTrigger.toggle()
                }
                .keyboardShortcut("+", modifiers: .command)
                Button("Zoom In") {
                    zoomInTrigger.toggle()
                }
                .keyboardShortcut("=", modifiers: .command)
                Button("Zoom Out") {
                    zoomOutTrigger.toggle()
                }
                .keyboardShortcut("-", modifiers: .command)
                Button("Actual Size") {
                    zoomResetTrigger.toggle()
                }
                .keyboardShortcut("0", modifiers: .command)

                Divider()

                Button("Toggle Sidebar") {
                    toggleSidebarTrigger.toggle()
                }
                .keyboardShortcut("b", modifiers: .command)
                Button("Toggle Terminal") {
                    toggleTerminalTrigger.toggle()
                }
                .keyboardShortcut("`", modifiers: .command)
            }

            CommandMenu("Go") {
                Button("Go to File...") {
                    goToFileTrigger.toggle()
                }
                .keyboardShortcut("p", modifiers: .command)
            }
        }
    }
}

// MARK: - About View

private struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private let techStacks: [(icon: String, name: String, detail: String)] = [
        ("swift", "Swift", "Primary language"),
        ("macwindow", "SwiftUI", "Declarative UI framework"),
        ("app.badge.checkmark", "AppKit", "Native macOS integration"),
        ("terminal", "SwiftTerm", "Integrated terminal emulator"),
        ("globe", "WKWebView", "WebKit-based rendering"),
        ("chevron.left.forwardslash.chevron.right", "CodeMirror 5", "Code editor with syntax highlighting"),
        ("arrow.triangle.branch", "Git", "Source control via CLI"),
        ("brain.head.profile", "Anthropic API", "AI-powered features"),
        ("brain", "Google Gemini API", "AI model provider"),
        ("doc.text", "TextKit", "Text editing engine"),
        ("paintbrush", "Custom Theming", "Dark-first design system"),
        ("magnifyingglass", "Search Index", "In-memory full-text search"),
        ("folder", "File System", "Live directory tree sync"),
        ("arrow.left.arrow.right", "Diff Engine", "Side-by-side file comparison"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                if let appIcon = NSApp.applicationIconImage {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: Theme.accent.opacity(0.3), radius: 12, y: 4)
                }

                Text("Quantum")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)

                Text("AI-Powered Code Editor")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)

                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)

            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)
                .padding(.horizontal, 20)

            // Tech stacks
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("TECH STACK")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.textMuted)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .padding(.bottom, 6)

                    ForEach(Array(techStacks.enumerated()), id: \.offset) { _, tech in
                        HStack(spacing: 10) {
                            Image(systemName: tech.icon)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.accent)
                                .frame(width: 20, alignment: .center)

                            Text(tech.name)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)

                            Spacer()

                            Text(tech.detail)
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textMuted)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 5)
                    }
                }
                .padding(.bottom, 8)
            }
            .frame(maxHeight: 280)

            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)
                .padding(.horizontal, 20)

            // Footer
            VStack(spacing: 6) {
                Text("Built with Swift & SwiftUI for macOS")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderless)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 6)
                .background(Theme.accent)
                .cornerRadius(6)
            }
            .padding(.vertical, 14)
        }
        .frame(width: 360)
        .background(Theme.bgSidebar)
    }
}
