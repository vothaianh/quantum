import SwiftUI

@main
struct quantumApp: App {
    @State private var showSettings = false
    @State private var openFolderTrigger = false
    @State private var saveTrigger = false
    @State private var saveAsTrigger = false

    var body: some Scene {
        WindowGroup {
            ContentView(showSettings: $showSettings, openFolderTrigger: $openFolderTrigger, saveTrigger: $saveTrigger, saveAsTrigger: $saveAsTrigger)
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

                        window.backgroundColor = NSColor(srgbRed: 0.094, green: 0.106, blue: 0.129, alpha: 1)
                        window.isMovableByWindowBackground = true
                        if let screen = window.screen {
                            window.setFrame(screen.visibleFrame, display: true)
                        }
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
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
        }
    }
}
