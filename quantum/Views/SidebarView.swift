import SwiftUI

struct SidebarView: View {
    @Bindable var state: AppState
    @Environment(\.fontZoom) private var zoom

    var body: some View {
        VStack(spacing: 0) {
            // Icon tab bar — horizontal at top
            HStack(spacing: 6) {
                Spacer()
                SidebarTabIcon(icon: "doc.on.doc", tab: .files, selected: state.sidebarTab)
                    .onTapGesture { state.sidebarTab = .files }
                SidebarTabIcon(icon: "magnifyingglass", tab: .search, selected: state.sidebarTab)
                    .onTapGesture { state.sidebarTab = .search }
                SidebarTabIcon(icon: "arrow.triangle.branch", tab: .git, selected: state.sidebarTab)
                    .onTapGesture {
                        state.sidebarTab = .git
                        state.refreshGit()
                    }
                SidebarTabIcon(icon: "square.grid.2x2", tab: .projects, selected: state.sidebarTab)
                    .onTapGesture { state.sidebarTab = .projects }
                Spacer()
            }
            .padding(.vertical, 10)
            .background(Theme.bgHeader)

            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)

            // Content
            switch state.sidebarTab {
            case .projects:
                ProjectsPanel(state: state)
            case .files:
                FileTreePanel(state: state)
            case .search:
                SearchPanel(state: state)
            case .git:
                GitPanel(state: state)
            }
        }
        .background(Theme.bgSidebar)
    }
}

// MARK: - Tab Icon

private struct SidebarTabIcon: View {
    let icon: String
    let tab: SidebarTab
    let selected: SidebarTab
    @State private var isHovered = false

    private var isActive: Bool { tab == selected }

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(isActive ? Theme.accent : Theme.textMuted)
            .frame(width: 32, height: 32)
            .background(isActive ? Theme.bgSelected : isHovered ? Theme.bgHover : .clear)
            .cornerRadius(6)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
    }
}

// MARK: - Projects Panel

private struct ProjectsPanel: View {
    @Bindable var state: AppState
    @Environment(\.fontZoom) private var zoom
    @State private var renamingURL: URL?
    @State private var renameText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Text("PROJECTS")
                    .font(.zoomed(size: 10, zoom: zoom, weight: .semibold))
                    .foregroundStyle(Theme.textMuted)
                Spacer()
                Button { addProject() } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Theme.accent)
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)
                .help("Add project")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)

            if state.recentProjects.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.textMuted)
                    Text("No projects yet")
                        .font(.zoomed(size: 12, zoom: zoom))
                        .foregroundStyle(Theme.textSecondary)
                    Button { addProject() } label: {
                        Text("Add Project")
                            .font(.zoomed(size: 11, zoom: zoom, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Theme.accent)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.borderless)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(state.recentProjects, id: \.path) { url in
                            ProjectRow(
                                url: url,
                                state: state,
                                isRenaming: renamingURL?.path == url.path,
                                renameText: renamingURL?.path == url.path ? $renameText : .constant(""),
                                onStartRename: {
                                    renameText = state.displayName(for: url)
                                    renamingURL = url
                                },
                                onCommitRename: {
                                    state.renameProject(url, to: renameText)
                                    renamingURL = nil
                                },
                                onCancelRename: { renamingURL = nil }
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func addProject() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a project folder"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        state.addToRecents(url)
    }
}

private struct ProjectRow: View {
    let url: URL
    @Bindable var state: AppState
    let isRenaming: Bool
    @Binding var renameText: String
    let onStartRename: () -> Void
    let onCommitRename: () -> Void
    let onCancelRename: () -> Void

    @Environment(\.fontZoom) private var zoom
    @State private var isHovered = false
    @FocusState private var isFocused: Bool

    private var isCurrent: Bool {
        state.projectURL?.path == url.path
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .font(.zoomed(size: 13, zoom: zoom))
                .foregroundStyle(Theme.folderBlue)

            VStack(alignment: .leading, spacing: 1) {
                if isRenaming {
                    TextField("Name", text: $renameText)
                        .textFieldStyle(.plain)
                        .font(.zoomed(size: 11, zoom: zoom, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                        .focused($isFocused)
                        .onSubmit { onCommitRename() }
                        .onExitCommand { onCancelRename() }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Theme.bg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Theme.accent, lineWidth: 1.5)
                        )
                        .cornerRadius(4)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                isFocused = true
                            }
                        }
                } else {
                    Text(state.displayName(for: url))
                        .font(.zoomed(size: 11, zoom: zoom, weight: .medium))
                        .foregroundStyle(isCurrent ? Theme.accent : Theme.textPrimary)
                        .lineLimit(1)
                }
                Text(url.path)
                    .font(.zoomed(size: 9, zoom: zoom))
                    .foregroundStyle(Theme.textMuted)
                    .lineLimit(1)
                    .truncationMode(.head)
            }

            Spacer()

            if isHovered && !isRenaming {
                // Open in new window
                Button { state.openProjectInNewWindow(url) } label: {
                    Image(systemName: "macwindow.badge.plus")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 26, height: 26)
                        .background(Theme.bgHover)
                        .cornerRadius(5)
                }
                .buttonStyle(.borderless)
                .help("Open in new window")

                // Rename
                Button { onStartRename() } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 26, height: 26)
                        .background(Theme.bgHover)
                        .cornerRadius(5)
                }
                .buttonStyle(.borderless)
                .help("Rename")

                // Remove
                Button {
                    state.removeFromRecents(url)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(.red.opacity(0.7))
                        .frame(width: 26, height: 26)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(5)
                }
                .buttonStyle(.borderless)
                .help("Remove from list")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            isCurrent ? Theme.accent.opacity(0.15) :
            isHovered ? Theme.bgHover : .clear
        )
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            guard !isRenaming else { return }
            state.openProject(at: url)
        }
    }
}

// MARK: - File Tree Panel

private struct FileTreePanel: View {
    @Bindable var state: AppState
    @Environment(\.fontZoom) private var zoom

    var body: some View {
        if let root = state.rootFileItem {
            HStack(spacing: 6) {
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
}

// MARK: - Search Panel

private struct SearchPanel: View {
    @Bindable var state: AppState
    @Environment(\.fontZoom) private var zoom
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search header
            HStack(spacing: 6) {
                Text("SEARCH")
                    .font(.zoomed(size: 10, zoom: zoom, weight: .semibold))
                    .foregroundStyle(Theme.textMuted)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Search input
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)
                TextField("Search", text: $state.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.zoomed(size: 12, zoom: zoom))
                    .foregroundStyle(Theme.textPrimary)
                    .focused($isFocused)
                    .onSubmit { state.performSearch() }
                if !state.searchQuery.isEmpty {
                    Button {
                        state.searchQuery = ""
                        state.searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textMuted)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Theme.bg)
            .cornerRadius(6)
            .padding(.horizontal, 8)

            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)
                .padding(.top, 8)

            // Results
            if state.isSearching {
                VStack(spacing: 8) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Searching...")
                        .font(.zoomed(size: 11, zoom: zoom))
                        .foregroundStyle(Theme.textMuted)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if state.searchResults.isEmpty && !state.searchQuery.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Text("No results found")
                        .font(.zoomed(size: 12, zoom: zoom))
                        .foregroundStyle(Theme.textMuted)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(state.searchResults) { result in
                            SearchResultRow(result: result, state: state)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .onAppear { isFocused = true }
        .onChange(of: state.searchQuery) {
            state.performSearch()
        }
    }
}

private struct SearchResultRow: View {
    let result: SearchResult
    @Bindable var state: AppState
    @Environment(\.fontZoom) private var zoom
    @State private var isHovered = false

    private var highlightedLine: AttributedString {
        let trimmed = result.lineContent.trimmingCharacters(in: .whitespaces)
        let query = state.searchQuery.lowercased()
        var attributed = AttributedString(trimmed)
        attributed.foregroundColor = Color(nsColor: .init(srgbRed: 0.478, green: 0.514, blue: 0.576, alpha: 1))

        let lower = trimmed.lowercased()
        var searchStart = lower.startIndex
        while let range = lower.range(of: query, range: searchStart..<lower.endIndex) {
            if let attrRange = Range(range, in: attributed) {
                attributed[attrRange].foregroundColor = Color(nsColor: .init(srgbRed: 0.322, green: 0.557, blue: 0.918, alpha: 1))
                attributed[attrRange].backgroundColor = Color(nsColor: .init(srgbRed: 0.322, green: 0.557, blue: 0.918, alpha: 0.2))
            }
            searchStart = range.upperBound
        }
        return attributed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(result.fileName)
                    .font(.zoomed(size: 11, zoom: zoom, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(":\(result.lineNumber)")
                    .font(.zoomed(size: 10, zoom: zoom))
                    .foregroundStyle(Theme.textMuted)
                Spacer()
            }
            Text(highlightedLine)
                .font(.zoomed(size: 11, zoom: zoom, design: .monospaced))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(isHovered ? Theme.bgHover : .clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            let file = FileItem(name: result.fileName, url: result.fileURL, isDirectory: false, children: nil)
            state.openFileAtLine(file, line: result.lineNumber, query: state.searchQuery)
        }
    }
}

// MARK: - Git Panel

private struct GitPanel: View {
    @Bindable var state: AppState
    @Environment(\.fontZoom) private var zoom

    private var totalChanges: Int {
        state.gitRepos.reduce(0) { $0 + $1.files.count }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Git header
            HStack(spacing: 6) {
                Text("SOURCE CONTROL")
                    .font(.zoomed(size: 10, zoom: zoom, weight: .semibold))
                    .foregroundStyle(Theme.textMuted)
                Spacer()
                Button {
                    state.refreshGit()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)

            // Commit input
            if !state.gitRepos.isEmpty {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        TextField("Commit message", text: $state.commitMessage, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.zoomed(size: 11, zoom: zoom))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1...3)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Theme.bg)
                            .cornerRadius(6)

                        Button {
                            state.generateCommitMessage()
                        } label: {
                            if state.isGeneratingCommitMsg {
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .buttonStyle(.borderless)
                        .frame(width: 28, height: 28)
                        .background(Theme.bgHover)
                        .cornerRadius(6)
                        .disabled(state.isGeneratingCommitMsg)
                        .help("Generate commit message with AI")
                    }

                    Button {
                        state.commitChanges()
                    } label: {
                        HStack(spacing: 6) {
                            if state.isCommitting {
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .frame(width: 12, height: 12)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11))
                            }
                            Text("Commit")
                                .font(.zoomed(size: 11, zoom: zoom, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            state.commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || state.isCommitting
                                ? Theme.accent.opacity(0.4)
                                : Theme.accent
                        )
                        .cornerRadius(6)
                    }
                    .buttonStyle(.borderless)
                    .disabled(state.commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || state.isCommitting)

                    if let error = state.commitError {
                        Text(error)
                            .font(.zoomed(size: 10, zoom: zoom))
                            .foregroundStyle(.red)
                            .lineLimit(2)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)

                Rectangle()
                    .fill(Theme.border)
                    .frame(height: 1)
            }

            // Status
            if state.isLoadingGit {
                VStack(spacing: 8) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Loading...")
                        .font(.zoomed(size: 11, zoom: zoom))
                        .foregroundStyle(Theme.textMuted)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if state.gitRepos.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.termGreen)
                    Text("No changes")
                        .font(.zoomed(size: 12, zoom: zoom))
                        .foregroundStyle(Theme.textMuted)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(state.gitRepos) { repo in
                            GitRepoSection(repo: repo, state: state)
                        }
                    }
                }
            }
        }
    }
}

private struct GitRepoSection: View {
    let repo: GitRepoStatus
    @Bindable var state: AppState
    @Environment(\.fontZoom) private var zoom
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Repo header
            HStack(spacing: 6) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.zoomed(size: 9, zoom: zoom, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 10)

                Image(systemName: "folder.fill")
                    .font(.zoomed(size: 11, zoom: zoom))
                    .foregroundStyle(Theme.folderBlue)

                Text(repo.name)
                    .font(.zoomed(size: 11, zoom: zoom, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                Text("\(repo.files.count)")
                    .font(.zoomed(size: 10, zoom: zoom))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Theme.bgHover)
                    .cornerRadius(4)

                Spacer()

                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.textMuted)
                Text(repo.branch)
                    .font(.zoomed(size: 10, zoom: zoom))
                    .foregroundStyle(Theme.textMuted)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.bgHeader)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isExpanded.toggle()
                }
            }

            if isExpanded {
                ForEach(repo.files) { file in
                    GitFileRow(file: file, state: state)
                }
            }
        }
    }
}

private struct GitFileRow: View {
    let file: GitFileStatus
    @Bindable var state: AppState
    @Environment(\.fontZoom) private var zoom
    @State private var isHovered = false

    private var statusColor: Color {
        switch file.status {
        case .modified: return .orange
        case .added, .untracked: return Theme.termGreen
        case .deleted: return .red
        case .renamed: return Theme.folderBlue
        case .conflicted: return .red
        }
    }

    private var fileItem: FileItem {
        FileItem(name: file.fullURL.lastPathComponent, url: file.fullURL, isDirectory: false, children: nil)
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(nsImage: FileIconResolver.icon(for: fileItem))
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: 16 * zoom, height: 16 * zoom)
            Text(file.path)
                .font(.zoomed(size: 11, zoom: zoom))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .truncationMode(.head)
            Spacer()
            Text(file.status.label)
                .font(.zoomed(size: 10, zoom: zoom, weight: .bold, design: .monospaced))
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(isHovered ? Theme.bgHover : .clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            state.openDiffFile(file)
        }
    }
}

// MARK: - File Tree Row

private struct FileTreeRow: View {
    let item: FileItem
    @Bindable var state: AppState
    let depth: Int

    @Environment(\.fontZoom) private var zoom
    @State private var isExpanded = false
    @State private var isHovered = false
    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var showDeleteConfirm = false
    @FocusState private var renameFocused: Bool

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

                if isRenaming {
                    TextField("Name", text: $renameText)
                        .textFieldStyle(.plain)
                        .font(.zoomed(size: 12, zoom: zoom))
                        .foregroundStyle(Theme.textPrimary)
                        .focused($renameFocused)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Theme.bg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Theme.accent, lineWidth: 1.5)
                        )
                        .cornerRadius(3)
                        .onSubmit { commitRename() }
                        .onExitCommand { cancelRename() }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                renameFocused = true
                            }
                        }
                } else {
                    Text(item.name)
                        .font(.zoomed(size: 12, zoom: zoom))
                        .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textPrimary.opacity(0.85))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

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
                guard !isRenaming else { return }
                if item.isDirectory {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isExpanded.toggle()
                    }
                } else {
                    state.openFile(item)
                }
            }
            .contextMenu {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([item.url])
                } label: {
                    Label("Reveal in Finder", systemImage: "folder")
                }
                Divider()
                Button {
                    startRename()
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .alert("Delete \"\(item.name)\"?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { deleteItem() }
            } message: {
                Text(item.isDirectory
                     ? "This folder and all its contents will be moved to Trash."
                     : "This file will be moved to Trash.")
            }

            if item.isDirectory && isExpanded, let children = item.children {
                ForEach(children) { child in
                    FileTreeRow(item: child, state: state, depth: depth + 1)
                }
            }
        }
    }

    private func startRename() {
        // Pre-select name without extension for files
        let name = item.name
        if !item.isDirectory, let dotIdx = name.lastIndex(of: "."), dotIdx != name.startIndex {
            renameText = String(name[..<dotIdx])
        } else {
            renameText = name
        }
        // Actually use full name so user sees extension
        renameText = name
        isRenaming = true
    }

    private func commitRename() {
        let newName = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        isRenaming = false
        guard !newName.isEmpty, newName != item.name else { return }
        let newURL = item.url.deletingLastPathComponent().appendingPathComponent(newName)
        do {
            try FileManager.default.moveItem(at: item.url, to: newURL)
            // Reload the file tree
            if let root = state.projectURL {
                Task.detached {
                    let tree = FileService.loadDirectory(at: root)
                    await MainActor.run { state.rootFileItem = tree }
                }
            }
        } catch {
            // Rename failed — ignore silently
        }
    }

    private func cancelRename() {
        isRenaming = false
    }

    private func deleteItem() {
        do {
            try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
            // Close any open tab for this file
            state.openEditorTabs.removeAll { $0.file.url == item.url }
            // Reload file tree
            if let root = state.projectURL {
                Task.detached {
                    let tree = FileService.loadDirectory(at: root)
                    await MainActor.run { state.rootFileItem = tree }
                }
            }
        } catch {
            // Delete failed — ignore silently
        }
    }
}
