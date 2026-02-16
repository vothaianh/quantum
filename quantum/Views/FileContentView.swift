import SwiftUI

struct FileContentView: View {
    @Bindable var state: AppState
    @Environment(\.fontZoom) private var zoom

    var body: some View {
        VStack(spacing: 0) {
            if !state.openEditorTabs.isEmpty {
                // Tab bar
                HStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 1) {
                            ForEach(state.openEditorTabs) { tab in
                                EditorTabButton(
                                    tab: tab,
                                    isSelected: state.selectedEditorTabID == tab.id,
                                    onSelect: { state.selectedEditorTabID = tab.id },
                                    onClose: { state.closeEditorTab(tab) },
                                    onCloseOthers: {
                                        state.openEditorTabs.removeAll { $0.id != tab.id }
                                        state.selectedEditorTabID = tab.id
                                        state.saveSession()
                                    },
                                    onCloseAll: {
                                        state.openEditorTabs.removeAll()
                                        state.selectedEditorTabID = nil
                                        state.saveSession()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 4)
                .background(Theme.bgHeader)

                Rectangle()
                    .fill(Theme.border)
                    .frame(height: 1)

                // File content — editable or diff
                if let tab = state.selectedEditorTab {
                    if tab.isDiff, let original = tab.diffOriginalContent {
                        DiffEditorView(
                            original: original,
                            modified: tab.content,
                            fileExtension: tab.file.url.pathExtension,
                            zoom: zoom
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .id(tab.id)
                    } else {
                        EditableCodeView(
                            content: contentBinding(for: tab.id),
                            isModified: modifiedBinding(for: tab.id),
                            fileExtension: tab.file.url.pathExtension,
                            zoom: zoom,
                            fileURL: tab.file.url,
                            goToLine: tab.pendingGoToLine,
                            searchQuery: tab.pendingSearchQuery,
                            onDidGoToLine: {
                                if let idx = state.openEditorTabs.firstIndex(where: { $0.id == tab.id }) {
                                    state.openEditorTabs[idx].pendingGoToLine = nil
                                    state.openEditorTabs[idx].pendingSearchQuery = nil
                                }
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .id(tab.id)
                    }
                } else {
                    emptyState
                }
            } else {
                emptyState
            }
        }
        .clipped()
    }

    // MARK: - Bindings

    private func contentBinding(for tabID: UUID) -> Binding<String> {
        Binding(
            get: { state.openEditorTabs.first(where: { $0.id == tabID })?.content ?? "" },
            set: { newValue in
                if let idx = state.openEditorTabs.firstIndex(where: { $0.id == tabID }) {
                    state.openEditorTabs[idx].content = newValue
                }
            }
        )
    }

    private func modifiedBinding(for tabID: UUID) -> Binding<Bool> {
        Binding(
            get: { state.openEditorTabs.first(where: { $0.id == tabID })?.isModified ?? false },
            set: { newValue in
                if let idx = state.openEditorTabs.firstIndex(where: { $0.id == tabID }) {
                    state.openEditorTabs[idx].isModified = newValue
                }
            }
        )
    }

    private static let emptyMessages = [
        "Your code awaits. Pick a file from the sidebar.",
        "No files open. The sidebar has plenty to choose from.",
        "It's quiet here... too quiet. Open a file.",
        "Ready when you are. Just pick a file.",
        "This space reserved for something brilliant.",
        "The editor is empty, but your potential isn't.",
        "Cmd+O to open a folder, or browse the sidebar.",
        "Great things start with a single file.",
    ]

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 36))
                .foregroundStyle(Theme.textMuted)
            Text(Self.emptyMessages.randomElement()!)
                .font(.zoomed(size: 12, zoom: zoom))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }
}

// MARK: - Editor Tab Button

private struct EditorTabButton: View {
    let tab: EditorTab
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    let onCloseOthers: () -> Void
    let onCloseAll: () -> Void

    @Environment(\.fontZoom) private var zoom
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 4) {
            if tab.isDiff {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.zoomed(size: 10, zoom: zoom, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            } else {
                Image(nsImage: FileIconResolver.icon(for: tab.file))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14 * zoom, height: 14 * zoom)
            }

            Text(tab.isDiff ? "\(tab.file.name) (diff)" : tab.file.name)
                .font(.zoomed(size: 11, zoom: zoom))
                .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                .lineLimit(1)

            // Modified dot or close button
            if tab.isModified && !(isHovered || isSelected) {
                Circle()
                    .fill(Theme.textMuted)
                    .frame(width: 6, height: 6)
                    .help("Unsaved Changes")
            } else {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.zoomed(size: 8, zoom: zoom, weight: .bold))
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.borderless)
                .opacity(isHovered || isSelected ? 1 : 0)
                .help("Close Tab")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            isSelected ? Theme.bg :
            isHovered ? Theme.bgHover : Theme.bgHeader
        )
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture(perform: onSelect)
        .contextMenu {
            Button("Close") { onClose() }
            Button("Close Others") { onCloseOthers() }
            Button("Close All") { onCloseAll() }
        }
    }
}
