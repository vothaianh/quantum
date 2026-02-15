import SwiftUI

struct TerminalPanelView: View {
    @Bindable var state: AppState
    @Environment(\.fontZoom) private var zoom

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(state.terminalTabs) { tab in
                            TerminalTabButton(
                                tab: tab,
                                isSelected: state.selectedTerminalTabID == tab.id,
                                onSelect: { state.selectedTerminalTabID = tab.id },
                                onClose: { closeTab(tab) }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }

                Spacer()

                Button(action: addTab) {
                    Image(systemName: "plus")
                        .font(.zoomed(size: 11, zoom: zoom, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 4)
            .background(Theme.bgHeader)

            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)

            if let tab = state.selectedTerminalTab {
                TerminalTabView(tab: tab)
                    .padding(10)
                    .background(Theme.bgTerminal)
                    .id(tab.id)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "terminal")
                        .font(.system(size: 36))
                        .foregroundStyle(Theme.textMuted)
                    Text("Click + to open a terminal")
                        .font(.zoomed(size: 12, zoom: zoom))
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.bgTerminal)
            }
        }
        .clipped()
    }

    private func addTab() {
        let tab = TerminalTab(workingDirectory: state.projectURL)
        state.terminalTabs.append(tab)
        state.selectedTerminalTabID = tab.id
    }

    private func closeTab(_ tab: TerminalTab) {
        state.terminalTabs.removeAll { $0.id == tab.id }
        if state.selectedTerminalTabID == tab.id {
            state.selectedTerminalTabID = state.terminalTabs.last?.id
        }
    }
}

private struct TerminalTabButton: View {
    let tab: TerminalTab
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @Environment(\.fontZoom) private var zoom
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "terminal")
                .font(.zoomed(size: 10, zoom: zoom))
                .foregroundStyle(Theme.textSecondary)
            Text(tab.title)
                .font(.zoomed(size: 11, zoom: zoom))
                .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                .lineLimit(1)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.zoomed(size: 8, zoom: zoom, weight: .bold))
                    .foregroundStyle(Theme.textMuted)
            }
            .buttonStyle(.borderless)
            .opacity(isHovered || isSelected ? 1 : 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            isSelected ? Theme.accent.opacity(0.15) :
            isHovered ? Theme.bgHover : Color.clear
        )
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture(perform: onSelect)
    }
}
