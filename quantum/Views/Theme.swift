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
    // Neutral black-to-gray — clean depth, no color tint

    /// Editor — the hero surface
    static let bg = Color(nsColor: NSColor(srgbRed: 0.098, green: 0.098, blue: 0.098, alpha: 1))            // #191919

    /// Sidebar — slightly darker, recedes
    static let bgSidebar = Color(nsColor: NSColor(srgbRed: 0.078, green: 0.078, blue: 0.078, alpha: 1))      // #141414

    /// Terminal — deepest layer
    static let bgTerminal = Color(nsColor: NSColor(srgbRed: 0.059, green: 0.059, blue: 0.059, alpha: 1))     // #0F0F0F

    /// Headers/tab bars — slightly lifted
    static let bgHeader = Color(nsColor: NSColor(srgbRed: 0.118, green: 0.118, blue: 0.118, alpha: 1))       // #1E1E1E

    /// Interactive states
    static let bgHover = Color.white.opacity(0.05)
    static let bgSelected = Color.white.opacity(0.08)

    // MARK: - Text

    /// Primary — high contrast for code & file names
    static let textPrimary = Color(nsColor: NSColor(srgbRed: 0.847, green: 0.910, blue: 0.875, alpha: 1))    // #D8E8DF

    /// Secondary — labels, metadata, inactive tabs
    static let textSecondary = Color(nsColor: NSColor(srgbRed: 0.420, green: 0.545, blue: 0.478, alpha: 1))  // #6B8B7A

    /// Muted — placeholders, disabled, decorative
    static let textMuted = Color(nsColor: NSColor(srgbRed: 0.243, green: 0.337, blue: 0.286, alpha: 1))      // #3E5649

    // MARK: - Borders

    /// Panel dividers — subtle neutral
    static let border = Color(nsColor: NSColor(srgbRed: 0.137, green: 0.137, blue: 0.137, alpha: 1))         // #232323

    // MARK: - Accents

    /// Primary accent — emerald green
    static let accent = Color(nsColor: NSColor(srgbRed: 0.0, green: 0.863, blue: 0.510, alpha: 1))           // #00DC82

    /// Terminal prompt green
    static let termGreen = Color(nsColor: NSColor(srgbRed: 0.0, green: 0.863, blue: 0.510, alpha: 1))        // #00DC82

    /// Folder/file icons
    static let folderBlue = Color(nsColor: NSColor(srgbRed: 0.0, green: 0.863, blue: 0.510, alpha: 1))       // #00DC82

    /// Danger — deletions, errors
    static let danger = Color(nsColor: NSColor(srgbRed: 1.0, green: 0.333, blue: 0.333, alpha: 1))           // #FF5555

    /// Gutter — line numbers area
    static let bgGutter = Color(nsColor: NSColor(srgbRed: 0.078, green: 0.078, blue: 0.078, alpha: 1))       // #141414

    /// Active line — subtle highlight
    static let bgActiveLine = Color(nsColor: NSColor(srgbRed: 0.0, green: 0.863, blue: 0.510, alpha: 0.04))
}

// MARK: - Syntax Highlighting Colors

extension NSColor {
    static let editorBg     = NSColor(srgbRed: 0.098, green: 0.098, blue: 0.098, alpha: 1)  // #191919
    static let gutterBg     = NSColor(srgbRed: 0.078, green: 0.078, blue: 0.078, alpha: 1)  // #141414
    static let gutterLine   = NSColor(srgbRed: 0.137, green: 0.137, blue: 0.137, alpha: 1)  // #232323
    static let lineNumberFg = NSColor(srgbRed: 0.243, green: 0.337, blue: 0.286, alpha: 1)  // #3E5649

    static let syntaxText         = NSColor(srgbRed: 0.847, green: 0.910, blue: 0.875, alpha: 1)  // #D8E8DF
    static let syntaxKeyword      = NSColor(srgbRed: 0.0,   green: 0.863, blue: 0.510, alpha: 1)  // #00DC82 emerald
    static let syntaxString       = NSColor(srgbRed: 0.722, green: 0.914, blue: 0.525, alpha: 1)  // #B8E986 lime
    static let syntaxComment      = NSColor(srgbRed: 0.294, green: 0.388, blue: 0.341, alpha: 1)  // #4B6357 sage
    static let syntaxNumber       = NSColor(srgbRed: 0.898, green: 0.753, blue: 0.482, alpha: 1)  // #E5C07B gold
    static let syntaxType         = NSColor(srgbRed: 0.780, green: 0.573, blue: 0.918, alpha: 1)  // #C792EA purple
    static let syntaxPreprocessor = NSColor(srgbRed: 0.502, green: 0.796, blue: 0.769, alpha: 1)  // #80CBC4 seafoam
    static let syntaxFunction     = NSColor(srgbRed: 0.510, green: 0.667, blue: 1.0,   alpha: 1)  // #82AAFF blue
    static let syntaxProperty     = NSColor(srgbRed: 0.941, green: 0.443, blue: 0.471, alpha: 1)  // #F07178 coral
    static let activeLine         = NSColor(srgbRed: 0.0, green: 0.863, blue: 0.510, alpha: 0.04)
}

// MARK: - Dark Scrollbar Swizzling

extension NSScroller {
    static let swizzleOnce: Void = {
        let drawKnob = #selector(NSScroller.drawKnob as (NSScroller) -> () -> Void)
        let darkKnob = #selector(NSScroller.q_drawKnob)
        if let orig = class_getInstanceMethod(NSScroller.self, drawKnob),
           let repl = class_getInstanceMethod(NSScroller.self, darkKnob) {
            method_exchangeImplementations(orig, repl)
        }

        let drawSlot = #selector(NSScroller.drawKnobSlot(in:highlight:))
        let darkSlot = #selector(NSScroller.q_drawKnobSlot(in:highlight:))
        if let orig = class_getInstanceMethod(NSScroller.self, drawSlot),
           let repl = class_getInstanceMethod(NSScroller.self, darkSlot) {
            method_exchangeImplementations(orig, repl)
        }
    }()

    @objc func q_drawKnob() {
        let r = rect(for: .knob)
        guard r.width > 0, r.height > 0 else { return }
        let inset = r.width > r.height
            ? r.insetBy(dx: 1, dy: 2)
            : r.insetBy(dx: 2, dy: 1)
        let radius = min(inset.width, inset.height) / 2
        let path = NSBezierPath(roundedRect: inset, xRadius: radius, yRadius: radius)
        NSColor(srgbRed: 0.0, green: 0.863, blue: 0.510, alpha: 0.20).setFill()
        path.fill()
    }

    @objc func q_drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        // Transparent track
    }
}
