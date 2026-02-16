import Foundation
import AppKit

@Observable
final class AppState {
    var rootFileItem: FileItem?
    var openEditorTabs: [EditorTab] = []
    var selectedEditorTabID: UUID?
    var terminalTabs: [TerminalTab] = []
    var selectedTerminalTabID: UUID?
    var showSidebar: Bool = true
    var showTerminal: Bool = true
    var projectURL: URL?
    var zoomLevel: Double = 1.0
    var sidebarTab: SidebarTab = .files
    var searchQuery: String = ""
    var searchResults: [SearchResult] = []
    var isSearching: Bool = false
    var gitRepos: [GitRepoStatus] = []
    var gitBranch: String = ""
    var isLoadingGit: Bool = false
    var commitMessage: String = ""
    var isGeneratingCommitMsg: Bool = false
    var isCommitting: Bool = false
    var commitError: String?

    // MARK: - Search

    func performSearch() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        // Search whatever is indexed so far — synchronous, Data.range(of:) is C-fast
        let files = SearchIndex.shared.getFiles()
        searchResults = SearchService.search(query: searchQuery, files: files)
        isSearching = false
    }

    // MARK: - Git

    func refreshGit() {
        guard let projectURL else { return }
        isLoadingGit = true
        let root = projectURL
        Task.detached {
            let repos = GitService.statusAllRepos(at: root)
            let branch = repos.first?.branch ?? GitService.currentBranch(at: root)
            await MainActor.run {
                self.gitRepos = repos
                self.gitBranch = branch
                self.isLoadingGit = false
            }
        }
    }

    func refreshGitBranchForCurrentFile() {
        guard let fileURL = selectedFile?.url else {
            gitBranch = ""
            return
        }
        let dir = fileURL.deletingLastPathComponent()
        Task.detached {
            let branch = GitService.currentBranch(at: dir)
            await MainActor.run {
                self.gitBranch = branch
            }
        }
    }

    func generateCommitMessage() {
        guard !gitRepos.isEmpty else { return }
        let modelID = AppSettings.shared.resolvedModelID
        guard !modelID.isEmpty else {
            commitError = "No AI model configured. Add an API key in Settings."
            return
        }
        isGeneratingCommitMsg = true
        commitError = nil
        let roots = gitRepos.map(\.gitRoot)
        Task.detached {
            do {
                var allDiffs = ""
                for root in roots {
                    let diff = GitService.diff(at: root)
                    if !diff.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        allDiffs += "[\(root.lastPathComponent)]\n\(diff)\n"
                    }
                }
                guard !allDiffs.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    await MainActor.run {
                        self.commitError = "No changes to describe"
                        self.isGeneratingCommitMsg = false
                    }
                    return
                }
                let message = try await AIService.generateCommitMessage(diff: allDiffs, modelID: modelID)
                await MainActor.run {
                    self.commitMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.isGeneratingCommitMsg = false
                }
            } catch {
                await MainActor.run {
                    self.commitError = error.localizedDescription
                    self.isGeneratingCommitMsg = false
                }
            }
        }
    }

    func commitChanges() {
        guard !gitRepos.isEmpty else { return }
        let message = commitMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else {
            commitError = "Commit message cannot be empty"
            return
        }
        isCommitting = true
        commitError = nil
        let roots = gitRepos.map(\.gitRoot)
        Task.detached {
            var allSuccess = true
            var allOutput = ""
            for root in roots {
                let result = GitService.commitAll(message: message, at: root)
                if !result.success { allSuccess = false }
                if !result.output.isEmpty {
                    allOutput += "[\(root.lastPathComponent)] \(result.output)\n"
                }
            }
            await MainActor.run {
                self.isCommitting = false
                if allSuccess {
                    self.commitMessage = ""
                    self.refreshGit()
                } else {
                    self.commitError = allOutput.isEmpty ? "Commit failed" : allOutput
                }
            }
        }
    }

    private static let zoomKey = "zoomLevel"
    private static let zoomStep = 0.1
    private static let zoomMin = 0.5
    private static let zoomMax = 2.0

    func zoomIn() {
        zoomLevel = min(zoomLevel + Self.zoomStep, Self.zoomMax)
        UserDefaults.standard.set(zoomLevel, forKey: Self.zoomKey)
    }

    func zoomOut() {
        zoomLevel = max(zoomLevel - Self.zoomStep, Self.zoomMin)
        UserDefaults.standard.set(zoomLevel, forKey: Self.zoomKey)
    }

    func zoomReset() {
        zoomLevel = 1.0
        UserDefaults.standard.set(zoomLevel, forKey: Self.zoomKey)
    }

    func loadZoom() {
        let saved = UserDefaults.standard.double(forKey: Self.zoomKey)
        if saved >= Self.zoomMin && saved <= Self.zoomMax {
            zoomLevel = saved
        }
    }

    // MARK: - Editor Tabs

    var selectedEditorTab: EditorTab? {
        guard let id = selectedEditorTabID else { return openEditorTabs.first }
        return openEditorTabs.first { $0.id == id }
    }

    var selectedFile: FileItem? { selectedEditorTab?.file }
    var fileContent: String { selectedEditorTab?.content ?? "" }

    func openFile(_ file: FileItem) {
        // If already open, just select it
        if let existing = openEditorTabs.first(where: { $0.file.url == file.url }) {
            selectedEditorTabID = existing.id
            refreshGitBranchForCurrentFile()
            return
        }
        let content = FileService.readFile(at: file.url)
        let tab = EditorTab(file: file, content: content)
        openEditorTabs.append(tab)
        selectedEditorTabID = tab.id
        refreshGitBranchForCurrentFile()
    }

    func openFileAtLine(_ file: FileItem, line: Int, query: String?) {
        // If already open, select it and set pending go-to
        if let idx = openEditorTabs.firstIndex(where: { $0.file.url == file.url && !$0.isDiff }) {
            selectedEditorTabID = openEditorTabs[idx].id
            openEditorTabs[idx].pendingGoToLine = line
            openEditorTabs[idx].pendingSearchQuery = query
            refreshGitBranchForCurrentFile()
            return
        }
        let content = FileService.readFile(at: file.url)
        var tab = EditorTab(file: file, content: content)
        tab.pendingGoToLine = line
        tab.pendingSearchQuery = query
        openEditorTabs.append(tab)
        selectedEditorTabID = tab.id
        refreshGitBranchForCurrentFile()
    }

    func openDiffFile(_ gitFile: GitFileStatus) {
        let fileURL = gitFile.fullURL

        // Untracked/added files have no HEAD version — open normally
        guard gitFile.status == .modified || gitFile.status == .renamed else {
            let name = fileURL.lastPathComponent
            let item = FileItem(name: name, url: fileURL, isDirectory: false, children: nil)
            openFile(item)
            return
        }

        // If a diff tab for this file is already open, select it
        if let existing = openEditorTabs.first(where: { $0.file.url == fileURL && $0.isDiff }) {
            selectedEditorTabID = existing.id
            return
        }

        // Close any non-diff tab for the same file
        openEditorTabs.removeAll { $0.file.url == fileURL && !$0.isDiff }

        let currentContent = FileService.readFile(at: fileURL)

        // Find git root and relative path
        let dir = fileURL.deletingLastPathComponent()
        guard let gitRoot = GitService.findGitRoot(from: dir) else {
            let item = FileItem(name: fileURL.lastPathComponent, url: fileURL, isDirectory: false, children: nil)
            openFile(item)
            return
        }

        let rootPath = gitRoot.path.hasSuffix("/") ? gitRoot.path : gitRoot.path + "/"
        let filePath = fileURL.path
        guard filePath.hasPrefix(rootPath) else {
            let item = FileItem(name: fileURL.lastPathComponent, url: fileURL, isDirectory: false, children: nil)
            openFile(item)
            return
        }
        let relativePath = String(filePath.dropFirst(rootPath.count))

        let original = GitService.showHEAD(relativePath: relativePath, at: gitRoot)
        guard let original else {
            let item = FileItem(name: fileURL.lastPathComponent, url: fileURL, isDirectory: false, children: nil)
            openFile(item)
            return
        }

        let file = FileItem(name: fileURL.lastPathComponent, url: fileURL, isDirectory: false, children: nil)
        let tab = EditorTab(file: file, content: currentContent, diffOriginalContent: original)
        openEditorTabs.append(tab)
        selectedEditorTabID = tab.id
    }

    func closeEditorTab(_ tab: EditorTab) {
        openEditorTabs.removeAll { $0.id == tab.id }
        if selectedEditorTabID == tab.id {
            selectedEditorTabID = openEditorTabs.last?.id
        }
    }

    // MARK: - Terminal Tabs

    var selectedTerminalTab: TerminalTab? {
        guard let id = selectedTerminalTabID else { return terminalTabs.first }
        return terminalTabs.first { $0.id == id }
    }

    // MARK: - Recent Projects

    private static let recentProjectsKey = "recentProjects"
    private static let maxRecents = 10

    var recentProjects: [URL] = []

    func loadRecents() {
        guard let bookmarks = UserDefaults.standard.array(forKey: Self.recentProjectsKey) as? [Data] else {
            recentProjects = []
            return
        }
        recentProjects = bookmarks.compactMap { data in
            var stale = false
            return try? URL(resolvingBookmarkData: data, options: .withSecurityScope, bookmarkDataIsStale: &stale)
        }
    }

    private func saveRecents() {
        let bookmarks = recentProjects.prefix(Self.maxRecents).compactMap { url in
            try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        }
        UserDefaults.standard.set(Array(bookmarks), forKey: Self.recentProjectsKey)
    }

    func addToRecents(_ url: URL) {
        // If already in list, keep its position
        if recentProjects.contains(where: { $0.path == url.path }) { return }
        recentProjects.append(url)
        if recentProjects.count > Self.maxRecents {
            recentProjects = Array(recentProjects.prefix(Self.maxRecents))
        }
        saveRecents()
    }

    func removeFromRecents(_ url: URL) {
        recentProjects.removeAll { $0.path == url.path }
        saveRecents()
        // Also remove custom name
        var names = Self.projectNames
        names.removeValue(forKey: url.path)
        Self.projectNames = names
    }

    // MARK: - Project Names

    private static let projectNamesKey = "projectCustomNames"

    static var projectNames: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: projectNamesKey) as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: projectNamesKey) }
    }

    func displayName(for url: URL) -> String {
        Self.projectNames[url.path] ?? url.lastPathComponent
    }

    func renameProject(_ url: URL, to name: String) {
        var names = Self.projectNames
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == url.lastPathComponent {
            names.removeValue(forKey: url.path)
        } else {
            names[url.path] = trimmed
        }
        Self.projectNames = names
    }

    func openProjectInNewWindow(_ url: URL) {
        // Launch a new instance of the app with the project path as argument
        guard let appURL = Bundle.main.bundleURL as URL? else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        config.arguments = [url.path]
        NSWorkspace.shared.openApplication(at: appURL, configuration: config)
    }

    func restoreLastProject() {
        guard projectURL == nil, let last = recentProjects.first else { return }
        let didAccess = last.startAccessingSecurityScopedResource()
        defer { if didAccess { last.stopAccessingSecurityScopedResource() } }
        guard FileManager.default.fileExists(atPath: last.path) else { return }
        openProject(at: last)
    }

    func openProject(at url: URL) {
        terminalTabs.removeAll()
        openEditorTabs.removeAll()
        selectedEditorTabID = nil

        projectURL = url
        rootFileItem = nil
        addToRecents(url)

        // Spawn default terminal
        let tab = TerminalTab(workingDirectory: url)
        terminalTabs.append(tab)
        selectedTerminalTabID = tab.id

        // Build search index in background
        SearchIndex.shared.invalidate()
        Task.detached { SearchIndex.shared.buildIndex(for: url) }

        // Load directory tree off main thread
        Task.detached {
            let root = FileService.loadDirectory(at: url)
            await MainActor.run {
                self.rootFileItem = root
            }
        }

        refreshGit()
    }
}
