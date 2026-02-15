import AppKit

// MARK: - Language Definition

enum SyntaxLanguage {
    case swift, javascript, typescript, python, ruby, go, rust, c, cpp, java, kotlin, csharp
    case html, css, json, yaml, xml, markdown, shell, sql, php, lua, perl, r
    case unknown

    var keywords: [String] {
        switch self {
        case .swift:
            return ["import", "func", "var", "let", "class", "struct", "enum", "protocol", "extension",
                    "if", "else", "guard", "switch", "case", "default", "for", "while", "repeat",
                    "return", "throw", "throws", "try", "catch", "do", "break", "continue", "fallthrough",
                    "in", "where", "is", "as", "nil", "true", "false", "self", "Self", "super",
                    "init", "deinit", "subscript", "typealias", "associatedtype",
                    "private", "fileprivate", "internal", "public", "open", "static", "final",
                    "override", "mutating", "nonmutating", "lazy", "weak", "unowned",
                    "optional", "required", "convenience", "dynamic", "indirect",
                    "some", "any", "async", "await", "actor", "nonisolated", "isolated",
                    "get", "set", "willSet", "didSet", "inout", "consuming", "borrowing"]
        case .javascript, .typescript:
            return ["function", "var", "let", "const", "class", "extends", "implements",
                    "if", "else", "switch", "case", "default", "for", "while", "do",
                    "return", "throw", "try", "catch", "finally", "break", "continue",
                    "new", "delete", "typeof", "instanceof", "void", "this", "super",
                    "import", "export", "from", "as", "async", "await", "yield",
                    "true", "false", "null", "undefined", "of", "in",
                    "interface", "type", "enum", "namespace", "declare", "abstract",
                    "public", "private", "protected", "readonly", "static", "override"]
        case .python:
            return ["def", "class", "if", "elif", "else", "for", "while", "try", "except",
                    "finally", "with", "as", "import", "from", "return", "yield", "raise",
                    "pass", "break", "continue", "and", "or", "not", "is", "in", "lambda",
                    "global", "nonlocal", "True", "False", "None", "self", "async", "await",
                    "del", "assert"]
        case .go:
            return ["package", "import", "func", "var", "const", "type", "struct", "interface",
                    "map", "chan", "if", "else", "switch", "case", "default", "for", "range",
                    "return", "break", "continue", "goto", "fallthrough", "defer", "go", "select",
                    "true", "false", "nil", "iota"]
        case .rust:
            return ["fn", "let", "mut", "const", "static", "struct", "enum", "trait", "impl",
                    "type", "mod", "use", "pub", "crate", "super", "self", "Self",
                    "if", "else", "match", "for", "while", "loop", "break", "continue", "return",
                    "as", "in", "ref", "move", "async", "await", "dyn", "unsafe", "extern",
                    "true", "false", "where"]
        case .c, .cpp:
            return ["auto", "break", "case", "char", "const", "continue", "default", "do",
                    "double", "else", "enum", "extern", "float", "for", "goto", "if",
                    "int", "long", "register", "return", "short", "signed", "sizeof", "static",
                    "struct", "switch", "typedef", "union", "unsigned", "void", "volatile", "while",
                    "class", "namespace", "template", "typename", "virtual", "override", "final",
                    "public", "private", "protected", "new", "delete", "this", "throw", "try", "catch",
                    "true", "false", "nullptr", "using", "include", "define", "ifdef", "ifndef", "endif"]
        case .java, .kotlin:
            return ["abstract", "boolean", "break", "byte", "case", "catch", "char",
                    "class", "const", "continue", "default", "do", "double", "else", "enum",
                    "extends", "final", "finally", "float", "for", "if", "implements",
                    "import", "instanceof", "int", "interface", "long", "native", "new",
                    "package", "private", "protected", "public", "return", "short", "static",
                    "super", "switch", "synchronized", "this", "throw", "throws",
                    "try", "void", "volatile", "while", "true", "false", "null",
                    "var", "val", "fun", "object", "companion", "data", "sealed", "when", "is", "in"]
        case .csharp:
            return ["abstract", "base", "bool", "break", "byte", "case", "catch", "char",
                    "class", "const", "continue", "decimal", "default", "delegate", "do",
                    "double", "else", "enum", "event", "explicit", "extern", "false", "finally",
                    "fixed", "float", "for", "foreach", "goto", "if", "implicit", "in", "int",
                    "interface", "internal", "is", "lock", "long", "namespace", "new", "null",
                    "object", "operator", "out", "override", "params", "private", "protected",
                    "public", "readonly", "ref", "return", "sealed", "short", "sizeof",
                    "static", "string", "struct", "switch", "this", "throw", "true", "try",
                    "typeof", "uint", "ulong", "unchecked", "unsafe", "ushort", "using",
                    "var", "virtual", "void", "volatile", "while", "async", "await"]
        case .json:
            return ["true", "false", "null"]
        case .yaml:
            return ["true", "false", "null", "yes", "no"]
        case .shell:
            return ["if", "then", "else", "elif", "fi", "for", "while", "do", "done",
                    "case", "esac", "function", "return", "exit", "local", "export",
                    "source", "echo", "read", "set", "unset", "shift", "eval",
                    "true", "false", "in"]
        case .sql:
            return ["SELECT", "FROM", "WHERE", "AND", "OR", "NOT", "INSERT", "INTO", "VALUES",
                    "UPDATE", "SET", "DELETE", "CREATE", "DROP", "ALTER", "TABLE", "INDEX",
                    "JOIN", "LEFT", "RIGHT", "INNER", "OUTER", "ON", "GROUP", "BY", "ORDER",
                    "HAVING", "LIMIT", "OFFSET", "AS", "DISTINCT", "NULL", "TRUE", "FALSE",
                    "IN", "EXISTS", "BETWEEN", "LIKE", "IS", "CASE", "WHEN", "THEN", "ELSE", "END",
                    "select", "from", "where", "and", "or", "not", "insert", "into", "values",
                    "update", "set", "delete", "create", "drop", "alter", "table",
                    "join", "left", "right", "inner", "outer", "on", "group", "by", "order",
                    "having", "limit", "offset", "as", "distinct", "null",
                    "in", "exists", "between", "like", "is", "case", "when", "then", "else", "end"]
        case .php:
            return ["abstract", "and", "as", "break", "case", "catch", "class", "clone",
                    "const", "continue", "declare", "default", "do", "else", "elseif",
                    "extends", "final", "finally", "for", "foreach", "function", "global",
                    "if", "implements", "instanceof", "interface", "namespace", "new", "or",
                    "private", "protected", "public", "return", "static", "switch", "throw",
                    "trait", "try", "use", "var", "while", "yield",
                    "true", "false", "null", "self", "parent"]
        case .ruby:
            return ["def", "class", "module", "if", "elsif", "else", "unless", "case", "when",
                    "while", "until", "for", "do", "begin", "rescue", "ensure", "raise",
                    "return", "yield", "break", "next", "redo", "retry",
                    "and", "or", "not", "in", "end", "self", "super",
                    "true", "false", "nil", "require", "include", "extend",
                    "attr_reader", "attr_writer", "attr_accessor",
                    "public", "private", "protected"]
        case .lua:
            return ["and", "break", "do", "else", "elseif", "end", "false", "for",
                    "function", "goto", "if", "in", "local", "nil", "not", "or",
                    "repeat", "return", "then", "true", "until", "while"]
        case .perl:
            return ["my", "our", "local", "sub", "if", "elsif", "else", "unless",
                    "while", "until", "for", "foreach", "do", "last", "next", "redo",
                    "return", "die", "warn", "print", "say", "use", "require",
                    "package", "BEGIN", "END"]
        case .r:
            return ["if", "else", "for", "while", "repeat", "in", "next", "break",
                    "function", "return", "TRUE", "FALSE", "NULL", "NA", "Inf", "NaN",
                    "library", "require", "source"]
        default:
            return []
        }
    }

    var hasSlashComments: Bool {
        switch self {
        case .swift, .javascript, .typescript, .go, .rust, .c, .cpp, .java, .kotlin,
             .csharp, .php, .css:
            return true
        default: return false
        }
    }

    var hasHashComments: Bool {
        switch self {
        case .python, .ruby, .shell, .yaml, .r, .perl: return true
        default: return false
        }
    }

    var hasDashDashComments: Bool {
        switch self {
        case .sql, .lua: return true
        default: return false
        }
    }

    var hasHTMLComments: Bool {
        switch self {
        case .html, .xml, .markdown: return true
        default: return false
        }
    }

    var hasSingleQuoteStrings: Bool {
        switch self {
        case .javascript, .typescript, .python, .ruby, .php, .shell, .html, .css, .yaml, .perl:
            return true
        default: return false
        }
    }

    var hasBacktickStrings: Bool {
        switch self {
        case .javascript, .typescript, .go: return true
        default: return false
        }
    }

    var hasTripleQuoteStrings: Bool {
        switch self {
        case .python, .swift, .kotlin: return true
        default: return false
        }
    }

    var hasAtAttributes: Bool {
        switch self {
        case .swift, .java, .kotlin, .python, .csharp: return true
        default: return false
        }
    }
}

// MARK: - Highlighter

enum SyntaxHighlighter {

    static func language(for ext: String) -> SyntaxLanguage {
        switch ext.lowercased() {
        case "swift":                        return .swift
        case "js", "jsx", "mjs", "cjs":     return .javascript
        case "ts", "tsx":                    return .typescript
        case "py":                           return .python
        case "rb":                           return .ruby
        case "go":                           return .go
        case "rs":                           return .rust
        case "c", "h":                       return .c
        case "cpp", "cc", "cxx", "mm", "hpp": return .cpp
        case "java":                         return .java
        case "kt", "kts":                    return .kotlin
        case "cs":                           return .csharp
        case "html", "htm":                  return .html
        case "css", "scss", "sass", "less":  return .css
        case "json":                         return .json
        case "yaml", "yml":                  return .yaml
        case "xml", "plist":                 return .xml
        case "md", "markdown":               return .markdown
        case "sh", "bash", "zsh", "fish":    return .shell
        case "sql":                          return .sql
        case "php":                          return .php
        case "lua":                          return .lua
        case "pl", "pm":                     return .perl
        case "r":                            return .r
        default:                             return .unknown
        }
    }

    static func highlight(_ text: String, fileExtension: String, font: NSFont) -> NSAttributedString {
        let lang = language(for: fileExtension)

        let defaultAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.syntaxText,
        ]

        let result = NSMutableAttributedString(string: text, attributes: defaultAttrs)
        let nsString = text as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)

        guard lang != .unknown, fullRange.length > 0 else { return result }

        // --- Phase 1: find string & comment regions (context-aware) ---
        let stringRanges = findStringRanges(in: text, language: lang)
        let commentRanges = findCommentRanges(in: text, language: lang, excluding: stringRanges)
        let excluded = stringRanges + commentRanges

        // --- Phase 2: color tokens in code regions ---

        // @ attributes
        if lang.hasAtAttributes {
            applyPattern("@[A-Za-z_]\\w*", color: .syntaxPreprocessor, to: result, in: text, fullRange: fullRange, excluding: excluded)
        }

        // C/C++ preprocessor
        if lang == .c || lang == .cpp {
            applyPattern("^\\s*#\\s*\\w+", color: .syntaxPreprocessor, to: result, in: text, fullRange: fullRange, excluding: excluded, options: .anchorsMatchLines)
        }

        // Types (PascalCase identifiers)
        applyPattern("\\b[A-Z][a-zA-Z0-9_]*\\b", color: .syntaxType, to: result, in: text, fullRange: fullRange, excluding: excluded)

        // Numbers (decimal + hex)
        applyPattern("\\b0[xX][0-9a-fA-F_]+\\b", color: .syntaxNumber, to: result, in: text, fullRange: fullRange, excluding: excluded)
        applyPattern("\\b\\d[\\d_]*(\\.[\\d_]+)?([eE][+-]?[\\d_]+)?\\b", color: .syntaxNumber, to: result, in: text, fullRange: fullRange, excluding: excluded)

        // Keywords (override types for words like Self, True, etc.)
        if !lang.keywords.isEmpty {
            let escaped = lang.keywords.map { NSRegularExpression.escapedPattern(for: $0) }
            let pattern = "\\b(" + escaped.joined(separator: "|") + ")\\b"
            applyPattern(pattern, color: .syntaxKeyword, to: result, in: text, fullRange: fullRange, excluding: excluded)
        }

        // Function calls: word followed by (
        applyPattern("\\b([a-zA-Z_]\\w*)\\s*(?=\\()", color: .syntaxFunction, to: result, in: text, fullRange: fullRange, excluding: excluded)

        // --- Phase 3: color strings & comments (override everything) ---
        for range in stringRanges {
            result.addAttribute(.foregroundColor, value: NSColor.syntaxString, range: range)
        }
        for range in commentRanges {
            result.addAttribute(.foregroundColor, value: NSColor.syntaxComment, range: range)
        }

        return result
    }

    // MARK: - Helpers

    private static func applyPattern(
        _ pattern: String,
        color: NSColor,
        to attributed: NSMutableAttributedString,
        in text: String,
        fullRange: NSRange,
        excluding: [NSRange],
        options: NSRegularExpression.Options = []
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
        let matches = regex.matches(in: text, range: fullRange)
        for match in matches {
            let range = match.numberOfRanges > 1 ? match.range(at: 1) : match.range
            guard range.location != NSNotFound else { continue }
            if !isExcluded(range, from: excluding) {
                attributed.addAttribute(.foregroundColor, value: color, range: range)
            }
        }
    }

    private static func isExcluded(_ range: NSRange, from excluded: [NSRange]) -> Bool {
        excluded.contains { NSIntersectionRange($0, range).length > 0 }
    }

    // MARK: - String Range Detection

    private static func findStringRanges(in text: String, language: SyntaxLanguage) -> [NSRange] {
        var ranges: [NSRange] = []
        let nsString = text as NSString
        let len = nsString.length
        var i = 0

        while i < len {
            let ch = nsString.character(at: i)

            // Triple-quote strings
            if language.hasTripleQuoteStrings && ch == 0x22 && i + 2 < len
                && nsString.character(at: i + 1) == 0x22
                && nsString.character(at: i + 2) == 0x22 {
                let start = i
                i += 3
                while i + 2 < len {
                    if nsString.character(at: i) == 0x22
                        && nsString.character(at: i + 1) == 0x22
                        && nsString.character(at: i + 2) == 0x22 {
                        i += 3
                        break
                    }
                    if nsString.character(at: i) == 0x5C { i += 1 } // backslash
                    i += 1
                }
                if i >= len { i = len }
                ranges.append(NSRange(location: start, length: i - start))
                continue
            }

            // Double-quote string
            if ch == 0x22 { // "
                let start = i
                i += 1
                while i < len {
                    let c = nsString.character(at: i)
                    if c == 0x5C { i += 2; continue } // backslash escape
                    if c == 0x22 { i += 1; break }    // closing quote
                    if c == 0x0A { break }             // newline
                    i += 1
                }
                ranges.append(NSRange(location: start, length: i - start))
                continue
            }

            // Single-quote string
            if language.hasSingleQuoteStrings && ch == 0x27 { // '
                let start = i
                i += 1
                while i < len {
                    let c = nsString.character(at: i)
                    if c == 0x5C { i += 2; continue }
                    if c == 0x27 { i += 1; break }
                    if c == 0x0A { break }
                    i += 1
                }
                ranges.append(NSRange(location: start, length: i - start))
                continue
            }

            // Backtick string (template literals)
            if language.hasBacktickStrings && ch == 0x60 { // `
                let start = i
                i += 1
                while i < len {
                    let c = nsString.character(at: i)
                    if c == 0x5C { i += 2; continue }
                    if c == 0x60 { i += 1; break }
                    i += 1
                }
                ranges.append(NSRange(location: start, length: i - start))
                continue
            }

            i += 1
        }
        return ranges
    }

    // MARK: - Comment Range Detection

    private static func findCommentRanges(in text: String, language: SyntaxLanguage, excluding: [NSRange]) -> [NSRange] {
        var ranges: [NSRange] = []
        let nsString = text as NSString
        let len = nsString.length
        var i = 0

        while i < len {
            let ch = nsString.character(at: i)

            // Block comments /* ... */
            if language.hasSlashComments && ch == 0x2F && i + 1 < len && nsString.character(at: i + 1) == 0x2A {
                let start = i
                if isExcluded(NSRange(location: start, length: 2), from: excluding) { i += 2; continue }
                i += 2
                while i + 1 < len {
                    if nsString.character(at: i) == 0x2A && nsString.character(at: i + 1) == 0x2F {
                        i += 2; break
                    }
                    i += 1
                }
                if i >= len { i = len }
                ranges.append(NSRange(location: start, length: i - start))
                continue
            }

            // Line comments //
            if language.hasSlashComments && ch == 0x2F && i + 1 < len && nsString.character(at: i + 1) == 0x2F {
                let start = i
                if isExcluded(NSRange(location: start, length: 2), from: excluding) { i += 2; continue }
                while i < len && nsString.character(at: i) != 0x0A { i += 1 }
                ranges.append(NSRange(location: start, length: i - start))
                continue
            }

            // Hash comments #
            if language.hasHashComments && ch == 0x23 {
                let start = i
                if isExcluded(NSRange(location: start, length: 1), from: excluding) { i += 1; continue }
                while i < len && nsString.character(at: i) != 0x0A { i += 1 }
                ranges.append(NSRange(location: start, length: i - start))
                continue
            }

            // -- comments
            if language.hasDashDashComments && ch == 0x2D && i + 1 < len && nsString.character(at: i + 1) == 0x2D {
                let start = i
                if isExcluded(NSRange(location: start, length: 2), from: excluding) { i += 2; continue }
                while i < len && nsString.character(at: i) != 0x0A { i += 1 }
                ranges.append(NSRange(location: start, length: i - start))
                continue
            }

            // HTML comments <!-- ... -->
            if language.hasHTMLComments && ch == 0x3C && i + 3 < len
                && nsString.character(at: i + 1) == 0x21
                && nsString.character(at: i + 2) == 0x2D
                && nsString.character(at: i + 3) == 0x2D {
                let start = i
                if isExcluded(NSRange(location: start, length: 4), from: excluding) { i += 4; continue }
                i += 4
                while i + 2 < len {
                    if nsString.character(at: i) == 0x2D
                        && nsString.character(at: i + 1) == 0x2D
                        && nsString.character(at: i + 2) == 0x3E {
                        i += 3; break
                    }
                    i += 1
                }
                if i >= len { i = len }
                ranges.append(NSRange(location: start, length: i - start))
                continue
            }

            i += 1
        }
        return ranges
    }
}
