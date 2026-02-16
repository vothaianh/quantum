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
        let addOutput = run(["git", "add", "-A"], at: gitRoot)
        // Commit
        let commitOutput = run(["git", "commit", "-m", message], at: gitRoot)
        let success = commitOutput.contains("file changed") ||
                      commitOutput.contains("files changed") ||
                      commitOutput.contains("insertions") ||
                      commitOutput.contains("deletions") ||
                      commitOutput.contains("create mode")
        return (success, commitOutput.isEmpty ? addOutput : commitOutput)
    }

    static func showHEAD(relativePath: String, at root: URL) -> String? {
        let gitRoot = findGitRoot(from: root) ?? root
        let output = run(["git", "show", "HEAD:\(relativePath)"], at: gitRoot)
        // Empty output means file doesn't exist in HEAD (new/untracked)
        guard !output.isEmpty else { return nil }
        return output
    }

    private static func run(_ args: [String], at directory: URL) -> String {
        let process = Process()
        let pipe = Pipe()
        // Use git directly — /usr/bin/env may not find it in GUI apps
        let gitPath = FileManager.default.fileExists(atPath: "/usr/bin/git")
            ? "/usr/bin/git" : "/usr/local/bin/git"
        process.executableURL = URL(fileURLWithPath: gitPath)
        process.arguments = Array(args.dropFirst()) // drop "git" from args
        process.currentDirectoryURL = directory
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}
