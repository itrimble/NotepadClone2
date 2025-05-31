import SwiftUI
import AppKit

struct TerminalConfig {
    var backgroundColor: NSColor
    var textColor: NSColor
    var cursorColor: NSColor
    var selectionColor: NSColor
    var font: NSFont
    let shell: String = "/bin/zsh" // Default shell

    // Default initializer for use before AppState is available or for previews
    init() {
        // Provide some sensible defaults, these will be overridden by theme
        self.backgroundColor = NSColor.windowBackgroundColor
        self.textColor = NSColor.textColor
        self.cursorColor = NSColor.textColor
        self.selectionColor = NSColor.selectedTextBackgroundColor.withAlphaComponent(0.3)
        self.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    }

    init(theme: AppTheme) {
        self.backgroundColor = theme.terminalBackgroundColor()
        self.textColor = theme.terminalTextColor()
        self.cursorColor = theme.terminalCursorColor()
        self.selectionColor = theme.terminalSelectionColor()
        // For now, use a system monospaced font. Theme-specific fonts could be added later.
        self.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        // self.shell is already defaulted
    }
}
