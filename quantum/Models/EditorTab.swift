import Foundation

struct EditorTab: Identifiable {
    let id = UUID()
    let file: FileItem
    var content: String
    var isModified: Bool = false
    var diffOriginalContent: String?
    var pendingGoToLine: Int?        // 1-based line number to scroll to
    var pendingSearchQuery: String?  // keyword to highlight on that line

    var isDiff: Bool { diffOriginalContent != nil }
}
