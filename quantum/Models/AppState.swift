import Foundation

@Observable
final class AppState {
    var rootFileItem: FileItem?
    var selectedFile: FileItem?
    var fileContent: String = ""
    var terminalTabs: [TerminalTab] = []
    var selectedTerminalTabID: UUID?
    var showSidebar: Bool = true
    var showTerminal: Bool = true
    var projectURL: URL?
    var zoomLevel: Double = 1.0

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

    var selectedTerminalTab: TerminalTab? {
        guard let id = selectedTerminalTabID else { return terminalTabs.first }
        return terminalTabs.first { $0.id == id }
    }

    // MARK: - Recent Projects

    private static let recentProjectsKey = "recentProjects"
    private static let maxRecents = 10

    var recentProjects: [URL] {
        get {
            guard let bookmarks = UserDefaults.standard.array(forKey: Self.recentProjectsKey) as? [Data] else {
                return []
            }
            return bookmarks.compactMap { data in
                var stale = false
                return try? URL(resolvingBookmarkData: data, options: .withSecurityScope, bookmarkDataIsStale: &stale)
            }
        }
        set {
            let bookmarks = newValue.prefix(Self.maxRecents).compactMap { url in
                try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            }
            UserDefaults.standard.set(Array(bookmarks), forKey: Self.recentProjectsKey)
        }
    }

    func addToRecents(_ url: URL) {
        var recents = recentProjects
        recents.removeAll { $0.path == url.path }
        recents.insert(url, at: 0)
        recentProjects = Array(recents.prefix(Self.maxRecents))
    }

    func removeFromRecents(_ url: URL) {
        var recents = recentProjects
        recents.removeAll { $0.path == url.path }
        recentProjects = recents
    }

    func openProject(at url: URL) {
        terminalTabs.removeAll()

        projectURL = url
        rootFileItem = nil
        selectedFile = nil
        fileContent = ""
        addToRecents(url)

        // Spawn default terminal
        let tab = TerminalTab(workingDirectory: url)
        terminalTabs.append(tab)
        selectedTerminalTabID = tab.id

        // Load directory tree off main thread
        Task.detached {
            let root = FileService.loadDirectory(at: url)
            await MainActor.run {
                self.rootFileItem = root
            }
        }
    }
}
