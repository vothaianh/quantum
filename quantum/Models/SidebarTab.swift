import Foundation

enum SidebarTab: String, CaseIterable {
    case projects
    case files
    case search
    case git
}

struct SearchResult: Identifiable {
    let id = UUID()
    let fileURL: URL
    let fileName: String
    let lineNumber: Int
    let lineContent: String
    let matchRange: Range<String.Index>?
}

struct GitRepoStatus: Identifiable {
    let id = UUID()
    let name: String
    let branch: String
    let files: [GitFileStatus]
    let gitRoot: URL
}

struct GitFileStatus: Identifiable {
    let id = UUID()
    let path: String
    let status: GitStatus
    let fullURL: URL

    enum GitStatus: String {
        case modified = "M"
        case added = "A"
        case deleted = "D"
        case renamed = "R"
        case untracked = "?"
        case conflicted = "U"

        var label: String {
            switch self {
            case .modified: return "M"
            case .added: return "A"
            case .deleted: return "D"
            case .renamed: return "R"
            case .untracked: return "U"
            case .conflicted: return "C"
            }
        }

        var color: String {
            switch self {
            case .modified: return "modified"
            case .added, .untracked: return "added"
            case .deleted: return "deleted"
            case .renamed: return "renamed"
            case .conflicted: return "conflicted"
            }
        }
    }
}
