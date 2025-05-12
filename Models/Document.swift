import SwiftUI
import AppKit

// Notification names moved to Utilities/Notifications.swift
// No longer declared here to prevent duplicate definitions

class Document: ObservableObject, Identifiable {
    // MARK: - Identifiable (Persistent across sessions)
    let id: UUID
    
    @Published var text = "" {
        didSet {
            if oldValue != text && !isUpdatingFromAttributed {
                coalesceEdits()
                // Use immediate word counting instead of delayed
                updateWordCountImmediate()
                hasUnsavedChanges = true
                applyHighlighting()
                
                // Notify listeners that text has changed - critical for UI updates
                NotificationCenter.default.post(name: .documentTextDidChange, object: self)
            }
        }
    }
    
    @Published var attributedText = NSAttributedString() {
        didSet {
            if oldValue != attributedText {
                hasUnsavedChanges = true
                // Only update plain text if it's actually different
                let newPlainText = attributedText.string
                if newPlainText != text {
                    // Use a flag to prevent circular updates
                    isUpdatingFromAttributed = true
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.text = newPlainText
                        self.isUpdatingFromAttributed = false
                        // Force UI refresh
                        self.objectWillChange.send()
                        
                        // Notify listeners
                        NotificationCenter.default.post(name: .documentTextDidChange, object: self)
                    }
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
    private var lastEditTime: TimeInterval = 0
    private let editCoalescingInterval: TimeInterval = 1.0
    
    // MARK: - Initializers
    
    init() {
        self.id = UUID() // Create new unique ID
        setupDocument()
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
            self?.updateTheme()
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
        
        // Directly update on main thread without delay
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.wordCount != count {
                self.wordCount = count
                // Explicitly notify observers
                self.objectWillChange.send()
                
                // Notify specifically about word count updates
                NotificationCenter.default.post(
                    name: .documentStateDidChange,
                    object: self,
                    userInfo: ["propertyChanged": "wordCount"]
                )
            }
        }
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
        let isDarkMode = NSApplication.shared.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let currentTheme = isDarkMode ? SyntaxTheme.dark : SyntaxTheme.default
        highlighter = SyntaxHighlighter(language: language, theme: currentTheme)
    }
    
    func applyHighlighting() {
        guard language != .none else {
            // For plain text, just use default attributes
            let defaultAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
                .foregroundColor: NSColor.labelColor
            ]
            let plainText = NSAttributedString(string: text, attributes: defaultAttributes)
            DispatchQueue.main.async {
                self.attributedText = plainText
            }
            return
        }
        
        // Cancel any pending highlighting
        highlightTimer?.invalidate()
        
        // Check if text is small enough for immediate highlighting
        if text.count < 5000 {
            // Immediate highlighting for small files
            performHighlighting()
        } else {
            // Debounced highlighting for larger files
            highlightTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
                self?.performHighlighting()
            }
        }
    }
    
    private func performHighlighting() {
        guard let highlighter = self.highlighter else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let highlighted = highlighter.highlight(self.text)
            DispatchQueue.main.async {
                // Syntax highlighting updates don't need to be part of undo stack
                // as they're automatically reapplied when text changes
                self.attributedText = highlighted
                
                // Force UI refresh
                self.objectWillChange.send()
            }
        }
    }
    
    func updateTheme() {
        updateHighlighter()
        applyHighlighting()
    }
    
    // MARK: - Document State Management
    
    struct DocumentState: Codable {
        let id: String // Store UUID as string for JSON serialization
        let text: String
        let language: String // Stored as string for serialization
        let customName: String?
        let fileURLPath: String?
        
        // Initialize from Document
        init(from document: Document) {
            self.id = document.id.uuidString
            self.text = document.text
            self.language = document.language.rawValue
            self.customName = document.customName
            self.fileURLPath = document.fileURL?.path
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
        if let encoded = try? JSONEncoder().encode(states) {
            UserDefaults.standard.set(encoded, forKey: "DocumentSessionState")
        }
    }
    
    // Restore documents from UserDefaults
    static func restoreSessionState() -> [Document] {
        guard let data = UserDefaults.standard.data(forKey: "DocumentSessionState"),
              let states = try? JSONDecoder().decode([DocumentState].self, from: data) else {
            return []
        }
        
        return states.map { Document.fromState($0) }
    }
}
