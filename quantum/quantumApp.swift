import SwiftUI

@main
struct quantumApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NSApp.appearance = NSAppearance(named: .darkAqua)
                    if let window = NSApplication.shared.windows.first {
                        window.zoom(nil)
                    }
                }
        }
    }
}
