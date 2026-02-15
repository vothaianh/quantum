import SwiftUI

// MARK: - Zoom Environment

struct FontZoomKey: EnvironmentKey {
    static let defaultValue: Double = 1.0
}

extension EnvironmentValues {
    var fontZoom: Double {
        get { self[FontZoomKey.self] }
        set { self[FontZoomKey.self] = newValue }
    }
}

extension Font {
    static func zoomed(size: CGFloat, zoom: Double, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        .system(size: size * zoom, weight: weight, design: design)
    }
}

enum Theme {
    // MARK: - Backgrounds
    // Blue-tinted dark family — each panel at a different depth

    /// Editor — the hero surface, eyes spend the most time here
    static let bg = Color(nsColor: NSColor(srgbRed: 0.094, green: 0.106, blue: 0.129, alpha: 1))            // #181B21

    /// Sidebar — cooler, slightly darker, recedes visually
    static let bgSidebar = Color(nsColor: NSColor(srgbRed: 0.078, green: 0.090, blue: 0.114, alpha: 1))      // #14171D

    /// Terminal — deepest layer, its own world
    static let bgTerminal = Color(nsColor: NSColor(srgbRed: 0.059, green: 0.067, blue: 0.082, alpha: 1))     // #0F1115

    /// Headers/tab bars — slightly lifted from their parent surface
    static let bgHeader = Color(nsColor: NSColor(srgbRed: 0.106, green: 0.118, blue: 0.145, alpha: 1))       // #1B1E25

    /// Interactive states
    static let bgHover = Color.white.opacity(0.04)
    static let bgSelected = Color.white.opacity(0.07)

    // MARK: - Text

    /// Primary — high contrast for code & file names
    static let textPrimary = Color(nsColor: NSColor(srgbRed: 0.847, green: 0.863, blue: 0.894, alpha: 1))    // #D8DCE4

    /// Secondary — labels, metadata, inactive tabs
    static let textSecondary = Color(nsColor: NSColor(srgbRed: 0.478, green: 0.514, blue: 0.576, alpha: 1))  // #7A8393

    /// Muted — placeholders, disabled, decorative
    static let textMuted = Color(nsColor: NSColor(srgbRed: 0.306, green: 0.337, blue: 0.388, alpha: 1))      // #4E5663

    // MARK: - Borders

    /// Panel dividers — visible but not distracting, slight blue tint
    static let border = Color(nsColor: NSColor(srgbRed: 0.145, green: 0.161, blue: 0.196, alpha: 1))         // #252932

    // MARK: - Accents

    /// Primary accent — selections, buttons, active indicators
    static let accent = Color(nsColor: NSColor(srgbRed: 0.322, green: 0.557, blue: 0.918, alpha: 1))         // #528EEA

    /// Terminal prompt green
    static let termGreen = Color(nsColor: NSColor(srgbRed: 0.337, green: 0.804, blue: 0.478, alpha: 1))      // #56CD7A

    /// Folder icons
    static let folderBlue = Color(nsColor: NSColor(srgbRed: 0.416, green: 0.635, blue: 0.945, alpha: 1))     // #6AA2F1

    /// Gutter — line numbers area, slightly darker than editor
    static let bgGutter = Color(nsColor: NSColor(srgbRed: 0.082, green: 0.094, blue: 0.118, alpha: 1))       // #151820

    /// Active line — subtle highlight for current line
    static let bgActiveLine = Color.white.opacity(0.03)
}

// MARK: - Syntax Highlighting Colors (VSCode Dark+ / Cursor inspired)

extension NSColor {
    static let editorBg     = NSColor(srgbRed: 0.094, green: 0.106, blue: 0.129, alpha: 1) // #181B21
    static let gutterBg     = NSColor(srgbRed: 0.082, green: 0.094, blue: 0.118, alpha: 1) // #151820
    static let gutterLine   = NSColor(srgbRed: 0.145, green: 0.161, blue: 0.196, alpha: 1) // #252932
    static let lineNumberFg = NSColor(srgbRed: 0.306, green: 0.337, blue: 0.388, alpha: 1) // #4E5663

    static let syntaxText         = NSColor(srgbRed: 0.847, green: 0.863, blue: 0.894, alpha: 1)  // #D8DCE4
    static let syntaxKeyword      = NSColor(srgbRed: 0.337, green: 0.612, blue: 0.839, alpha: 1)  // #569CD6
    static let syntaxString       = NSColor(srgbRed: 0.808, green: 0.569, blue: 0.471, alpha: 1)  // #CE9178
    static let syntaxComment      = NSColor(srgbRed: 0.416, green: 0.600, blue: 0.333, alpha: 1)  // #6A9955
    static let syntaxNumber       = NSColor(srgbRed: 0.710, green: 0.808, blue: 0.659, alpha: 1)  // #B5CEA8
    static let syntaxType         = NSColor(srgbRed: 0.306, green: 0.788, blue: 0.690, alpha: 1)  // #4EC9B0
    static let syntaxPreprocessor = NSColor(srgbRed: 0.773, green: 0.525, blue: 0.753, alpha: 1)  // #C586C0
    static let syntaxFunction     = NSColor(srgbRed: 0.863, green: 0.863, blue: 0.667, alpha: 1)  // #DCDCAA
    static let syntaxProperty     = NSColor(srgbRed: 0.612, green: 0.863, blue: 0.996, alpha: 1)  // #9CDCFE
    static let activeLine         = NSColor(white: 1.0, alpha: 0.03)
}

// MARK: - Dark Scroller Modifier

/// Finds the backing NSScrollView and sets dark knob style
struct DarkScrollerViewFinder: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            var current: NSView? = view.superview
            while let v = current {
                if let sv = v as? NSScrollView {
                    sv.scrollerKnobStyle = .dark
                    break
                }
                current = v.superview
            }
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
    func darkScrollers() -> some View {
        background(DarkScrollerViewFinder())
    }
}
