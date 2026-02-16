import Foundation

// MARK: - Indexed file entry

struct IndexedFile: Sendable {
    let url: URL
    let name: String
    let lines: [String]        // original lines for display
    let lowerData: Data        // entire file content lowercased as raw bytes
    let lineStarts: [Int]      // byte offset of each line start in lowerData
}

// MARK: - Search Index (incremental, background)

final class SearchIndex: @unchecked Sendable {
    static let shared = SearchIndex()

    private let lock = NSLock()
    private var files: [IndexedFile] = []
    private var isBuilding = false
    private var generation = 0          // bumped on invalidate to cancel stale builds

    private init() {}

    /// Returns current snapshot — may be partial while building.
    func getFiles() -> [IndexedFile] {
        lock.lock()
        let f = files
        lock.unlock()
        return f
    }

    var isReady: Bool {
        lock.lock()
        let ready = !files.isEmpty || !isBuilding
        lock.unlock()
        return ready
    }

    var indexing: Bool {
        lock.lock()
        let b = isBuilding
        lock.unlock()
        return b
    }

    func buildIndex(for root: URL) {
        lock.lock()
        generation += 1
        let gen = generation
        files = []
        isBuilding = true
        lock.unlock()

        // Run on a low-priority background queue so it doesn't slow down the UI
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.scan(root: root, generation: gen)
        }
    }

    func invalidate() {
        lock.lock()
        generation += 1
        files = []
        isBuilding = false
        lock.unlock()
    }

    // MARK: - Incremental scanner

    private static let skipDirs: Set<String> = [
        "node_modules", ".git", ".svn", ".hg", ".DS_Store",
        "build", "Build", "DerivedData", ".build",
        "Pods", ".cocoapods", "Carthage",
        ".gradle", ".idea", ".vscode",
        "target", "dist", "out", ".output",
        "__pycache__", ".pytest_cache", ".mypy_cache",
        ".next", ".nuxt", ".vercel",
        "vendor", "bower_components",
        ".cache", ".parcel-cache", ".turbo",
        "coverage", ".nyc_output", "xcuserdata",
    ]

    private static let binaryExts: Set<String> = [
        "png", "jpg", "jpeg", "gif", "bmp", "ico", "webp", "svg",
        "mp4", "mov", "avi", "mp3", "wav", "flac",
        "zip", "tar", "gz", "rar", "7z",
        "exe", "dll", "so", "dylib", "o", "a",
        "ttf", "otf", "woff", "woff2",
        "pdf", "psd", "db", "sqlite", "sqlite3",
    ]

    private func scan(root: URL, generation gen: Int) {
        var stack: [URL] = [root]
        let fm = FileManager.default
        let newline = UInt8(0x0A)
        var batch: [IndexedFile] = []

        while let dir = stack.popLast() {
            // Check if this build was cancelled
            lock.lock()
            let cancelled = generation != gen
            lock.unlock()
            if cancelled { return }

            guard let contents = try? fm.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: [.isDirectoryKey],
                options: []
            ) else { continue }

            for url in contents {
                let name = url.lastPathComponent
                let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                if isDir {
                    if !Self.skipDirs.contains(name) { stack.append(url) }
                    continue
                }
                if name == ".DS_Store" { continue }
                if Self.binaryExts.contains(url.pathExtension.lowercased()) { continue }
                guard let data = try? Data(contentsOf: url, options: .mappedIfSafe),
                      data.count < 500_000,
                      let content = String(data: data, encoding: .utf8) else { continue }

                let lower = content.lowercased()
                let lowerData = Data(lower.utf8)

                var lines: [String] = []
                var lineStarts: [Int] = [0]
                content.enumerateLines { line, _ in
                    lines.append(line.count > 300 ? String(line.prefix(300)) : line)
                }
                lowerData.withUnsafeBytes { buf in
                    let ptr = buf.bindMemory(to: UInt8.self)
                    for i in 0..<ptr.count {
                        if ptr[i] == newline {
                            lineStarts.append(i + 1)
                        }
                    }
                }

                batch.append(IndexedFile(url: url, name: name, lines: lines, lowerData: lowerData, lineStarts: lineStarts))

                // Flush batch every 50 files so search works incrementally
                if batch.count >= 50 {
                    lock.lock()
                    if generation == gen {
                        files.append(contentsOf: batch)
                    }
                    lock.unlock()
                    batch.removeAll(keepingCapacity: true)
                }
            }
        }

        // Flush remaining
        lock.lock()
        if generation == gen {
            files.append(contentsOf: batch)
            isBuilding = false
        }
        lock.unlock()
    }
}

// MARK: - Search Service

enum SearchService {
    static func search(query: String, files: [IndexedFile], maxResults: Int = 100) -> [SearchResult] {
        let needle = Data(query.lowercased().utf8)
        guard !needle.isEmpty else { return [] }
        var results: [SearchResult] = []

        for file in files {
            if results.count >= maxResults { break }
            let haystack = file.lowerData
            let starts = file.lineStarts
            var pos = haystack.startIndex

            while pos < haystack.endIndex, results.count < maxResults {
                guard let range = haystack.range(of: needle, in: pos..<haystack.endIndex) else { break }

                // Binary search to find line index from byte offset
                let byteOff = range.lowerBound
                var lo = 0, hi = starts.count - 1
                while lo < hi {
                    let mid = (lo + hi + 1) / 2
                    if starts[mid] <= byteOff { lo = mid } else { hi = mid - 1 }
                }
                let lineIdx = lo

                if lineIdx < file.lines.count {
                    results.append(SearchResult(
                        fileURL: file.url,
                        fileName: file.name,
                        lineNumber: lineIdx + 1,
                        lineContent: file.lines[lineIdx],
                        matchRange: nil
                    ))
                }

                // Jump to next line to avoid duplicate matches on same line
                if lineIdx + 1 < starts.count {
                    pos = starts[lineIdx + 1]
                } else {
                    break
                }
            }
        }
        return results
    }
}
