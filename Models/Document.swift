import SwiftUI
import AppKit

// Notification names moved to Utilities/Notifications.swift
// No longer declared here to prevent duplicate definitions

class Document: ObservableObject, Identifiable {
    // MARK: - Identifiable (Persistent across sessions)
    let id: UUID
    
    @Published var text = "" {
        didSet {
            if oldValue != text && !isUpdatingFromAttributed && !isApplyingHighlight {
                coalesceEdits()
                // Defer word count update to avoid state modification during view updates
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
                    self?.updateWordCountImmediate()
                }
                hasUnsavedChanges = true
                // Defer highlighting to avoid state modification during view updates
                scheduleHighlighting()
            }
        }
    }
    
    @Published var attributedText = NSAttributedString() {
        didSet {
            if oldValue != attributedText && !isApplyingHighlight {
                hasUnsavedChanges = true
                // Only update plain text if it's actually different
                let newPlainText = attributedText.string
                if newPlainText != text {
                    // Use a flag to prevent circular updates
                    isUpdatingFromAttributed = true
                    text = newPlainText
                    isUpdatingFromAttributed = false
                }
            }
        }
    }
    
    @Published var wordCount: Int = 0
    @Published var hasUnsavedChanges = false
    @Published var customName: String? = nil  // For custom tab names
    @Published var language: SyntaxHighlighter.Language = .none {
        didSet {
            if oldValue != language {
                updateHighlighter()
                applyHighlighting()
            }
        }
    }
    
    // Cursor and selection tracking
    @Published var cursorPosition: Int = 0
    @Published var selectedRange: NSRange = NSRange(location: 0, length: 0)
    @Published var lineNumber: Int = 1
    @Published var columnNumber: Int = 1
    @Published var encoding: String.Encoding = .utf8
    
    // Code folding state
    @Published var foldedRegions: Set<FoldableRegion> = []
    
    // Theme tracking
    var appTheme: AppTheme = .system {
        didSet {
            if oldValue != appTheme {
                updateHighlighter()
                applyHighlighting()
            }
        }
    }
    
    var fileURL: URL? {
        didSet {
            // Detect language from file extension
            language = SyntaxHighlighter.Language.detect(from: fileURL)
        }
    }
    
    var displayName: String {
        // Prioritize custom name, then file name, then fallback to "Untitled"
        if let customName = customName {
            return customName
        }
        if let url = fileURL {
            return url.lastPathComponent
        }
        return "Untitled"
    }
    
    private var wordCountTimer: Timer?
    private var highlightTimer: Timer?
    private var highlighter: SyntaxHighlighter?
    private var isUpdatingFromAttributed = false
    private var isApplyingHighlight = false
    private var lastEditTime: TimeInterval = 0
    private let editCoalescingInterval: TimeInterval = 1.0
    
    // MARK: - Initializers
    
    init() {
        self.id = UUID() // Create new unique ID
        setupDocument()
        
        // Initialize with empty attributed text with proper attributes
        let theme = appTheme.syntaxTheme()
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: theme.textColor
        ]
        self.attributedText = NSAttributedString(string: "", attributes: defaultAttributes)
    }
    
    // Initialize with existing ID (for session restoration)
    init(id: UUID) {
        self.id = id
        setupDocument()
    }
    
    private func setupDocument() {
        // Initial word count
        updateWordCountImmediate()
        updateHighlighter()
        
        // Observe system appearance changes
        NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeBackingPropertiesNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Re-apply highlighting when system appearance changes
            self?.updateHighlighter()
            self?.applyHighlighting()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        wordCountTimer?.invalidate()
        highlightTimer?.invalidate()
    }
    
    // MARK: - Undo/Redo Support
    
    private func coalesceEdits() {
        let now = Date().timeIntervalSince1970
        
        // Coalesce rapid edits to prevent too many undo states
        if now - lastEditTime < editCoalescingInterval {
            // Note: NSTextView's undo manager automatically handles text coalescing
            // This is just a timestamp for potential future use
        }
        
        lastEditTime = now
    }
    
    // MARK: - Word Count Management
    
    // Immediate word counting for UI responsiveness
    private func updateWordCountImmediate() {
        var count = 0
        text.enumerateSubstrings(in: text.startIndex..<text.endIndex,
                                 options: .byWords) { _, _, _, _ in
            count += 1
        }
        
        // Update synchronously if count changed
        if wordCount != count {
            wordCount = count
        }
    }
    
    // MARK: - Cursor and Selection Management
    
    func updateCursorPosition(from range: NSRange) {
        // Only update if actually changed to avoid unnecessary updates
        if selectedRange != range {
            selectedRange = range
            cursorPosition = range.location
            
            // Calculate line and column
            let (line, column) = calculateLineAndColumn(for: range.location)
            lineNumber = line
            columnNumber = column
        }
    }
    
    private func calculateLineAndColumn(for position: Int) -> (line: Int, column: Int) {
        guard position <= text.count else { return (1, 1) }
        
        var line = 1
        var column = 1
        var currentPosition = 0
        
        for char in text {
            if currentPosition == position {
                break
            }
            
            if char == "\n" {
                line += 1
                column = 1
            } else {
                column += 1
            }
            
            currentPosition += 1
        }
        
        return (line, column)
    }
    
    // Keep original method for backward compatibility
    private func updateWordCount() {
        // Cancel any pending updates
        wordCountTimer?.invalidate()
        
        // First update immediately for responsive UI
        updateWordCountImmediate()
        
        // If needed, schedule a more thorough analysis
        wordCountTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            // This is now redundant but kept for backward compatibility
            self?.updateWordCountImmediate()
        }
    }
    
    // MARK: - Syntax Highlighting
    
    private func updateHighlighter() {
        let syntaxTheme = appTheme.syntaxTheme()
        highlighter = SyntaxHighlighter(language: language, theme: syntaxTheme)
    }
    
    private func scheduleHighlighting() {
        // Cancel any pending highlighting
        highlightTimer?.invalidate()
        
        // Schedule highlighting with a small delay to batch rapid edits
        highlightTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { [weak self] _ in
            self?.applyHighlighting()
        }
    }
    
    func applyHighlighting() {
        guard language != .none else {
            // For plain text, use theme-aware colors
            let syntaxTheme = appTheme.syntaxTheme()
            let defaultAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
                .foregroundColor: syntaxTheme.textColor
            ]
            let plainText = NSAttributedString(string: text, attributes: defaultAttributes)
            isApplyingHighlight = true
            attributedText = plainText
            isApplyingHighlight = false
            return
        }
        
        // Perform highlighting based on file size
        if text.count < 5000 {
            // Immediate highlighting for small files
            performHighlighting()
        } else {
            // Async highlighting for larger files
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.performHighlighting()
            }
        }
    }
    
    private func performHighlighting() {
        guard let highlighter = self.highlighter else { return }
        
        let currentText = self.text
        let highlighted = highlighter.highlight(currentText)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Only update if text hasn't changed while highlighting
            if self.text == currentText {
                self.isApplyingHighlight = true
                self.attributedText = highlighted
                self.isApplyingHighlight = false
            }
        }
    }
    
    func updateTheme(to theme: AppTheme) {
        appTheme = theme
    }
    
    // MARK: - Code Folding Management
    
    func toggleFold(for region: FoldableRegion) {
        if foldedRegions.contains(region) {
            unfoldRegion(region)
        } else {
            foldRegion(region)
        }
    }
    
    func foldRegion(_ region: FoldableRegion) {
        var foldedRegion = region
        foldedRegion.isFolded = true
        foldedRegions.insert(foldedRegion)
        hasUnsavedChanges = true
        
        // Notify that fold state changed
        NotificationCenter.default.post(
            name: .codeFoldStateDidChange,
            object: self,
            userInfo: ["region": foldedRegion, "action": "fold"]
        )
    }
    
    func unfoldRegion(_ region: FoldableRegion) {
        foldedRegions.remove(region)
        hasUnsavedChanges = true
        
        // Notify that fold state changed
        NotificationCenter.default.post(
            name: .codeFoldStateDidChange,
            object: self,
            userInfo: ["region": region, "action": "unfold"]
        )
    }
    
    func isFolded(_ region: FoldableRegion) -> Bool {
        return foldedRegions.contains(region)
    }
    
    // MARK: - Document State Management
    
    struct FoldableRegionState: Codable {
        let startLine: Int
        let endLine: Int
        let startColumn: Int
        let endColumn: Int
        let type: String  // Store FoldType as string
        let startText: String
        
        init(from region: FoldableRegion) {
            self.startLine = region.startLine
            self.endLine = region.endLine
            self.startColumn = region.startColumn
            self.endColumn = region.endColumn
            self.type = region.type.rawValue
            self.startText = region.startText
        }
        
        func toFoldableRegion() -> FoldableRegion {
            let foldType = FoldableRegion.FoldType(rawValue: type) ?? .braces
            return FoldableRegion(
                startLine: startLine,
                endLine: endLine,
                startColumn: startColumn,
                endColumn: endColumn,
                type: foldType,
                startText: startText,
                isFolded: true  // This will be folded since it's in the saved state
            )
        }
    }
    
    struct DocumentState: Codable {
        let id: String // Store UUID as string for JSON serialization
        let text: String
        let language: String // Stored as string for serialization
        let customName: String?
        let fileURLPath: String?
        let foldedRegions: [FoldableRegionState]
        
        // Initialize from Document
        init(from document: Document) {
            self.id = document.id.uuidString
            self.text = document.text
            self.language = document.language.rawValue
            self.customName = document.customName
            self.fileURLPath = document.fileURL?.path
            self.foldedRegions = document.foldedRegions.map { FoldableRegionState(from: $0) }
        }
    }
    
    func saveState() -> DocumentState {
        return DocumentState(from: self)
    }
    
    func restoreState(_ state: DocumentState) {
        // Note: ID should already match when restoring
        text = state.text
        if let restoredLanguage = SyntaxHighlighter.Language(rawValue: state.language) {
            language = restoredLanguage
        }
        customName = state.customName
        if let urlPath = state.fileURLPath {
            fileURL = URL(fileURLWithPath: urlPath)
        }
        foldedRegions = Set(state.foldedRegions.map { $0.toFoldableRegion() })
    }
    
    // MARK: - Session State Management
    
    static func fromState(_ state: DocumentState) -> Document {
        // Create document with existing ID
        guard let restoredID = UUID(uuidString: state.id) else {
            print("Warning: Invalid UUID string, creating new document")
            return Document() // Fallback to new document
        }
        
        let document = Document(id: restoredID)
        document.restoreState(state)
        return document
    }
}

// MARK: - Session State Management
extension Document {
    // Save all document states to UserDefaults
    static func saveSessionState(documents: [Document]) {
        let states = documents.map { $0.saveState() }
        do {
            let encoded = try JSONEncoder().encode(states)
            UserDefaults.standard.set(encoded, forKey: "DocumentSessionState")
        } catch {
            print("Error encoding document session states: \(error)")
        }
    }
    
    // Restore documents from UserDefaults
    static func restoreSessionState() -> [Document] {
        guard let data = UserDefaults.standard.data(forKey: "DocumentSessionState") else {
            return []
        }
        do {
            let states = try JSONDecoder().decode([DocumentState].self, from: data)
            return states.map { Document.fromState($0) }
        } catch {
            print("Error decoding document session states: \(error)")
            return []
        }
    }
}
