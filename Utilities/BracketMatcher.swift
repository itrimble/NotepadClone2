import Foundation
import AppKit

class BracketMatcher {
    
    // Define bracket pairs
    private static let bracketPairs: [Character: Character] = [
        "(": ")",
        "[": "]",
        "{": "}",
        "<": ">",
        "\"": "\"",
        "'": "'",
        "`": "`"
    ]
    
    private static let openingBrackets = Set(bracketPairs.keys)
    private static let closingBrackets = Set(bracketPairs.values)
    private static let allBrackets = openingBrackets.union(closingBrackets)
    
    // Find matching bracket for position in text
    static func findMatchingBracket(in text: String, at position: Int) -> BracketMatch? {
        guard position >= 0 && position < text.count else { return nil }
        
        let characters = Array(text)
        let currentChar = characters[position]
        
        // Check if current character is a bracket
        guard allBrackets.contains(currentChar) else { return nil }
        
        if openingBrackets.contains(currentChar) {
            // Find closing bracket
            return findClosingBracket(in: characters, startPosition: position, openChar: currentChar)
        } else if closingBrackets.contains(currentChar) {
            // Find opening bracket
            return findOpeningBracket(in: characters, startPosition: position, closeChar: currentChar)
        }
        
        return nil
    }
    
    // Find bracket at cursor position or adjacent positions
    static func findBracketAtCursor(in text: String, cursorPosition: Int) -> BracketMatch? {
        // Check character before cursor
        if cursorPosition > 0 {
            if let match = findMatchingBracket(in: text, at: cursorPosition - 1) {
                return match
            }
        }
        
        // Check character at cursor
        if cursorPosition < text.count {
            if let match = findMatchingBracket(in: text, at: cursorPosition) {
                return match
            }
        }
        
        return nil
    }
    
    private static func findClosingBracket(in characters: [Character], startPosition: Int, openChar: Character) -> BracketMatch? {
        guard let closeChar = bracketPairs[openChar] else { return nil }
        
        var depth = 1
        var position = startPosition + 1
        
        // Special handling for quotes - they're their own closing character
        if openChar == closeChar {
            while position < characters.count {
                if characters[position] == closeChar {
                    return BracketMatch(
                        startPosition: startPosition,
                        endPosition: position,
                        startChar: openChar,
                        endChar: closeChar,
                        isMatched: true
                    )
                }
                position += 1
            }
            return BracketMatch(
                startPosition: startPosition,
                endPosition: -1,
                startChar: openChar,
                endChar: closeChar,
                isMatched: false
            )
        }
        
        // Handle nested brackets
        while position < characters.count {
            let char = characters[position]
            
            if char == openChar {
                depth += 1
            } else if char == closeChar {
                depth -= 1
                if depth == 0 {
                    return BracketMatch(
                        startPosition: startPosition,
                        endPosition: position,
                        startChar: openChar,
                        endChar: closeChar,
                        isMatched: true
                    )
                }
            }
            position += 1
        }
        
        // No matching bracket found
        return BracketMatch(
            startPosition: startPosition,
            endPosition: -1,
            startChar: openChar,
            endChar: closeChar,
            isMatched: false
        )
    }
    
    private static func findOpeningBracket(in characters: [Character], startPosition: Int, closeChar: Character) -> BracketMatch? {
        // Find the opening bracket for this closing bracket
        var openChar: Character?
        for (open, close) in bracketPairs {
            if close == closeChar {
                openChar = open
                break
            }
        }
        
        guard let openBracket = openChar else { return nil }
        
        var depth = 1
        var position = startPosition - 1
        
        // Special handling for quotes
        if openBracket == closeChar {
            while position >= 0 {
                if characters[position] == openBracket {
                    return BracketMatch(
                        startPosition: position,
                        endPosition: startPosition,
                        startChar: openBracket,
                        endChar: closeChar,
                        isMatched: true
                    )
                }
                position -= 1
            }
            return BracketMatch(
                startPosition: -1,
                endPosition: startPosition,
                startChar: openBracket,
                endChar: closeChar,
                isMatched: false
            )
        }
        
        // Handle nested brackets
        while position >= 0 {
            let char = characters[position]
            
            if char == closeChar {
                depth += 1
            } else if char == openBracket {
                depth -= 1
                if depth == 0 {
                    return BracketMatch(
                        startPosition: position,
                        endPosition: startPosition,
                        startChar: openBracket,
                        endChar: closeChar,
                        isMatched: true
                    )
                }
            }
            position -= 1
        }
        
        // No matching bracket found
        return BracketMatch(
            startPosition: -1,
            endPosition: startPosition,
            startChar: openBracket,
            endChar: closeChar,
            isMatched: false
        )
    }
    
    // Apply bracket highlighting to NSTextView using temporary attributes
    static func highlightBrackets(in textView: NSTextView, theme: SyntaxTheme) {
        guard let layoutManager = textView.layoutManager else { return }
        
        let selectedRange = textView.selectedRange()
        let text = textView.string
        
        // Remove any existing bracket highlighting
        clearBracketHighlighting(in: layoutManager)
        
        // Find bracket match at cursor position
        guard let bracketMatch = findBracketAtCursor(in: text, cursorPosition: selectedRange.location) else {
            return
        }
        
        let highlightColor = bracketMatch.isMatched ? 
            NSColor.systemBlue.withAlphaComponent(0.2) : 
            NSColor.systemRed.withAlphaComponent(0.2)
        
        // Use temporary attributes for bracket highlighting to avoid conflicts with syntax highlighting
        // Highlight the starting bracket
        if bracketMatch.startPosition >= 0 {
            let startRange = NSRange(location: bracketMatch.startPosition, length: 1)
            layoutManager.addTemporaryAttribute(.backgroundColor, value: highlightColor, forCharacterRange: startRange)
        }
        
        // Highlight the ending bracket
        if bracketMatch.endPosition >= 0 {
            let endRange = NSRange(location: bracketMatch.endPosition, length: 1)
            layoutManager.addTemporaryAttribute(.backgroundColor, value: highlightColor, forCharacterRange: endRange)
        }
        
        // Invalidate display for the highlighted ranges
        if textView.textContainer != nil {
            if bracketMatch.startPosition >= 0 {
                let startRange = NSRange(location: bracketMatch.startPosition, length: 1)
                let glyphRange = layoutManager.glyphRange(forCharacterRange: startRange, actualCharacterRange: nil)
                layoutManager.invalidateDisplay(forGlyphRange: glyphRange)
            }
            
            if bracketMatch.endPosition >= 0 {
                let endRange = NSRange(location: bracketMatch.endPosition, length: 1)
                let glyphRange = layoutManager.glyphRange(forCharacterRange: endRange, actualCharacterRange: nil)
                layoutManager.invalidateDisplay(forGlyphRange: glyphRange)
            }
        }
    }
    
    private static func clearBracketHighlighting(in layoutManager: NSLayoutManager) {
        // Remove all temporary background color attributes
        let fullRange = NSRange(location: 0, length: layoutManager.textStorage?.length ?? 0)
        layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: fullRange)
    }
}

// Data structure to represent a bracket match
struct BracketMatch {
    let startPosition: Int      // Position of opening bracket (-1 if not found)
    let endPosition: Int        // Position of closing bracket (-1 if not found)
    let startChar: Character    // Opening bracket character
    let endChar: Character      // Closing bracket character
    let isMatched: Bool         // Whether a valid match was found
    
    var isValid: Bool {
        return startPosition >= 0 && endPosition >= 0
    }
}