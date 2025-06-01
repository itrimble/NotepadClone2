// Models/CompletionContext.swift
import Foundation

struct CompletionContext {
    let currentText: String      // Full text of the document
    let cursorPosition: Int    // Current cursor position (UTF-16 offset)
    let languageIdentifier: String // e.g., "swift", "python"
    let currentWord: String      // The word fragment leading up to the cursor
}
