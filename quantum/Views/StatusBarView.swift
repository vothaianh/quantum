import SwiftUI

struct StatusBarView: View {
    @Bindable var state: AppState
    @Environment(\.fontZoom) private var zoom

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)

            HStack(spacing: 14) {
                // Git branch
                if !state.gitBranch.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textMuted)
                        Text("Branch:")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textMuted)
                        Text(state.gitBranch)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .onTapGesture {
                        state.sidebarTab = .git
                        if !state.showSidebar { state.showSidebar = true }
                        state.refreshGit()
                    }
                }

                // File info
                if let tab = state.selectedEditorTab {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(tab.isModified ? .orange : Theme.termGreen)
                            .frame(width: 7, height: 7)
                        Text(tab.file.name)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    }

                    let ext = tab.file.url.pathExtension.uppercased()
                    if !ext.isEmpty {
                        Text(ext)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textMuted)
                    }
                }

                Spacer()

                // Line count
                if let tab = state.selectedEditorTab {
                    let lines = tab.content.components(separatedBy: "\n").count
                    Text("\(lines) lines")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textMuted)
                }

                Text("\(Int(state.zoomLevel * 100))%")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
        }
        .background(Theme.bgHeader)
    }
}
