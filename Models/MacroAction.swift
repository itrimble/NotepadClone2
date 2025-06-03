import Foundation
import AppKit // For NSRange if used directly, or define a Codable wrapper

// Define a Codable wrapper for NSRange if needed, or ensure direct Codable conformance
// For simplicity, we might avoid NSRange directly in MacroAction if it complicates Codability across modules/targets.
// Let's start with basic actions not directly embedding AppKit types if possible,
// or use simple Ints for location/length if a full NSRange Codable wrapper is too much for now.

enum MacroAction: Codable, Hashable {
    case insertText(String)
    case deleteBackward
    case deleteForward
    // Basic cursor movements (by character)
    case moveCursorBackward
    case moveCursorForward
    // Could add moveUp, moveDown, etc. later
    // For selection, it's more complex. Let's defer explicit selection recording for now
    // and focus on actions that imply selection changes (like deleteForward on a selection).
    // case setSelectedRange(location: Int, length: Int) // Example for later

    // To make it Codable with associated values, Swift handles it automatically if associated types are Codable.
    // String is Codable.
}
