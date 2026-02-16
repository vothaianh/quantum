import Foundation

struct FileService {

    nonisolated(unsafe) private static let skippedDirectories: Set<String> = [
        "node_modules", ".git", ".svn", ".hg", ".DS_Store",
        "build", "Build", "DerivedData", ".build",
        "Pods", ".cocoapods", "Carthage",
        ".gradle", ".idea", ".vscode",
        "target", "dist", "out", ".output",
        "__pycache__", ".pytest_cache", ".mypy_cache",
        ".next", ".nuxt", ".vercel",
        "vendor", "bower_components",
        ".cache", ".parcel-cache", ".turbo",
        "coverage", ".nyc_output",
        ".sass-cache", ".tmp", "tmp",
        "xcuserdata",
    ]

    nonisolated static func loadDirectory(at url: URL, depth: Int = 0, maxDepth: Int = 20) -> FileItem {
        guard depth < maxDepth else {
            return FileItem(name: url.lastPathComponent, url: url, isDirectory: true, children: [])
        }

        let fm = FileManager.default
        var children: [FileItem] = []

        if let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        ) {
            for itemURL in contents {
                let name = itemURL.lastPathComponent
                let isDir = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false

                if isDir {
                    if skippedDirectories.contains(name) { continue }
                    let child = loadDirectory(at: itemURL, depth: depth + 1, maxDepth: maxDepth)
                    children.append(child)
                } else {
                    if name == ".DS_Store" { continue }
                    children.append(FileItem(name: name, url: itemURL, isDirectory: false, children: nil))
                }
            }
        }

        // Sort: directories first, then alphabetical
        children.sort { a, b in
            if a.isDirectory != b.isDirectory { return a.isDirectory }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }

        return FileItem(name: url.lastPathComponent, url: url, isDirectory: true, children: children)
    }

    nonisolated static func readFile(at url: URL) -> String {
        (try? String(contentsOf: url, encoding: .utf8)) ?? "[Unable to read file]"
    }
}
