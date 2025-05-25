import SwiftUI
import AppKit

class SyntaxHighlighter {
    enum Language: String, CaseIterable {
        case swift
        case python
        case bash
        case applescript
        case javascript
        case none
        
        static func detect(from fileURL: URL?) -> Language {
            guard let ext = fileURL?.pathExtension.lowercased() else { return .none }
            
            switch ext {
            case "swift": return .swift
            case "py": return .python
            case "sh", "bash": return .bash
            case "scpt", "applescript": return .applescript
            case "js", "jsx", "ts", "tsx": return .javascript
            default: return .none
            }
        }
        
        var displayName: String {
            switch self {
            case .swift: return "Swift"
            case .python: return "Python"
            case .bash: return "Bash"
            case .applescript: return "AppleScript"
            case .javascript: return "JavaScript"
            case .none: return "Plain Text"
            }
        }
        
        var abbreviation: String {
            switch self {
            case .swift: return "SWIFT"
            case .python: return "PY"
            case .bash: return "SH"
            case .applescript: return "AS"
            case .javascript: return "JS"
            case .none: return ""
            }
        }
    }
    
    private let language: Language
    private let theme: SyntaxTheme // This now includes editorFont
    
    init(language: Language, theme: SyntaxTheme) { // Removed default for theme to ensure it's always passed
        self.language = language
        self.theme = theme
    }
    
    func highlight(_ text: String) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: text)
        
        // Apply base style using theme's font and text color
        let range = NSRange(location: 0, length: text.count)
        attributed.addAttribute(.font, value: theme.editorFont, range: range) // Use theme.editorFont
        attributed.addAttribute(.foregroundColor, value: theme.textColor, range: range)
        
        // Apply syntax highlighting based on language
        switch language {
        case .swift:
            highlightSwift(in: attributed)
        case .python:
            highlightPython(in: attributed)
        case .bash:
            highlightBash(in: attributed)
        case .applescript:
            highlightAppleScript(in: attributed)
        case .javascript:
            highlightJavaScript(in: attributed)
        case .none:
            break
        }
        
        return attributed
    }
    
    private func highlightSwift(in text: NSMutableAttributedString) {
        let keywords = [
            "func", "var", "let", "if", "else", "for", "while", "repeat", "import", "struct", "class", "enum", "protocol", "extension", "return", "private", "public", "internal", "fileprivate", "open", "static", "final", "override", "init", "deinit", "mutating", "associatedtype", "where", "throws", "rethrows", "try", "catch", "guard", "defer", "switch", "case", "default", "break", "continue", "fallthrough", "is", "as", "in", "inout", "indirect", "lazy", "weak", "unowned", "some", "any", "Self", "self", "true", "false", "nil"
        ]
        highlightPattern(in: text, pattern: "\\b(" + keywords.joined(separator: "|") + ")\\b", color: theme.keywordColor)
        highlightPattern(in: text, pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", color: theme.stringColor)
        highlightPattern(in: text, pattern: "//.*?$", options: .anchorsMatchLines, color: theme.commentColor)
        highlightPattern(in: text, pattern: "/\\*.*?\\*/", options: .dotMatchesLineSeparators, color: theme.commentColor)
        highlightPattern(in: text, pattern: "\\b\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?\\b", color: theme.numberColor)
        highlightPattern(in: text, pattern: "@\\w+", color: theme.annotationColor)
        highlightPattern(in: text, pattern: "\\b[A-Z][a-zA-Z0-9]*\\b", color: theme.typeColor)
    }
    
    private func highlightPython(in text: NSMutableAttributedString) {
        let keywords = [
            "def", "class", "if", "else", "elif", "for", "while", "import", "from", "as", "in", "return", "try", "except", "finally", "with", "lambda", "self", "True", "False", "None", "and", "or", "not", "is", "assert", "del", "global", "nonlocal", "raise", "pass", "break", "continue", "yield", "async", "await"
        ]
        highlightPattern(in: text, pattern: "\\b(" + keywords.joined(separator: "|") + ")\\b", color: theme.keywordColor)
        highlightPattern(in: text, pattern: "\"\"\".*?\"\"\"", options: .dotMatchesLineSeparators, color: theme.stringColor)
        highlightPattern(in: text, pattern: "'''.*?'''", options: .dotMatchesLineSeparators, color: theme.stringColor)
        highlightPattern(in: text, pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", color: theme.stringColor)
        highlightPattern(in: text, pattern: "'(?:[^'\\\\]|\\\\.)*'", color: theme.stringColor)
        highlightPattern(in: text, pattern: "#.*?$", options: .anchorsMatchLines, color: theme.commentColor)
        highlightPattern(in: text, pattern: "\\b\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?\\b", color: theme.numberColor)
        highlightPattern(in: text, pattern: "@\\w+", color: theme.annotationColor)
        highlightPattern(in: text, pattern: "def\\s+(\\w+)", color: theme.functionColor)
        highlightPattern(in: text, pattern: "class\\s+(\\w+)", color: theme.typeColor)
    }
    
    private func highlightBash(in text: NSMutableAttributedString) {
        let keywords = [
            "if", "then", "fi", "for", "while", "do", "done", "case", "esac", "function", "echo", "exit", "return", "export", "source", "\\.", "set", "unset", "declare", "local", "readonly", "alias", "unalias", "history", "jobs", "kill", "ps", "cd", "pwd", "ls", "cat", "grep", "sed", "awk", "sort", "uniq", "wc", "head", "tail", "find", "xargs", "chmod", "chown", "mkdir", "rmdir", "rm", "cp", "mv", "ln", "touch", "date", "sleep", "read", "test", "\\[", "\\]"
        ]
        highlightPattern(in: text, pattern: "\\b(" + keywords.joined(separator: "|") + ")\\b", color: theme.keywordColor)
        highlightPattern(in: text, pattern: "\\$\\w+", color: theme.variableColor)
        highlightPattern(in: text, pattern: "\\$\\{[^}]+\\}", color: theme.variableColor)
        highlightPattern(in: text, pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", color: theme.stringColor)
        highlightPattern(in: text, pattern: "'[^']*'", color: theme.stringColor)
        highlightPattern(in: text, pattern: "#.*?$", options: .anchorsMatchLines, color: theme.commentColor)
        highlightPattern(in: text, pattern: "[~/\\.]?[\\w/\\.\\-]+", color: theme.pathColor)
        highlightPattern(in: text, pattern: "^#!.*?$", options: .anchorsMatchLines, color: theme.commentColor)
    }
    
    private func highlightAppleScript(in text: NSMutableAttributedString) {
        let keywords = [
            "set", "to", "if", "then", "else", "end", "repeat", "while", "until", "times", "tell", "application", "return", "on", "error", "try", "of", "with", "without", "property", "script", "handler", "display", "dialog", "choose", "file", "folder", "activate", "get", "copy", "exists", "make", "new", "every", "whose", "where", "contains", "begins", "ends", "equals", "and", "or", "not", "is", "equal", "true", "false", "missing", "value", "id", "name", "class", "item", "the", "my", "me", "its"
        ]
        highlightPattern(in: text, pattern: "\\b(" + keywords.joined(separator: "|") + ")\\b", options: .caseInsensitive, color: theme.keywordColor)
        highlightPattern(in: text, pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", color: theme.stringColor)
        highlightPattern(in: text, pattern: "--.*?$", options: .anchorsMatchLines, color: theme.commentColor)
        highlightPattern(in: text, pattern: "\\(\\*.*?\\*\\)", options: .dotMatchesLineSeparators, color: theme.commentColor)
        highlightPattern(in: text, pattern: "\\b\\d+(?:\\.\\d+)?\\b", color: theme.numberColor)
        highlightPattern(in: text, pattern: "application\\s+\"[^\"]+\"", color: theme.typeColor)
    }
    
    private func highlightJavaScript(in text: NSMutableAttributedString) {
        let keywords = [
            "function", "var", "let", "const", "if", "else", "for", "while", "do", "return", "class", "extends", "import", "export", "from", "default", "async", "await", "try", "catch", "finally", "throw", "new", "this", "super", "static", "get", "set", "typeof", "instanceof", "in", "of", "delete", "void", "true", "false", "null", "undefined", "break", "continue", "switch", "case", "default", "debugger", "with", "yield"
        ]
        highlightPattern(in: text, pattern: "\\b(" + keywords.joined(separator: "|") + ")\\b", color: theme.keywordColor)
        highlightPattern(in: text, pattern: "`(?:[^`\\\\]|\\\\.)*`", color: theme.stringColor)
        highlightPattern(in: text, pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", color: theme.stringColor)
        highlightPattern(in: text, pattern: "'(?:[^'\\\\]|\\\\.)*'", color: theme.stringColor)
        highlightPattern(in: text, pattern: "//.*?$", options: .anchorsMatchLines, color: theme.commentColor)
        highlightPattern(in: text, pattern: "/\\*.*?\\*/", options: .dotMatchesLineSeparators, color: theme.commentColor)
        highlightPattern(in: text, pattern: "\\b\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?\\b", color: theme.numberColor)
        highlightPattern(in: text, pattern: "/(?:[^/\\\\]|\\\\.)+/[gimsuxy]*", color: theme.regexColor)
        highlightPattern(in: text, pattern: "function\\s+(\\w+)", color: theme.functionColor)
    }
    
    private func highlightPattern(in text: NSMutableAttributedString, pattern: String, options: NSRegularExpression.Options = [], color: NSColor) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let range = NSRange(location: 0, length: text.length)
            
            regex.enumerateMatches(in: text.string, options: [], range: range) { match, _, _ in
                if let matchRange = match?.range {
                    text.addAttribute(.foregroundColor, value: color, range: matchRange)
                }
            }
        } catch {
            print("Syntax highlighting regex error: \(error)")
        }
    }
}

// SyntaxTheme.swift
struct SyntaxTheme {
    let editorFont: NSFont // Added font property
    let textColor: NSColor
    let keywordColor: NSColor
    let stringColor: NSColor
    let commentColor: NSColor
    let numberColor: NSColor
    let variableColor: NSColor
    let pathColor: NSColor
    let functionColor: NSColor
    let typeColor: NSColor
    let annotationColor: NSColor
    let regexColor: NSColor
    
    static let `default` = SyntaxTheme(
        editorFont: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular), // Default font
        textColor: NSColor.black,
        keywordColor: NSColor(red: 0.52, green: 0.0, blue: 0.67, alpha: 1.0),
        stringColor: NSColor(red: 0.0, green: 0.42, blue: 0.0, alpha: 1.0),
        commentColor: NSColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1.0),
        numberColor: NSColor(red: 0.0, green: 0.0, blue: 0.67, alpha: 1.0),
        variableColor: NSColor(red: 0.67, green: 0.22, blue: 0.0, alpha: 1.0),
        pathColor: NSColor(red: 0.0, green: 0.35, blue: 0.56, alpha: 1.0),
        functionColor: NSColor(red: 0.67, green: 0.28, blue: 0.0, alpha: 1.0),
        typeColor: NSColor(red: 0.0, green: 0.45, blue: 0.56, alpha: 1.0),
        annotationColor: NSColor(red: 0.22, green: 0.45, blue: 0.67, alpha: 1.0),
        regexColor: NSColor(red: 0.78, green: 0.0, blue: 0.35, alpha: 1.0)
    )
    
    static let dark = SyntaxTheme(
        editorFont: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular), // Default font
        textColor: NSColor.white,
        keywordColor: NSColor(red: 0.95, green: 0.51, blue: 0.93, alpha: 1.0),
        stringColor: NSColor(red: 0.67, green: 0.82, blue: 0.38, alpha: 1.0),
        commentColor: NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),
        numberColor: NSColor(red: 0.38, green: 0.63, blue: 0.89, alpha: 1.0),
        variableColor: NSColor(red: 0.99, green: 0.71, blue: 0.38, alpha: 1.0),
        pathColor: NSColor(red: 0.43, green: 0.89, blue: 0.98, alpha: 1.0),
        functionColor: NSColor(red: 1.0, green: 0.85, blue: 0.38, alpha: 1.0),
        typeColor: NSColor(red: 0.43, green: 0.89, blue: 0.98, alpha: 1.0),
        annotationColor: NSColor(red: 0.51, green: 0.93, blue: 0.87, alpha: 1.0),
        regexColor: NSColor(red: 0.99, green: 0.51, blue: 0.76, alpha: 1.0)
    )
    
    // This static method is illustrative; actual theme selection happens in AppTheme.syntaxTheme()
    static func theme(for colorScheme: ColorScheme?, currentAppTheme: AppTheme) -> SyntaxTheme {
        return currentAppTheme.syntaxTheme() // Delegate to AppTheme instance
    }
}
