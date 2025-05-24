import Foundation
import AppKit

class SmartIndenter {
    
    // Configuration for different languages
    private static let indentationRules: [SyntaxHighlighter.Language: IndentationRules] = [
        .swift: IndentationRules(
            indentSize: 4,
            useSpaces: true,
            increaseAfter: ["\\{\\s*$", ":\\s*$", "\\(\\s*$"],
            decreaseBefore: ["^\\s*\\}", "^\\s*\\)", "^\\s*case\\s+", "^\\s*default\\s*:"],
            alignWithOpening: true,
            continuationIndent: 4
        ),
        .python: IndentationRules(
            indentSize: 4,
            useSpaces: true,
            increaseAfter: [":\\s*$", "\\(\\s*$", "\\[\\s*$"],
            decreaseBefore: ["^\\s*\\)", "^\\s*\\]", "^\\s*except\\s+", "^\\s*finally\\s*:", "^\\s*elif\\s+", "^\\s*else\\s*:"],
            alignWithOpening: true,
            continuationIndent: 4
        ),
        .javascript: IndentationRules(
            indentSize: 2,
            useSpaces: true,
            increaseAfter: ["\\{\\s*$", "\\(\\s*$", "\\[\\s*$"],
            decreaseBefore: ["^\\s*\\}", "^\\s*\\)", "^\\s*\\]"],
            alignWithOpening: true,
            continuationIndent: 2
        ),
        .bash: IndentationRules(
            indentSize: 2,
            useSpaces: true,
            increaseAfter: ["then\\s*$", "do\\s*$", "\\{\\s*$"],
            decreaseBefore: ["^\\s*fi\\s*$", "^\\s*done\\s*$", "^\\s*\\}"],
            alignWithOpening: false,
            continuationIndent: 2
        ),
        .applescript: IndentationRules(
            indentSize: 4,
            useSpaces: true,
            increaseAfter: ["then\\s*$", "repeat\\s+", "tell\\s+"],
            decreaseBefore: ["^\\s*end\\s+", "^\\s*else\\s*$"],
            alignWithOpening: false,
            continuationIndent: 4
        )
    ]
    
    // Calculate appropriate indentation for a new line
    static func calculateIndentation(
        for text: String,
        at insertionPoint: Int,
        language: SyntaxHighlighter.Language,
        tabSize: Int = 4,
        useSpaces: Bool = true
    ) -> String {
        
        guard let rules = indentationRules[language] else {
            return getGenericIndentation(for: text, at: insertionPoint, tabSize: tabSize, useSpaces: useSpaces)
        }
        
        let lines = text.components(separatedBy: .newlines)
        let lineIndex = getLineIndex(for: insertionPoint, in: text)
        
        guard lineIndex >= 0 && lineIndex < lines.count else {
            return ""
        }
        
        let currentLine = lines[lineIndex].trimmingCharacters(in: .whitespaces)
        let previousLineIndex = lineIndex - 1
        
        // Base case: first line
        if previousLineIndex < 0 {
            return ""
        }
        
        let previousLine = lines[previousLineIndex]
        let previousLineIndent = getIndentationLevel(of: previousLine, tabSize: tabSize)
        
        // Check if we need to decrease indentation for current line
        for pattern in rules.decreaseBefore {
            if currentLine.range(of: pattern, options: .regularExpression) != nil {
                let newIndent = max(0, previousLineIndent - rules.indentSize)
                return createIndentation(level: newIndent, useSpaces: rules.useSpaces, tabSize: tabSize)
            }
        }
        
        // Check if previous line should increase indentation
        for pattern in rules.increaseAfter {
            if previousLine.range(of: pattern, options: .regularExpression) != nil {
                let newIndent = previousLineIndent + rules.indentSize
                return createIndentation(level: newIndent, useSpaces: rules.useSpaces, tabSize: tabSize)
            }
        }
        
        // Handle continuation lines and alignment
        if rules.alignWithOpening {
            if let alignmentIndent = calculateAlignmentIndentation(
                for: lines,
                currentLineIndex: lineIndex,
                rules: rules,
                tabSize: tabSize
            ) {
                return alignmentIndent
            }
        }
        
        // Default: maintain same indentation as previous line
        return createIndentation(level: previousLineIndent, useSpaces: rules.useSpaces, tabSize: tabSize)
    }
    
    // Apply smart indentation when user presses Enter
    static func handleNewlineIndentation(
        in textView: NSTextView,
        language: SyntaxHighlighter.Language
    ) -> Bool {
        guard let textStorage = textView.textStorage else { return false }
        
        let selectedRange = textView.selectedRange()
        let text = textStorage.string
        
        // Calculate appropriate indentation
        let indentation = calculateIndentation(
            for: text,
            at: selectedRange.location,
            language: language
        )
        
        // Insert newline with appropriate indentation
        let newlineWithIndent = "\n" + indentation
        
        if textView.shouldChangeText(in: selectedRange, replacementString: newlineWithIndent) {
            textStorage.replaceCharacters(in: selectedRange, with: newlineWithIndent)
            textView.didChangeText()
            
            // Set cursor position at end of indentation
            let newCursorPosition = selectedRange.location + newlineWithIndent.count
            textView.setSelectedRange(NSRange(location: newCursorPosition, length: 0))
            
            return true
        }
        
        return false
    }
    
    // Auto-indent a block of text
    static func autoIndentText(
        _ text: String,
        language: SyntaxHighlighter.Language,
        tabSize: Int = 4,
        useSpaces: Bool = true
    ) -> String {
        
        let lines = text.components(separatedBy: .newlines)
        var indentedLines: [String] = []
        var currentIndentLevel = 0
        
        guard let rules = indentationRules[language] else {
            return text // Return unchanged if no rules for language
        }
        
        for (_, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines
            if trimmedLine.isEmpty {
                indentedLines.append("")
                continue
            }
            
            // Check if we need to decrease indentation for this line
            var lineIndentLevel = currentIndentLevel
            for pattern in rules.decreaseBefore {
                if trimmedLine.range(of: pattern, options: .regularExpression) != nil {
                    lineIndentLevel = max(0, currentIndentLevel - rules.indentSize)
                    currentIndentLevel = lineIndentLevel
                    break
                }
            }
            
            // Apply indentation to line
            let indentation = createIndentation(level: lineIndentLevel, useSpaces: rules.useSpaces, tabSize: tabSize)
            indentedLines.append(indentation + trimmedLine)
            
            // Check if this line should increase indentation for next line
            for pattern in rules.increaseAfter {
                if line.range(of: pattern, options: .regularExpression) != nil {
                    currentIndentLevel = lineIndentLevel + rules.indentSize
                    break
                }
            }
        }
        
        return indentedLines.joined(separator: "\n")
    }
    
    // MARK: - Helper Methods
    
    private static func getGenericIndentation(
        for text: String,
        at insertionPoint: Int,
        tabSize: Int,
        useSpaces: Bool
    ) -> String {
        let lines = text.components(separatedBy: .newlines)
        let lineIndex = getLineIndex(for: insertionPoint, in: text)
        
        guard lineIndex >= 0 && lineIndex < lines.count else {
            return ""
        }
        
        // For generic indentation, just match the indentation of the previous non-empty line
        for i in stride(from: lineIndex, through: 0, by: -1) {
            let line = lines[i]
            if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                let indentLevel = getIndentationLevel(of: line, tabSize: tabSize)
                return createIndentation(level: indentLevel, useSpaces: useSpaces, tabSize: tabSize)
            }
        }
        
        return ""
    }
    
    private static func getLineIndex(for position: Int, in text: String) -> Int {
        let beforeCursor = String(text.prefix(position))
        return beforeCursor.components(separatedBy: .newlines).count - 1
    }
    
    private static func getIndentationLevel(of line: String, tabSize: Int) -> Int {
        var level = 0
        for char in line {
            if char == " " {
                level += 1
            } else if char == "\t" {
                level += tabSize
            } else {
                break
            }
        }
        return level
    }
    
    private static func createIndentation(level: Int, useSpaces: Bool, tabSize: Int) -> String {
        if useSpaces {
            return String(repeating: " ", count: level)
        } else {
            let tabs = level / tabSize
            let spaces = level % tabSize
            return String(repeating: "\t", count: tabs) + String(repeating: " ", count: spaces)
        }
    }
    
    private static func calculateAlignmentIndentation(
        for lines: [String],
        currentLineIndex: Int,
        rules: IndentationRules,
        tabSize: Int
    ) -> String? {
        
        // Look for opening brackets/parentheses on previous lines
        for i in stride(from: currentLineIndex - 1, through: max(0, currentLineIndex - 10), by: -1) {
            let line = lines[i]
            
            // Look for unmatched opening brackets
            var bracketCount = 0
            var parenCount = 0
            var alignmentColumn: Int?
            
            for (index, char) in line.enumerated() {
                switch char {
                case "(":
                    parenCount += 1
                    if alignmentColumn == nil {
                        alignmentColumn = index + 1
                    }
                case ")":
                    parenCount -= 1
                case "[":
                    bracketCount += 1
                    if alignmentColumn == nil {
                        alignmentColumn = index + 1
                    }
                case "]":
                    bracketCount -= 1
                default:
                    break
                }
            }
            
            // If we have unmatched opening brackets and found an alignment point
            if (parenCount > 0 || bracketCount > 0), let column = alignmentColumn {
                let baseIndent = getIndentationLevel(of: line, tabSize: tabSize)
                let totalIndent = baseIndent + column
                return createIndentation(level: totalIndent, useSpaces: rules.useSpaces, tabSize: tabSize)
            }
        }
        
        return nil
    }
}

// Configuration structure for indentation rules
struct IndentationRules {
    let indentSize: Int                  // Number of spaces/tabs to indent
    let useSpaces: Bool                  // Whether to use spaces instead of tabs
    let increaseAfter: [String]          // Regex patterns that increase indentation on next line
    let decreaseBefore: [String]         // Regex patterns that decrease current line indentation
    let alignWithOpening: Bool           // Whether to align with opening brackets
    let continuationIndent: Int          // Extra indentation for continuation lines
}