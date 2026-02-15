import SwiftUI

struct SidebarView: View {
    @Bindable var state: AppState
    @Environment(\.fontZoom) private var zoom

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let root = state.rootFileItem {
                HStack(spacing: 6) {
                    Image(nsImage: FileIconResolver.icon(for: root))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16 * zoom, height: 16 * zoom)
                    Text(root.name)
                        .font(.zoomed(size: 12, zoom: zoom, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Theme.bgHeader)

                Rectangle()
                    .fill(Theme.border)
                    .frame(height: 1)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if let children = root.children {
                            ForEach(children) { item in
                                FileTreeRow(item: item, state: state, depth: 0)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .darkScrollers()
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 36))
                        .foregroundStyle(Theme.textMuted)
                    Text("Open a folder to begin")
                        .font(.zoomed(size: 12, zoom: zoom))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Theme.bgSidebar)
    }
}

private struct FileTreeRow: View {
    let item: FileItem
    @Bindable var state: AppState
    let depth: Int

    @Environment(\.fontZoom) private var zoom
    @State private var isExpanded = false
    @State private var isHovered = false

    private var isSelected: Bool {
        state.selectedFile?.id == item.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                if item.isDirectory {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.zoomed(size: 9, zoom: zoom, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 12)
                } else {
                    Spacer().frame(width: 12)
                }

                Image(nsImage: FileIconResolver.icon(for: item, expanded: isExpanded))
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16 * zoom, height: 16 * zoom)

                Text(item.name)
                    .font(.zoomed(size: 12, zoom: zoom))
                    .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textPrimary.opacity(0.85))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()
            }
            .padding(.leading, CGFloat(depth) * 16 + 8)
            .padding(.vertical, 3)
            .padding(.trailing, 8)
            .contentShape(Rectangle())
            .background(
                isSelected ? Theme.accent.opacity(0.2) :
                isHovered ? Theme.bgHover : Color.clear
            )
            .cornerRadius(3)
            .onHover { isHovered = $0 }
            .onTapGesture {
                if item.isDirectory {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isExpanded.toggle()
                    }
                } else {
                    state.selectedFile = item
                    state.fileContent = FileService.readFile(at: item.url)
                }
            }

            if item.isDirectory && isExpanded, let children = item.children {
                ForEach(children) { child in
                    FileTreeRow(item: child, state: state, depth: depth + 1)
                }
            }
        }
    }
}
