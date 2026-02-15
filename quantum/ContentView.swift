import SwiftUI

struct ContentView: View {
    @State private var state = AppState()
    @State private var sidebarFraction: CGFloat = 0.15
    @State private var terminalFraction: CGFloat = 0.30

    var body: some View {
        Group {
            if state.projectURL != nil {
                GeometryReader { geo in
                    let totalWidth = geo.size.width
                    let sidebarWidth = state.showSidebar ? totalWidth * sidebarFraction : 0
                    let terminalWidth = state.showTerminal ? totalWidth * terminalFraction : 0
                    let editorWidth = totalWidth - sidebarWidth - terminalWidth

                    HStack(spacing: 0) {
                        if state.showSidebar {
                            SidebarView(state: state)
                                .frame(width: sidebarWidth)

                            PanelDivider { delta in
                                let newFraction = sidebarFraction + delta / totalWidth
                                sidebarFraction = newFraction.clamped(to: 0.08...0.40)
                            }
                        }

                        FileContentView(state: state)
                            .frame(width: editorWidth)

                        if state.showTerminal {
                            PanelDivider { delta in
                                let newFraction = terminalFraction - delta / totalWidth
                                terminalFraction = newFraction.clamped(to: 0.10...0.60)
                            }

                            TerminalPanelView(state: state)
                                .frame(width: terminalWidth)
                        }
                    }
                }
                .background(Theme.bg)
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button(action: openFolder) {
                            Label("Open Folder", systemImage: "folder.badge.plus")
                        }

                        Spacer()

                        Button {
                            state.showSidebar.toggle()
                        } label: {
                            Label("Toggle Sidebar", systemImage: "sidebar.left")
                        }

                        Button {
                            state.showTerminal.toggle()
                        } label: {
                            Label("Toggle Terminal", systemImage: "terminal")
                        }
                    }
                }
            } else {
                WelcomeView(state: state, onOpenFolder: openFolder)
            }
        }
        .environment(\.fontZoom, state.zoomLevel)
        .frame(minWidth: 800, minHeight: 500)
        .background(Theme.bg)
        .keyboardShortcut(for: openFolder)
        .onAppear { state.loadZoom() }
        .background {
            Group {
                Button("") { state.zoomIn() }
                    .keyboardShortcut("+", modifiers: .command)
                Button("") { state.zoomIn() }
                    .keyboardShortcut("=", modifiers: .command)
                Button("") { state.zoomOut() }
                    .keyboardShortcut("-", modifiers: .command)
                Button("") { state.zoomReset() }
                    .keyboardShortcut("0", modifiers: .command)
            }
            .hidden()
        }
    }

    private func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a project folder"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        state.openProject(at: url)
    }
}

// MARK: - Draggable Divider

private struct PanelDivider: View {
    let onDrag: (CGFloat) -> Void

    var body: some View {
        Rectangle()
            .fill(Theme.border)
            .frame(width: 1.5)
            .contentShape(Rectangle().inset(by: -3))
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        onDrag(value.translation.width)
                    }
            )
    }
}

// MARK: - Helpers

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

private extension View {
    func keyboardShortcut(for action: @escaping () -> Void) -> some View {
        self.background(
            Button("") { action() }
                .keyboardShortcut("o", modifiers: .command)
                .hidden()
        )
    }
}

#Preview {
    ContentView()
}
