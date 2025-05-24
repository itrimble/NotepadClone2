import Foundation
import AppKit

// Represents a foldable region in the code
struct FoldableRegion: Hashable {
    let startLine: Int
    let endLine: Int
    let startColumn: Int
    let endColumn: Int
    let type: FoldType
    let startText: String  // Text at the start line for display purposes
    var isFolded: Bool = false
    
    enum FoldType: String, CaseIterable {
        case function
        case `class`
        case `struct`
        case `enum`
        case `protocol`
        case `extension`
        case braces  // Generic braces block
        case comment  // Multi-line comments
        case `import`  // Import statements
        case conditional  // if/else blocks
        case loop  // for/while blocks
        case `switch`  // switch statements
        
        var displayName: String {
            switch self {
            case .function: return "Function"
            case .class: return "Class"
            case .struct: return "Struct"
            case .enum: return "Enum"
            case .protocol: return "Protocol"
            case .extension: return "Extension"
            case .braces: return "Block"
            case .comment: return "Comment"
            case .import: return "Imports"
            case .conditional: return "Conditional"
            case .loop: return "Loop"
            case .switch: return "Switch"
            }
        }
    }
}

class CodeFolder {
    private let language: SyntaxHighlighter.Language
    
    init(language: SyntaxHighlighter.Language) {
        self.language = language
    }
    
    // Main function to detect all foldable regions in text
    func detectFoldableRegions(in text: String) -> [FoldableRegion] {
        var regions: [FoldableRegion] = []
        
        switch language {
        case .swift:
            regions.append(contentsOf: detectSwiftRegions(in: text))
        case .python:
            regions.append(contentsOf: detectPythonRegions(in: text))
        case .javascript:
            regions.append(contentsOf: detectJavaScriptRegions(in: text))
        case .bash:
            regions.append(contentsOf: detectBashRegions(in: text))
        case .applescript:
            regions.append(contentsOf: detectAppleScriptRegions(in: text))
        case .none:
            regions.append(contentsOf: detectGenericRegions(in: text))
        }
        
        // Sort regions by start line
        return regions.sorted { $0.startLine < $1.startLine }
    }
    
    // MARK: - Swift-specific detection
    private func detectSwiftRegions(in text: String) -> [FoldableRegion] {
        var regions: [FoldableRegion] = []
        let lines = text.components(separatedBy: .newlines)
        
        // Detect import groups
        regions.append(contentsOf: detectImportGroups(in: lines))
        
        // Detect functions, classes, structs, enums, protocols, extensions
        regions.append(contentsOf: detectSwiftDeclarations(in: lines))
        
        // Detect multi-line comments
        regions.append(contentsOf: detectMultiLineComments(in: lines, startPattern: "/\\*", endPattern: "\\*/"))
        
        // Detect generic brace blocks
        regions.append(contentsOf: detectBraceBlocks(in: lines))
        
        // Detect conditional blocks
        regions.append(contentsOf: detectSwiftConditionals(in: lines))
        
        return regions
    }
    
    private func detectSwiftDeclarations(in lines: [String]) -> [FoldableRegion] {
        var regions: [FoldableRegion] = []
        
        for (lineIndex, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("//") { continue }
            
            // Function declarations
            if let match = line.range(of: #"^\s*(private|public|internal|fileprivate|open)?\s*(static|class)?\s*func\s+\w+"#, options: .regularExpression) {
                if let endLine = findMatchingBrace(from: lineIndex, in: lines) {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .function,
                        startText: String(line[match])
                    )
                    regions.append(region)
                }
            }
            
            // Class declarations
            else if let match = line.range(of: #"^\s*(private|public|internal|fileprivate|open)?\s*(final)?\s*class\s+\w+"#, options: .regularExpression) {
                if let endLine = findMatchingBrace(from: lineIndex, in: lines) {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .class,
                        startText: String(line[match])
                    )
                    regions.append(region)
                }
            }
            
            // Struct declarations
            else if let match = line.range(of: #"^\s*(private|public|internal|fileprivate|open)?\s*struct\s+\w+"#, options: .regularExpression) {
                if let endLine = findMatchingBrace(from: lineIndex, in: lines) {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .struct,
                        startText: String(line[match])
                    )
                    regions.append(region)
                }
            }
            
            // Enum declarations
            else if let match = line.range(of: #"^\s*(private|public|internal|fileprivate|open)?\s*enum\s+\w+"#, options: .regularExpression) {
                if let endLine = findMatchingBrace(from: lineIndex, in: lines) {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .enum,
                        startText: String(line[match])
                    )
                    regions.append(region)
                }
            }
            
            // Protocol declarations
            else if let match = line.range(of: #"^\s*(private|public|internal|fileprivate|open)?\s*protocol\s+\w+"#, options: .regularExpression) {
                if let endLine = findMatchingBrace(from: lineIndex, in: lines) {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .protocol,
                        startText: String(line[match])
                    )
                    regions.append(region)
                }
            }
            
            // Extension declarations
            else if let match = line.range(of: #"^\s*(private|public|internal|fileprivate|open)?\s*extension\s+\w+"#, options: .regularExpression) {
                if let endLine = findMatchingBrace(from: lineIndex, in: lines) {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .extension,
                        startText: String(line[match])
                    )
                    regions.append(region)
                }
            }
        }
        
        return regions
    }
    
    private func detectSwiftConditionals(in lines: [String]) -> [FoldableRegion] {
        var regions: [FoldableRegion] = []
        
        for (lineIndex, line) in lines.enumerated() {
            _ = line.trimmingCharacters(in: .whitespaces)
            
            // If statements
            if let match = line.range(of: #"^\s*if\s+"#, options: .regularExpression) {
                if let endLine = findMatchingBrace(from: lineIndex, in: lines) {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .conditional,
                        startText: "if"
                    )
                    regions.append(region)
                }
            }
            
            // For loops
            else if let match = line.range(of: #"^\s*for\s+"#, options: .regularExpression) {
                if let endLine = findMatchingBrace(from: lineIndex, in: lines) {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .loop,
                        startText: "for"
                    )
                    regions.append(region)
                }
            }
            
            // While loops
            else if let match = line.range(of: #"^\s*while\s+"#, options: .regularExpression) {
                if let endLine = findMatchingBrace(from: lineIndex, in: lines) {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .loop,
                        startText: "while"
                    )
                    regions.append(region)
                }
            }
            
            // Switch statements
            else if let match = line.range(of: #"^\s*switch\s+"#, options: .regularExpression) {
                if let endLine = findMatchingBrace(from: lineIndex, in: lines) {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .switch,
                        startText: "switch"
                    )
                    regions.append(region)
                }
            }
        }
        
        return regions
    }
    
    // MARK: - Python-specific detection
    private func detectPythonRegions(in text: String) -> [FoldableRegion] {
        var regions: [FoldableRegion] = []
        let lines = text.components(separatedBy: .newlines)
        
        // Detect import groups
        regions.append(contentsOf: detectImportGroups(in: lines))
        
        // Detect classes and functions
        regions.append(contentsOf: detectPythonDeclarations(in: lines))
        
        // Detect multi-line strings (docstrings)
        regions.append(contentsOf: detectMultiLineStrings(in: lines, pattern: #"^\s*(""".*?"""|'''.*?''')"#))
        
        return regions
    }
    
    private func detectPythonDeclarations(in lines: [String]) -> [FoldableRegion] {
        var regions: [FoldableRegion] = []
        
        for (lineIndex, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            
            // Function definitions
            if let match = line.range(of: #"^\s*def\s+\w+"#, options: .regularExpression) {
                if let endLine = findPythonBlockEnd(from: lineIndex, in: lines) {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .function,
                        startText: String(line[match])
                    )
                    regions.append(region)
                }
            }
            
            // Class definitions
            else if let match = line.range(of: #"^\s*class\s+\w+"#, options: .regularExpression) {
                if let endLine = findPythonBlockEnd(from: lineIndex, in: lines) {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .class,
                        startText: String(line[match])
                    )
                    regions.append(region)
                }
            }
        }
        
        return regions
    }
    
    // MARK: - JavaScript-specific detection
    private func detectJavaScriptRegions(in text: String) -> [FoldableRegion] {
        var regions: [FoldableRegion] = []
        let lines = text.components(separatedBy: .newlines)
        
        // Detect import groups
        regions.append(contentsOf: detectImportGroups(in: lines))
        
        // Detect functions and classes
        regions.append(contentsOf: detectJavaScriptDeclarations(in: lines))
        
        // Detect multi-line comments
        regions.append(contentsOf: detectMultiLineComments(in: lines, startPattern: "/\\*", endPattern: "\\*/"))
        
        // Detect generic brace blocks
        regions.append(contentsOf: detectBraceBlocks(in: lines))
        
        return regions
    }
    
    private func detectJavaScriptDeclarations(in lines: [String]) -> [FoldableRegion] {
        var regions: [FoldableRegion] = []
        
        for (lineIndex, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("//") { continue }
            
            // Function declarations
            if let match = line.range(of: #"^\s*(export\s+)?(async\s+)?function\s+\w+"#, options: .regularExpression) {
                if let endLine = findMatchingBrace(from: lineIndex, in: lines) {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .function,
                        startText: String(line[match])
                    )
                    regions.append(region)
                }
            }
            
            // Class declarations
            else if let match = line.range(of: #"^\s*(export\s+)?class\s+\w+"#, options: .regularExpression) {
                if let endLine = findMatchingBrace(from: lineIndex, in: lines) {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .class,
                        startText: String(line[match])
                    )
                    regions.append(region)
                }
            }
        }
        
        return regions
    }
    
    // MARK: - Bash-specific detection
    private func detectBashRegions(in text: String) -> [FoldableRegion] {
        var regions: [FoldableRegion] = []
        let lines = text.components(separatedBy: .newlines)
        
        // Detect function declarations
        regions.append(contentsOf: detectBashFunctions(in: lines))
        
        // Detect if/then/fi blocks
        regions.append(contentsOf: detectBashConditionals(in: lines))
        
        return regions
    }
    
    private func detectBashFunctions(in lines: [String]) -> [FoldableRegion] {
        var regions: [FoldableRegion] = []
        
        for (lineIndex, line) in lines.enumerated() {
            // Function declarations: function name() or name()
            if let match = line.range(of: #"^\s*(function\s+)?\w+\s*\(\s*\)"#, options: .regularExpression) {
                // Find matching closing brace or end of function
                if let endLine = findBashFunctionEnd(from: lineIndex, in: lines) {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .function,
                        startText: String(line[match])
                    )
                    regions.append(region)
                }
            }
        }
        
        return regions
    }
    
    private func detectBashConditionals(in lines: [String]) -> [FoldableRegion] {
        var regions: [FoldableRegion] = []
        
        for (lineIndex, line) in lines.enumerated() {
            // If statements
            if let match = line.range(of: #"^\s*if\s+"#, options: .regularExpression) {
                if let endLine = findBashConditionalEnd(from: lineIndex, in: lines, endKeyword: "fi") {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .conditional,
                        startText: "if"
                    )
                    regions.append(region)
                }
            }
            
            // For loops
            else if let match = line.range(of: #"^\s*for\s+"#, options: .regularExpression) {
                if let endLine = findBashConditionalEnd(from: lineIndex, in: lines, endKeyword: "done") {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .loop,
                        startText: "for"
                    )
                    regions.append(region)
                }
            }
            
            // While loops
            else if let match = line.range(of: #"^\s*while\s+"#, options: .regularExpression) {
                if let endLine = findBashConditionalEnd(from: lineIndex, in: lines, endKeyword: "done") {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .loop,
                        startText: "while"
                    )
                    regions.append(region)
                }
            }
        }
        
        return regions
    }
    
    // MARK: - AppleScript-specific detection
    private func detectAppleScriptRegions(in text: String) -> [FoldableRegion] {
        var regions: [FoldableRegion] = []
        let lines = text.components(separatedBy: .newlines)
        
        // Detect handlers (functions)
        regions.append(contentsOf: detectAppleScriptHandlers(in: lines))
        
        // Detect tell blocks
        regions.append(contentsOf: detectAppleScriptTellBlocks(in: lines))
        
        return regions
    }
    
    private func detectAppleScriptHandlers(in lines: [String]) -> [FoldableRegion] {
        var regions: [FoldableRegion] = []
        
        for (lineIndex, line) in lines.enumerated() {
            // Handler declarations
            if let match = line.range(of: #"^\s*on\s+\w+"#, options: [.regularExpression, .caseInsensitive]) {
                if let endLine = findAppleScriptBlockEnd(from: lineIndex, in: lines, endKeyword: "end") {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .function,
                        startText: String(line[match])
                    )
                    regions.append(region)
                }
            }
        }
        
        return regions
    }
    
    private func detectAppleScriptTellBlocks(in lines: [String]) -> [FoldableRegion] {
        var regions: [FoldableRegion] = []
        
        for (lineIndex, line) in lines.enumerated() {
            // Tell blocks
            if let match = line.range(of: #"^\s*tell\s+"#, options: [.regularExpression, .caseInsensitive]) {
                if let endLine = findAppleScriptBlockEnd(from: lineIndex, in: lines, endKeyword: "end tell") {
                    let region = FoldableRegion(
                        startLine: lineIndex + 1,
                        endLine: endLine + 1,
                        startColumn: match.lowerBound.utf16Offset(in: line),
                        endColumn: line.count,
                        type: .braces,
                        startText: String(line[match])
                    )
                    regions.append(region)
                }
            }
        }
        
        return regions
    }
    
    // MARK: - Generic detection (for plain text and unknown languages)
    private func detectGenericRegions(in text: String) -> [FoldableRegion] {
        var regions: [FoldableRegion] = []
        let lines = text.components(separatedBy: .newlines)
        
        // Detect generic brace blocks only
        regions.append(contentsOf: detectBraceBlocks(in: lines))
        
        return regions
    }
    
    // MARK: - Helper methods for detecting specific patterns
    
    private func detectImportGroups(in lines: [String]) -> [FoldableRegion] {
        var regions: [FoldableRegion] = []
        var importStart: Int?
        var lastImportLine: Int?
        
        for (lineIndex, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Check if this line is an import/include
            let isImportLine = trimmed.hasPrefix("import ") || 
                              trimmed.hasPrefix("from ") || 
                              trimmed.hasPrefix("#include") ||
                              trimmed.hasPrefix("#import")
            
            if isImportLine {
                if importStart == nil {
                    importStart = lineIndex
                }
                lastImportLine = lineIndex
            } else if !trimmed.isEmpty && importStart != nil {
                // End of import group, create region if we have multiple imports
                if let start = importStart, let end = lastImportLine, end > start {
                    let region = FoldableRegion(
                        startLine: start + 1,
                        endLine: end + 1,
                        startColumn: 0,
                        endColumn: lines[end].count,
                        type: .import,
                        startText: "imports"
                    )
                    regions.append(region)
                }
                importStart = nil
                lastImportLine = nil
            }
        }
        
        // Handle case where imports go to end of file
        if let start = importStart, let end = lastImportLine, end > start {
            let region = FoldableRegion(
                startLine: start + 1,
                endLine: end + 1,
                startColumn: 0,
                endColumn: lines[end].count,
                type: .import,
                startText: "imports"
            )
            regions.append(region)
        }
        
        return regions
    }
    
    private func detectMultiLineComments(in lines: [String], startPattern: String, endPattern: String) -> [FoldableRegion] {
        var regions: [FoldableRegion] = []
        var commentStart: Int?
        
        for (lineIndex, line) in lines.enumerated() {
            if commentStart == nil && line.range(of: startPattern, options: .regularExpression) != nil {
                commentStart = lineIndex
            }
            
            if let start = commentStart, line.range(of: endPattern, options: .regularExpression) != nil {
                if lineIndex > start {  // Only create region for multi-line comments
                    let region = FoldableRegion(
                        startLine: start + 1,
                        endLine: lineIndex + 1,
                        startColumn: 0,
                        endColumn: line.count,
                        type: .comment,
                        startText: "comment"
                    )
                    regions.append(region)
                }
                commentStart = nil
            }
        }
        
        return regions
    }
    
    private func detectMultiLineStrings(in lines: [String], pattern: String) -> [FoldableRegion] {
        var regions: [FoldableRegion] = []
        var stringStart: Int?
        
        for (lineIndex, line) in lines.enumerated() {
            if stringStart == nil && line.range(of: #"^\s*("""|\"\"\"|''')"#, options: .regularExpression) != nil {
                stringStart = lineIndex
            } else if let start = stringStart, line.range(of: #"("""|''')\s*$"#, options: .regularExpression) != nil {
                if lineIndex > start {
                    let region = FoldableRegion(
                        startLine: start + 1,
                        endLine: lineIndex + 1,
                        startColumn: 0,
                        endColumn: line.count,
                        type: .comment,  // Treat docstrings as comments
                        startText: "docstring"
                    )
                    regions.append(region)
                }
                stringStart = nil
            }
        }
        
        return regions
    }
    
    private func detectBraceBlocks(in lines: [String]) -> [FoldableRegion] {
        var regions: [FoldableRegion] = []
        
        for (lineIndex, line) in lines.enumerated() {
            // Look for lines that end with opening brace
            if line.trimmingCharacters(in: .whitespaces).hasSuffix("{") {
                if let endLine = findMatchingBrace(from: lineIndex, in: lines) {
                    // Only create region for multi-line blocks
                    if endLine > lineIndex {
                        let region = FoldableRegion(
                            startLine: lineIndex + 1,
                            endLine: endLine + 1,
                            startColumn: 0,
                            endColumn: line.count,
                            type: .braces,
                            startText: "block"
                        )
                        regions.append(region)
                    }
                }
            }
        }
        
        return regions
    }
    
    // MARK: - Helper methods for finding block endings
    
    private func findMatchingBrace(from startLine: Int, in lines: [String]) -> Int? {
        var braceCount = 0
        var foundOpenBrace = false
        
        for lineIndex in startLine..<lines.count {
            let line = lines[lineIndex]
            
            for char in line {
                if char == "{" {
                    braceCount += 1
                    foundOpenBrace = true
                } else if char == "}" {
                    braceCount -= 1
                    if foundOpenBrace && braceCount == 0 {
                        return lineIndex
                    }
                }
            }
        }
        
        return nil
    }
    
    private func findPythonBlockEnd(from startLine: Int, in lines: [String]) -> Int? {
        guard startLine < lines.count else { return nil }
        
        // Get the indentation level of the declaration line
        let declarationLine = lines[startLine]
        let baseIndentation = getIndentationLevel(of: declarationLine)
        
        // Look for the last line that has greater indentation than the declaration
        var lastValidLine = startLine
        
        for lineIndex in (startLine + 1)..<lines.count {
            let line = lines[lineIndex]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines and comments
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            
            let lineIndentation = getIndentationLevel(of: line)
            
            if lineIndentation > baseIndentation {
                lastValidLine = lineIndex
            } else {
                // Found a line with equal or lesser indentation, end of block
                break
            }
        }
        
        return lastValidLine > startLine ? lastValidLine : nil
    }
    
    private func findBashFunctionEnd(from startLine: Int, in lines: [String]) -> Int? {
        var braceCount = 0
        var foundOpenBrace = false
        
        for lineIndex in startLine..<lines.count {
            let line = lines[lineIndex]
            
            // Count braces
            for char in line {
                if char == "{" {
                    braceCount += 1
                    foundOpenBrace = true
                } else if char == "}" {
                    braceCount -= 1
                    if foundOpenBrace && braceCount == 0 {
                        return lineIndex
                    }
                }
            }
        }
        
        return nil
    }
    
    private func findBashConditionalEnd(from startLine: Int, in lines: [String], endKeyword: String) -> Int? {
        for lineIndex in (startLine + 1)..<lines.count {
            let trimmed = lines[lineIndex].trimmingCharacters(in: .whitespaces)
            if trimmed == endKeyword {
                return lineIndex
            }
        }
        return nil
    }
    
    private func findAppleScriptBlockEnd(from startLine: Int, in lines: [String], endKeyword: String) -> Int? {
        for lineIndex in (startLine + 1)..<lines.count {
            let trimmed = lines[lineIndex].trimmingCharacters(in: .whitespaces).lowercased()
            if trimmed == endKeyword.lowercased() || trimmed.hasPrefix(endKeyword.lowercased() + " ") {
                return lineIndex
            }
        }
        return nil
    }
    
    private func getIndentationLevel(of line: String) -> Int {
        var count = 0
        for char in line {
            if char == " " {
                count += 1
            } else if char == "\t" {
                count += 4  // Treat tab as 4 spaces
            } else {
                break
            }
        }
        return count
    }
}