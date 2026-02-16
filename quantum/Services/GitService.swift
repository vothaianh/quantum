import Foundation

enum GitService {
    static func findGitRoot(from url: URL) -> URL? {
        let output = run(["git", "rev-parse", "--show-toplevel"], at: url)
        let path = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path)
    }

    static func currentBranch(at root: URL) -> String {
        let gitRoot = findGitRoot(from: root) ?? root
        let output = run(["git", "rev-parse", "--abbrev-ref", "HEAD"], at: gitRoot)
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Multi-repo scanning

    /// Discover all git repos at `projectRoot` and its immediate subdirectories.
    /// Uses `.git` directory check instead of spawning processes for discovery.
    static func statusAllRepos(at projectRoot: URL) -> [GitRepoStatus] {
        var repos: [GitRepoStatus] = []
        let fm = FileManager.default

        // Check if project root itself is a git repo (fast filesystem check)
        let rootGitDir = projectRoot.appendingPathComponent(".git")
        if fm.fileExists(atPath: rootGitDir.path) {
            let repo = repoStatusFast(at: projectRoot, name: projectRoot.lastPathComponent)
            if !repo.files.isEmpty {
                repos.append(repo)
            }
            return repos  // Root is a repo — subdirs are part of it, skip scanning
        }

        // Scan immediate subdirectories for .git dirs
        guard let children = try? fm.contentsOfDirectory(
            at: projectRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return repos }

        for child in children {
            guard (try? child.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else { continue }
            let childGitDir = child.appendingPathComponent(".git")
            guard fm.fileExists(atPath: childGitDir.path) else { continue }
            let repo = repoStatusFast(at: child, name: child.lastPathComponent)
            if !repo.files.isEmpty {
                repos.append(repo)
            }
        }

        return repos
    }

    /// Get repo status without redundant findGitRoot calls — we already know the root.
    private static func repoStatusFast(at gitRoot: URL, name: String) -> GitRepoStatus {
        let branchOutput = run(["git", "rev-parse", "--abbrev-ref", "HEAD"], at: gitRoot)
        let branch = branchOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        let files = statusFast(at: gitRoot)
        return GitRepoStatus(name: name, branch: branch, files: files, gitRoot: gitRoot)
    }

    /// Parse git status without calling findGitRoot again.
    private static func statusFast(at gitRoot: URL) -> [GitFileStatus] {
        let output = run(["git", "status", "--porcelain=v1"], at: gitRoot)
        guard !output.isEmpty else { return [] }

        return output.components(separatedBy: "\n").compactMap { line in
            guard line.count >= 4 else { return nil }
            let xy = line.prefix(2)
            let path = String(line.dropFirst(3))
            guard !path.isEmpty else { return nil }

            let x = xy[xy.startIndex]
            let y = xy[xy.index(after: xy.startIndex)]

            let status: GitFileStatus.GitStatus
            if x == "?" || y == "?" { status = .untracked }
            else if x == "U" || y == "U" { status = .conflicted }
            else if x == "D" || y == "D" { status = .deleted }
            else if x == "R" { status = .renamed }
            else if x == "A" { status = .added }
            else { status = .modified }

            return GitFileStatus(
                path: path,
                status: status,
                fullURL: gitRoot.appendingPathComponent(path)
            )
        }
    }

    static func status(at root: URL) -> [GitFileStatus] {
        let gitRoot = findGitRoot(from: root) ?? root
        let output = run(["git", "status", "--porcelain=v1"], at: gitRoot)
        guard !output.isEmpty else { return [] }

        return output.components(separatedBy: "\n").compactMap { line in
            guard line.count >= 4 else { return nil }
            let xy = line.prefix(2)
            let path = String(line.dropFirst(3))
            guard !path.isEmpty else { return nil }

            let statusChar: Character
            let x = xy[xy.startIndex]
            let y = xy[xy.index(after: xy.startIndex)]

            if x == "?" || y == "?" {
                statusChar = "?"
            } else if x == "U" || y == "U" {
                statusChar = "U"
            } else if x == "D" || y == "D" {
                statusChar = "D"
            } else if x == "R" {
                statusChar = "R"
            } else if x == "A" {
                statusChar = "A"
            } else {
                statusChar = "M"
            }

            let status: GitFileStatus.GitStatus
            switch statusChar {
            case "M": status = .modified
            case "A": status = .added
            case "D": status = .deleted
            case "R": status = .renamed
            case "U": status = .conflicted
            default: status = .untracked
            }

            return GitFileStatus(
                path: path,
                status: status,
                fullURL: gitRoot.appendingPathComponent(path)
            )
        }
    }

    static func diff(at root: URL) -> String {
        let gitRoot = findGitRoot(from: root) ?? root
        // Staged + unstaged diff
        let staged = run(["git", "diff", "--cached"], at: gitRoot)
        let unstaged = run(["git", "diff"], at: gitRoot)
        // Also list untracked files
        let untracked = run(["git", "ls-files", "--others", "--exclude-standard"], at: gitRoot)
        var result = ""
        if !staged.isEmpty { result += staged }
        if !unstaged.isEmpty { result += unstaged }
        if !untracked.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result += "\nNew untracked files:\n\(untracked)"
        }
        return result
    }

    static func commitAll(message: String, at root: URL) -> (success: Bool, output: String) {
        let gitRoot = findGitRoot(from: root) ?? root
        // Stage all changes
        let addResult = runWithStatus(["git", "add", "-A"], at: gitRoot)
        debugLog("COMMIT ADD gitRoot=\(gitRoot.path) exitCode=\(addResult.exitCode) output=\(addResult.output)")
        // Commit
        let commitResult = runWithStatus(["git", "commit", "-m", message], at: gitRoot)
        debugLog("COMMIT gitRoot=\(gitRoot.path) exitCode=\(commitResult.exitCode) output=\(commitResult.output)")
        let success = commitResult.exitCode == 0
        return (success, commitResult.output.isEmpty ? addResult.output : commitResult.output)
    }

    static func pull(at root: URL) -> (success: Bool, output: String) {
        let gitRoot = findGitRoot(from: root) ?? root
        let result = runWithStatus(["git", "pull", "--rebase"], at: gitRoot)
        let output = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        let success = result.exitCode == 0
        debugLog("PULL gitRoot=\(gitRoot.path) exitCode=\(result.exitCode) success=\(success) output=\(result.output)")
        return (success, output)
    }

    static func push(at root: URL) -> (success: Bool, output: String) {
        let gitRoot = findGitRoot(from: root) ?? root
        let result = runWithStatus(["git", "push"], at: gitRoot)
        let output = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        let success = result.exitCode == 0
        debugLog("PUSH gitRoot=\(gitRoot.path) exitCode=\(result.exitCode) success=\(success) output=\(result.output)")
        return (success, output)
    }

    /// Discard changes for a single file
    static func discardFile(_ file: GitFileStatus, at gitRoot: URL) {
        let rootPath = gitRoot.path.hasSuffix("/") ? gitRoot.path : gitRoot.path + "/"
        let filePath = file.fullURL.path
        let relativePath = filePath.hasPrefix(rootPath) ? String(filePath.dropFirst(rootPath.count)) : file.path

        if file.status == .untracked {
            // Remove untracked file
            try? FileManager.default.removeItem(at: file.fullURL)
        } else {
            // Restore tracked file
            _ = run(["git", "checkout", "HEAD", "--", relativePath], at: gitRoot)
        }
    }

    /// Discard all changes in a repo
    static func discardAll(at gitRoot: URL) {
        // Restore all tracked files
        _ = run(["git", "checkout", "HEAD", "--", "."], at: gitRoot)
        // Remove untracked files
        _ = run(["git", "clean", "-fd"], at: gitRoot)
    }

    // MARK: - Fetch

    @discardableResult
    static func fetch(at root: URL) -> Bool {
        let gitRoot = findGitRoot(from: root) ?? root
        let result = runWithStatus(["git", "fetch", "--quiet"], at: gitRoot)
        return result.exitCode == 0
    }

    // MARK: - Git Log

    private static let logSep = "‖"
    private static let logFormat = "%h‖%H‖%s‖%an‖%aI‖%ar"

    static func log(at root: URL, count: Int = 50) -> [GitCommitLog] {
        let gitRoot = findGitRoot(from: root) ?? root
        let output = run(["git", "log", "--pretty=format:\(logFormat)", "-n", "\(count)"], at: gitRoot)
        return parseLogOutput(output)
    }

    static func unpulledCommits(at root: URL) -> [GitCommitLog] {
        let gitRoot = findGitRoot(from: root) ?? root
        // Find the upstream tracking branch
        let upstream = run(["git", "rev-parse", "--abbrev-ref", "@{upstream}"], at: gitRoot)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !upstream.isEmpty, !upstream.contains("fatal") else { return [] }
        // Commits on remote not yet in local HEAD
        let output = run(["git", "log", "HEAD..\(upstream)", "--pretty=format:\(logFormat)"], at: gitRoot)
        var commits = parseLogOutput(output)
        for i in commits.indices { commits[i].isRemoteOnly = true }
        return commits
    }

    private static func parseLogOutput(_ output: String) -> [GitCommitLog] {
        guard !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }

        let isoFull = ISO8601DateFormatter()
        isoFull.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoBasic = ISO8601DateFormatter()
        isoBasic.formatOptions = [.withInternetDateTime]

        return output.components(separatedBy: "\n").compactMap { line in
            let parts = line.components(separatedBy: logSep)
            guard parts.count >= 6 else { return nil }
            let hash = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let fullHash = parts[1]
            let message = parts[2]
            let author = parts[3]
            let dateStr = parts[4]
            let relDate = parts[5]
            let date = isoFull.date(from: dateStr)
                ?? isoBasic.date(from: dateStr)
                ?? Date.distantPast
            return GitCommitLog(
                id: hash, fullHash: fullHash, message: message,
                author: author, date: date, relativeDate: relDate
            )
        }
    }

    static func showHEAD(relativePath: String, at root: URL) -> String? {
        let gitRoot = findGitRoot(from: root) ?? root
        let output = run(["git", "show", "HEAD:\(relativePath)"], at: gitRoot)
        // Empty output means file doesn't exist in HEAD (new/untracked)
        guard !output.isEmpty else { return nil }
        return output
    }

    private static let logFile: URL = {
        let path = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("quantum_debug.log")
        // Clear on launch
        try? "".write(to: path, atomically: true, encoding: .utf8)
        return path
    }()

    static func debugLog(_ message: String) {
        let ts = ISO8601DateFormatter().string(from: Date())
        let line = "[\(ts)] \(message)\n"
        if let data = line.data(using: .utf8),
           let fh = try? FileHandle(forWritingTo: logFile) {
            fh.seekToEndOfFile()
            fh.write(data)
            fh.closeFile()
        } else {
            try? line.write(to: logFile, atomically: false, encoding: .utf8)
        }
    }

    private static func run(_ args: [String], at directory: URL) -> String {
        runWithStatus(args, at: directory).output
    }

    private static func runWithStatus(_ args: [String], at directory: URL) -> (output: String, exitCode: Int32) {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        let gitPath = FileManager.default.fileExists(atPath: "/usr/bin/git")
            ? "/usr/bin/git" : "/usr/local/bin/git"
        process.executableURL = URL(fileURLWithPath: gitPath)
        process.arguments = Array(args.dropFirst())
        process.currentDirectoryURL = directory
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        do {
            try process.run()
            // Read both pipes concurrently to avoid deadlock
            var outData = Data()
            var errData = Data()
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.global().async {
                outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                group.leave()
            }
            group.enter()
            DispatchQueue.global().async {
                errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                group.leave()
            }
            group.wait()
            process.waitUntilExit()
            let out = String(data: outData, encoding: .utf8) ?? ""
            let err = String(data: errData, encoding: .utf8) ?? ""
            let combined = [out, err].filter { !$0.isEmpty }.joined(separator: "\n")
            debugLog("RUN args=\(args) dir=\(directory.path) exit=\(process.terminationStatus) stdout=[\(out.prefix(200))] stderr=[\(err.prefix(200))]")
            return (combined, process.terminationStatus)
        } catch {
            return ("", 1)
        }
    }
}
