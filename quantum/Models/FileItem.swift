import Foundation
import AppKit

struct FileItem: Identifiable, Hashable, Sendable {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    var children: [FileItem]?
}

// MARK: - File Icon Resolver

enum FileIconResolver {
    private static var cache: [String: NSImage] = [:]

    static func icon(for item: FileItem, expanded: Bool = false) -> NSImage {
        let key = iconName(for: item, expanded: expanded)

        if let cached = cache[key] { return cached }

        if let img = loadSVG(named: key) {
            cache[key] = img
            return img
        }

        // Fallback
        let fallback = item.isDirectory ? "default_folder" : "default_file"
        if let img = cache[fallback] ?? loadSVG(named: fallback) {
            cache[fallback] = img
            return img
        }

        return NSImage(systemSymbolName: "doc", accessibilityDescription: nil)!
    }

    private static func loadSVG(named name: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "svg") else {
            return nil
        }
        guard let img = NSImage(contentsOf: url) else { return nil }
        img.isTemplate = false
        return img
    }

    private static func iconName(for item: FileItem, expanded: Bool) -> String {
        if item.isDirectory {
            let folderName = item.name.lowercased()
            if let specific = folderNames[folderName] {
                return expanded ? "\(specific)_opened" : specific
            }
            return expanded ? "default_folder_opened" : "default_folder"
        }

        let ext = item.url.pathExtension.lowercased()
        let filename = item.name.lowercased()

        // Check exact filename first
        if let specific = fileNames[filename] {
            return specific
        }

        // Check extension
        if let specific = extensions[ext] {
            return specific
        }

        return "default_file"
    }

    private static let extensions: [String: String] = [
        // Apple
        "swift": "file_type_swift",
        "m": "file_type_objectivec",
        "mm": "file_type_objectivecpp",
        "h": "file_type_c",
        // Web
        "js": "file_type_js",
        "jsx": "file_type_reactjs",
        "ts": "file_type_typescript",
        "tsx": "file_type_reactjs",
        "html": "file_type_html",
        "htm": "file_type_html",
        "css": "file_type_css",
        "scss": "file_type_scss",
        "sass": "file_type_sass",
        "less": "file_type_less",
        "vue": "file_type_vue",
        "svelte": "file_type_config",
        // Data
        "json": "file_type_json",
        "xml": "file_type_xml",
        "yaml": "file_type_yaml",
        "yml": "file_type_yaml",
        "toml": "file_type_toml",
        "csv": "file_type_text",
        "plist": "file_type_xml",
        "graphql": "file_type_graphql",
        "gql": "file_type_graphql",
        // Languages
        "py": "file_type_python",
        "rb": "file_type_ruby",
        "rs": "file_type_rust",
        "go": "file_type_go",
        "java": "file_type_java",
        "kt": "file_type_kotlin",
        "kts": "file_type_kotlin",
        "cs": "file_type_csharp",
        "cpp": "file_type_cpp",
        "cc": "file_type_cpp",
        "cxx": "file_type_cpp",
        "c": "file_type_c",
        "php": "file_type_php",
        "r": "file_type_r",
        "lua": "file_type_lua",
        "pl": "file_type_perl",
        "pm": "file_type_perl",
        "sql": "file_type_sql",
        // Shell
        "sh": "file_type_shell",
        "bash": "file_type_shell",
        "zsh": "file_type_shell",
        "fish": "file_type_shell",
        // Docs
        "md": "file_type_markdown",
        "markdown": "file_type_markdown",
        "txt": "file_type_text",
        "pdf": "file_type_pdf",
        "log": "file_type_log",
        // Images
        "png": "file_type_image",
        "jpg": "file_type_image",
        "jpeg": "file_type_image",
        "gif": "file_type_image",
        "bmp": "file_type_image",
        "ico": "file_type_image",
        "webp": "file_type_image",
        "svg": "file_type_svg",
        // Media
        "mp4": "file_type_video",
        "mov": "file_type_video",
        "avi": "file_type_video",
        "webm": "file_type_video",
        "mp3": "file_type_audio",
        "wav": "file_type_audio",
        "flac": "file_type_audio",
        // Fonts
        "ttf": "file_type_font",
        "otf": "file_type_font",
        "woff": "file_type_font",
        "woff2": "file_type_font",
        // Archives
        "zip": "file_type_zip",
        "tar": "file_type_zip",
        "gz": "file_type_zip",
        "rar": "file_type_zip",
        "7z": "file_type_zip",
        // Config
        "env": "file_type_dotenv",
        "ini": "file_type_config",
        "cfg": "file_type_config",
        "conf": "file_type_config",
        // Build
        "gradle": "file_type_gradle",
        "cmake": "file_type_cmake",
    ]

    private static let fileNames: [String: String] = [
        "dockerfile": "file_type_docker",
        "docker-compose.yml": "file_type_docker2",
        "docker-compose.yaml": "file_type_docker2",
        ".gitignore": "file_type_git",
        ".gitattributes": "file_type_git",
        ".gitmodules": "file_type_git",
        "license": "file_type_license",
        "license.md": "file_type_license",
        "license.txt": "file_type_license",
        "makefile": "file_type_cmake",
        "cmakelists.txt": "file_type_cmake",
        ".env": "file_type_dotenv",
        ".env.local": "file_type_dotenv",
        ".env.development": "file_type_dotenv",
        ".env.production": "file_type_dotenv",
    ]

    private static let folderNames: [String: String] = [
        ".git": "default_folder",
    ]
}
