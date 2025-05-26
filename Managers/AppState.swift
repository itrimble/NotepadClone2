import SwiftUI
import UniformTypeIdentifiers
import AppKit

// Split view orientation
enum SplitOrientation: String, CaseIterable {
    case horizontal = "Horizontal"
    case vertical = "Vertical"
}

// Markdown preview mode
enum MarkdownPreviewMode: String, CaseIterable {
    case split = "Split View"
    case preview = "Preview Only"
}

// Custom window delegate to handle window close events
class CustomWindowDelegate: NSObject, NSWindowDelegate {
    weak var appState: AppState?
    
    init(appState: AppState) {
        self.appState = appState
        super.init()
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard let appState = appState else { return true }
        
        // Get current event to check for option key
        if let event = NSApp.currentEvent, event.modifierFlags.contains(.option) {
            // Option-close: Close all tabs
            handleCloseAllTabs()
            return false // We're handling the close
        } else if appState.tabs.count > 1 {
            // Regular close with multiple tabs: Just close the current tab
            if let currentTab = appState.currentTab {
                appState.closeDocument(at: currentTab)
            }
            return false // We handled it by closing just the tab
        }
        
        // With only one tab, proceed with standard window close
        return true
    }
    
    private func handleCloseAllTabs() {
        guard let appState = appState, !appState.tabs.isEmpty else { return }
        
        // Create a copy of tabs to avoid modification during iteration
        let tabCount = appState.tabs.count
        
        // Check if any tabs have unsaved changes
        let hasUnsavedChanges = appState.tabs.contains { $0.hasUnsavedChanges }
        
        if hasUnsavedChanges {
            // Ask once for all tabs with unsaved changes
            let alert = NSAlert()
            alert.messageText = "Close all tabs?"
            alert.informativeText = "There are unsaved changes. Do you want to save them before closing?"
            alert.addButton(withTitle: "Save All")
            alert.addButton(withTitle: "Don't Save")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            
            switch response {
            case .alertFirstButtonReturn: // Save All
                // Save each tab with unsaved changes
                for i in 0..<tabCount {
                    if i < appState.tabs.count && appState.tabs[i].hasUnsavedChanges {
                        appState.currentTab = i
                        appState.saveDocument()
                    }
                }
                
                // Close all tabs after saving
                closeAllTabsWithoutPrompting()
                
            case .alertSecondButtonReturn: // Don't Save
                closeAllTabsWithoutPrompting()
                
            default: // Cancel
                return
            }
        } else {
            // No unsaved changes, close all tabs
            closeAllTabsWithoutPrompting()
        }
    }
    
    private func closeAllTabsWithoutPrompting() {
        guard let appState = appState else { return }
        
        // Close tabs from back to front to avoid index issues
        while !appState.tabs.isEmpty {
            appState.performTabClose(at: appState.tabs.count - 1)
        }
    }
}

// Dummy responder to declare standard AppKit selectors
class DummyResponder: NSResponder {
    @objc func bold(_ sender: Any?) {}
    @objc func italic(_ sender: Any?) {}
    @objc func underline(_ sender: Any?) {}
    @objc func print(_ sender: Any?) {}
}

// Custom sender for find panel actions
class FindPanelActionSender: NSObject {
    let actionTag: Int

    init(actionTag: Int) {
        self.actionTag = actionTag
    }

    var tag: Int {
        return actionTag
    }
}

class AppState: ObservableObject {
    @Published var tabs: [Document] = []
    @Published var currentTab: Int? = nil
    @Published var showStatusBar = true
    
    // Split view support
    @Published var splitViewEnabled = false
    @Published var splitViewOrientation: SplitOrientation = .horizontal
    @Published var splitViewTabIndex: Int? = nil // Index of tab shown in split view
    
    // Theme support
    @Published var appTheme: AppTheme = .system {
        didSet {
            if oldValue != appTheme {
                // Apply the theme
                appTheme.apply()
                // Save the theme preference
                appTheme.save()
                // Update color scheme based on theme
                colorScheme = appTheme.colorScheme
                // Update all documents with the new theme
                for tab in tabs {
                    tab.updateTheme(to: appTheme)
                }
                // Notify observers
                objectWillChange.send()
            }
        }
    }
    
    // Keep colorScheme for backward compatibility
    @Published var colorScheme: ColorScheme? = nil
    
    // User preference for tab switching
    @AppStorage("switch_to_new_tab") var switchToNewTab = false // Default: don't switch
    
    // User preference for showing line numbers
    @AppStorage("show_line_numbers") var showLineNumbers = true
    
    // User preference for showing file explorer
    @AppStorage("show_file_explorer") var showFileExplorer = true
    
    // Find Panel Manager
    var findManager: FindPanelManager!
    
    // AI Settings & Manager
    @Published var aiSettings: AISettings! // Should be initialized before AIManager
    @Published var aiManager: AIManager!

    // Terminal Manager
    // TODO: Uncomment when Terminal files are added to Xcode project
    @Published var terminalManager = TerminalManager()
    
    // Markdown Preview
    @Published var showMarkdownPreview = false
    @Published var markdownPreviewMode: MarkdownPreviewMode = .split
    
    // AI Assistant Panel
    @Published var showAIAssistantPanel: Bool = false
    @Published var requestedPreferenceTab: PreferenceTabType? = nil // For opening Preferences to a specific tab

    // Windows
    private var findInFilesWindow: NSWindow?
    
    // Auto-save timer
    private var autoSaveTimer: Timer?
    
    @AppStorage("auto_save_enabled") private var autoSaveEnabled = true
    @AppStorage("auto_save_interval") private var autoSaveInterval = 30.0
    @AppStorage("restore_session") private var restoreSession = true
    
    // State management queue to prevent publishing issues
    private let stateQueue = DispatchQueue(label: "com.notepadclone.state", qos: .userInitiated)
    private var windowObserver: NSObjectProtocol?
    
    // Window delegate reference
    private var windowDelegates: [NSWindow: CustomWindowDelegate] = [:]
    private var windowObservers: [NSObjectProtocol] = []
    
    // Timestamp-based debouncing for tab creation operations
    private var lastTabCreationTime: Date = Date(timeIntervalSince1970: 0)
    private let minimumTabCreationInterval: TimeInterval = 0.3 // 300ms
    
    var windowTitle: String {
        if let currentTab = currentTab, currentTab < tabs.count {
            let doc = tabs[currentTab]
            let fileName = doc.fileURL?.lastPathComponent ?? doc.displayName
            let saveStatus = doc.hasUnsavedChanges ? " — Edited" : " — Saved"
            return fileName + saveStatus
        }
        return "Notepad Clone"
    }
    
    var currentDocumentIsMarkdown: Bool {
        guard let currentTab = currentTab, currentTab < tabs.count else { return false }
        let doc = tabs[currentTab]
        if let fileURL = doc.fileURL {
            let ext = fileURL.pathExtension.lowercased()
            return ext == "md" || ext == "markdown" || ext == "mdown" || ext == "mkd"
        }
        return false
    }
    
    // MARK: - Dialog Helpers
    
    func showGoToLineDialog() {
        // Post notification to show go to line dialog
        NotificationCenter.default.post(name: .showGoToLineDialog, object: nil)
    }
    
    func showEncodingMenu() {
        // Post notification to show encoding menu
        NotificationCenter.default.post(name: .showEncodingMenu, object: nil)
    }
    
    init() {
        // Initialize AI Settings first as AIManager depends on it
        self.aiSettings = AISettings()
        
        // Initialize AI Manager
        self.aiManager = AIManager(aiSettings: self.aiSettings)

        // Load saved theme
        self.appTheme = AppTheme.loadSavedTheme()
        
        // Initialize find manager with reference to self
        self.findManager = FindPanelManager(appState: self)
        
        // Apply the theme
        appTheme.apply()
        
        // Set color scheme based on theme
        colorScheme = appTheme.colorScheme
        
        // Restore previous session or create new document
        if restoreSession && restorePreviousSession() {
            print("Session restored successfully with \(tabs.count) tabs")
        } else {
            print("No session to restore, creating new document")
            // Create new document if no session to restore
            newDocument()
        }
        
        // Ensure we have at least one tab
        if tabs.isEmpty {
            print("Warning: No tabs after initialization, creating default tab")
            newDocument()
        }
        
        // Ensure currentTab is valid
        if let current = currentTab {
            if current >= tabs.count || current < 0 {
                print("Warning: Invalid currentTab index \(current), resetting to 0")
                currentTab = tabs.isEmpty ? nil : 0
            }
        } else if !tabs.isEmpty {
            print("No currentTab set, selecting first tab")
            currentTab = 0
        }
        
        // Set up auto-save timer
        setupAutoSave()
        setupDisplayChangeHandling()
        setupWindowHandling()
        
        // Save session when app terminates
        setupSessionSaving()
        
        // Set up window delegate for all windows
        setupWindowDelegates()
        
        // Set up code folding notifications
        setupCodeFoldingHandling()
    }
    
    deinit {
        autoSaveTimer?.invalidate()
        if let observer = windowObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // Clean up window observers
        for observer in windowObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        windowObservers.removeAll()
        
        // Save session state on app termination
        saveSessionState()
    }
    
    // MARK: - Window Delegate Setup
    
    private func setupWindowDelegates() {
        // Set up delegate for any existing windows
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Handle existing windows
            for window in NSApp.windows {
                self.setWindowDelegate(for: window)
            }
            
            // Listen for new windows
            let newWindowObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self = self,
                      let window = notification.object as? NSWindow else { return }
                
                self.setWindowDelegate(for: window)
            }
            
            self.windowObservers.append(newWindowObserver)
        }
    }
    
    private func setWindowDelegate(for window: NSWindow) {
        // Only set delegate if we haven't already set one for this window
        if windowDelegates[window] == nil {
            let delegate = CustomWindowDelegate(appState: self)
            window.delegate = delegate
            windowDelegates[window] = delegate
            
            print("Set window delegate for window: \(window)")
        }
    }
    
    // MARK: - Session Management
    
    private func setupSessionSaving() {
        // Save session when app becomes inactive or terminates
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.saveSessionState()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.saveSessionState()
        }
    }
    
    private func saveSessionState() {
        guard restoreSession else { return }
        
        // Save current tab index
        UserDefaults.standard.set(currentTab, forKey: "CurrentTabIndex")
        
        // Save document states
        Document.saveSessionState(documents: tabs)
        
        // Save window state
        saveWindowState()
    }
    
    private func restorePreviousSession() -> Bool {
        // Restore documents
        let restoredDocs = Document.restoreSessionState()
        
        guard !restoredDocs.isEmpty else {
            return false
        }
        
        tabs = restoredDocs
        
        // Update all restored documents with the current theme
        for tab in tabs {
            tab.updateTheme(to: appTheme)
        }
        
        // Restore current tab
        if let savedTabIndex = UserDefaults.standard.value(forKey: "CurrentTabIndex") as? Int,
           savedTabIndex >= 0 && savedTabIndex < tabs.count {
            currentTab = savedTabIndex
        } else {
            currentTab = 0
        }
        
        // Restore window state
        restoreWindowState()
        
        return true
    }
    
    private func saveWindowState() {
        // Save additional window-specific state
        UserDefaults.standard.set(showStatusBar, forKey: "ShowStatusBar")
        
        // Save theme and color scheme
        appTheme.save()
        
        // For backward compatibility - also save colorScheme
        if let colorScheme = colorScheme {
            switch colorScheme {
            case .light:
                UserDefaults.standard.set("light", forKey: "ColorScheme")
            case .dark:
                UserDefaults.standard.set("dark", forKey: "ColorScheme")
            @unknown default:
                UserDefaults.standard.removeObject(forKey: "ColorScheme")
            }
        } else {
            UserDefaults.standard.removeObject(forKey: "ColorScheme")
        }
    }
    
    private func restoreWindowState() {
        // Restore window state
        showStatusBar = UserDefaults.standard.bool(forKey: "ShowStatusBar")
        
        // Load theme (already done in init, but we'll make sure it's applied)
        appTheme = AppTheme.loadSavedTheme()
        appTheme.apply()
        
        // Set color scheme based on theme
        colorScheme = appTheme.colorScheme
        
        // For backward compatibility - check old color scheme settings
        if let colorSchemeString = UserDefaults.standard.string(forKey: "ColorScheme") {
            switch colorSchemeString {
            case "light":
                colorScheme = .light
                appTheme = .light
            case "dark":
                colorScheme = .dark
                appTheme = .dark
            default:
                colorScheme = nil // System default
                appTheme = .system
            }
        }
    }
    
    // MARK: - State Management Helper
    
    private func safeStateUpdate(_ update: @escaping () -> Void) {
        stateQueue.async {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                update()
            }
        }
    }
    
    // MARK: - Window & Display Management
    
    private func setupWindowHandling() {
        windowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let window = notification.object as? NSWindow {
                self?.handleWindowWillClose(window)
            }
        }
    }
    
    private func handleWindowWillClose(_ window: NSWindow) {
        // Save session before window closes
        saveSessionState()
        
        // Clean up any view-related state
        safeStateUpdate {
            self.tabs.forEach { tab in
                // Reset any pending state
                tab.hasUnsavedChanges = false
            }
        }
        
        // Remove window delegate reference
        windowDelegates.removeValue(forKey: window)
    }
    
    private func setupDisplayChangeHandling() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleDisplayChange()
        }
    }
    
    private func handleDisplayChange() {
        // Refresh any view state that might be affected by display changes
        tabs.forEach { tab in
            tab.updateTheme(to: appTheme)
        }
    }
    
    // MARK: - Auto-Save Management
    
    private func setupAutoSave() {
        autoSaveTimer?.invalidate()
        
        if autoSaveEnabled {
            autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { [weak self] _ in
                self?.performAutoSave()
            }
        }
    }
    
    private func autoSave(at index: Int) {
        guard index >= 0 && index < tabs.count,
              tabs[index].hasUnsavedChanges,
              let url = tabs[index].fileURL else { return }
        
        do {
            let content = tabs[index].attributedText
            let range = NSRange(location: 0, length: content.length)
            let data = try content.data(from: range, documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
            try data.write(to: url)
            
            DispatchQueue.main.async {
                self.tabs[index].hasUnsavedChanges = false
                self.objectWillChange.send()
            }
        } catch {
            print("Auto-save error: \(error)")
        }
    }
    
    private func performAutoSave() {
        // Auto-save all tabs that have unsaved changes and a file URL
        for (index, tab) in tabs.enumerated() {
            if tab.hasUnsavedChanges && tab.fileURL != nil {
                autoSave(at: index)
            }
        }
    }
    
    func updateAutoSaveSettings() {
        // Called when preferences are changed
        setupAutoSave()
    }
    
    // MARK: - Code Folding Management
    
    private func setupCodeFoldingHandling() {
        // Listen for code folding toggle requests
        NotificationCenter.default.addObserver(
            forName: .toggleCodeFold,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let region = notification.userInfo?["region"] as? FoldableRegion else { return }
            
            // Toggle fold state for the current document
            if let currentTab = self.currentTab,
               currentTab >= 0 && currentTab < self.tabs.count {
                self.tabs[currentTab].toggleFold(for: region)
            }
        }
    }
    
    // MARK: - Theme Management
    
    // Update the active theme
    func setTheme(_ theme: AppTheme) {
        appTheme = theme
    }
    
    // Get the current theme
    func getCurrentTheme() -> AppTheme {
        return appTheme
    }
    
    // MARK: - File Operations
    
    /// Creates a new document tab
    /// Uses a timestamp-based debouncing mechanism to prevent duplicate tab creation
    func newDocument() {
        // Get current time
        let now = Date()
        
        // Check if enough time has passed since the last tab creation
        let timeElapsed = now.timeIntervalSince(lastTabCreationTime)
        if timeElapsed < minimumTabCreationInterval {
            print("Tab creation debounced - too soon since last creation (\(timeElapsed) seconds)")
            return
        }
        
        // Update the timestamp immediately
        lastTabCreationTime = now
        
        // Use direct main thread update for responsiveness
        DispatchQueue.main.async {
            // Create new document
            let newDoc = Document()
            newDoc.appTheme = self.appTheme
            self.tabs.append(newDoc)
            
            // If this is the first tab, always select it.
            // Otherwise, honor the switchToNewTab preference.
            if self.tabs.count == 1 {
                self.currentTab = 0
            } else {
                if self.switchToNewTab {
                    self.currentTab = self.tabs.count - 1
                }
                // IMPORTANT: Ensure we always have a valid currentTab
                // If currentTab is nil or beyond bounds, set it to a valid value
                if self.currentTab == nil || self.currentTab! >= self.tabs.count {
                    self.currentTab = 0
                }
                
                // DEBUG: Force tab selection to newest tab for debugging
                // TODO: Remove this once tab selection is working properly
                print("FORCE SELECTING newest tab: \(self.tabs.count - 1)")
                self.currentTab = self.tabs.count - 1
            }
            
            // Force UI update
            self.objectWillChange.send()
            
            // Post notification about tab change
            NotificationCenter.default.post(
                name: .appStateTabDidChange,
                object: self
            )
            
            // Debug info
            print("Tab created at \(now), total tabs: \(self.tabs.count), currentTab: \(self.currentTab ?? -1), switchToNewTab: \(self.switchToNewTab)")
        }
    }
    
    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.rtf, UTType.plainText]
        
        // Run panel on main thread
        DispatchQueue.main.async {
            guard panel.runModal() == .OK, let url = panel.url else { return }
            self.openDocument(from: url)
        }
    }
    
    /// Opens a document from a given URL
    /// - Parameter url: The file URL to open
    /// - Returns: True if the file was opened successfully, false otherwise
    @discardableResult
    func openDocument(from url: URL) -> Bool {
        // Check if file is already open
        if let existingIndex = tabs.firstIndex(where: { $0.fileURL == url }) {
            // Switch to existing tab
            DispatchQueue.main.async {
                self.currentTab = existingIndex
                self.objectWillChange.send()
            }
            return true
        }
        
        do {
            let newDoc = Document()
            newDoc.appTheme = self.appTheme
            newDoc.fileURL = url
            
            // Check file extension to determine how to read
            let ext = url.pathExtension.lowercased()
            let plainTextExtensions = ["txt", "js", "jsx", "ts", "tsx", "swift", "py", "sh", "bash", "json", "xml", "html", "css", "md", "log"]
            
            if plainTextExtensions.contains(ext) {
                // Read as plain text
                let text = try String(contentsOf: url, encoding: .utf8)
                newDoc.text = text
                newDoc.attributedText = NSAttributedString(string: text)
            } else {
                // Try to read as RTF or other attributed text
                var documentAttributes: NSDictionary?
                let content = try NSAttributedString(url: url, options: [:], documentAttributes: &documentAttributes)
                
                if content.length == 0 {
                    newDoc.attributedText = NSAttributedString(string: "")
                    newDoc.text = ""
                } else {
                    newDoc.attributedText = content
                    newDoc.text = content.string
                }
            }
            
            newDoc.hasUnsavedChanges = false
            
            // Use direct update for responsiveness
            DispatchQueue.main.async {
                self.tabs.append(newDoc)
                self.currentTab = self.tabs.count - 1
                self.objectWillChange.send()
                
                // Post notification
                NotificationCenter.default.post(
                    name: .appStateTabDidChange,
                    object: self
                )
            }
            
            return true
            
        } catch {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Error Opening File"
                alert.informativeText = "Failed to open \(url.lastPathComponent): \(error.localizedDescription)"
                alert.alertStyle = .warning
                alert.runModal()
            }
            return false
        }
    }
    
    /// Opens multiple documents from URLs, useful for drag and drop
    /// - Parameter urls: Array of file URLs to open
    func openDocuments(from urls: [URL]) {
        for url in urls {
            openDocument(from: url)
        }
    }
    
    func saveDocument() {
        // Safely access current tab
        guard let currentTab = currentTab,
              currentTab >= 0 && currentTab < tabs.count else {
            print("Error: Cannot save - no valid tab selected")
            return
        }
        
        if let url = tabs[currentTab].fileURL {
            saveTo(url: url)
        } else {
            saveDocumentAs()
        }
    }
    
    func saveDocumentAs() {
        // Safely access current tab
        guard let currentTab = currentTab,
              currentTab >= 0 && currentTab < tabs.count else {
            print("Error: Cannot save as - no valid tab selected")
            return
        }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.rtf]
        if let url = tabs[currentTab].fileURL {
            panel.directoryURL = url.deletingLastPathComponent()
            panel.nameFieldStringValue = url.lastPathComponent
        }
        
        DispatchQueue.main.async {
            guard panel.runModal() == .OK, let url = panel.url else { return }
            self.saveTo(url: url)
            self.tabs[currentTab].fileURL = url
        }
    }
    
    private func saveTo(url: URL) {
        // Safely access current tab
        guard let currentTab = currentTab,
              currentTab >= 0 && currentTab < tabs.count else {
            print("Error: Cannot save to URL - no valid tab selected")
            return
        }
        
        do {
            let content = tabs[currentTab].attributedText
            let range = NSRange(location: 0, length: content.length)
            let data = try content.data(from: range, documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
            try data.write(to: url)
            tabs[currentTab].hasUnsavedChanges = false
        } catch {
            let alert = NSAlert()
            alert.messageText = "Error Saving File"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
    
    // MARK: - Tab Management
    
    // Modified for direct updating without safeStateUpdate
    func selectTab(at index: Int) {
        // Auto-save current tab before switching
        if let currentTab = currentTab,
           currentTab >= 0 && currentTab < tabs.count,
           tabs[currentTab].hasUnsavedChanges,
           tabs[currentTab].fileURL != nil {
            autoSave(at: currentTab)
        }
        
        // Validate index bounds before accessing
        guard index >= 0 && index < tabs.count else {
            print("Error: Attempted to select tab at invalid index \(index). Valid range: 0..<\(tabs.count)")
            
            // Reset to a valid tab if available
            if !tabs.isEmpty {
                // Use direct update for responsiveness
                DispatchQueue.main.async {
                    self.currentTab = 0
                    self.objectWillChange.send()
                }
            }
            return
        }
        
        // Use direct update for responsiveness
        DispatchQueue.main.async {
            self.currentTab = index
            self.objectWillChange.send()
            
            // Post notification
            NotificationCenter.default.post(
                name: .appStateTabDidChange,
                object: self
            )
        }
    }
    
    // MARK: - Tab Selection by Number
    func selectTabByNumber(_ number: Int) {
        // Convert 1-based tab number to 0-based index
        let index = number - 1
        selectTab(at: index)
    }
    
    // Modified for more responsive UI
    func closeDocument(at index: Int) {
        // Guard against invalid indices
        guard index >= 0 && index < tabs.count else {
            print("Error: Attempted to close tab at invalid index \(index)")
            return
        }
        
        // Make a defensive copy of the document before closing
        let documentToClose = tabs[index]
        
        if documentToClose.hasUnsavedChanges {
            let alert = NSAlert()
            alert.messageText = "Do you want to save changes?"
            alert.informativeText = "Your changes will be lost if you don't save them."
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Don't Save")
            alert.addButton(withTitle: "Cancel")
            alert.alertStyle = .warning
            
            let response = alert.runModal()
            switch response {
            case .alertFirstButtonReturn: // Save
                // Safely set current tab for saving
                if index < tabs.count && tabs.indices.contains(index) {
                    // Use direct update for responsiveness
                    DispatchQueue.main.async {
                        self.currentTab = index
                        self.saveDocument()
                        
                        // Continue with close after save
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.performTabClose(at: index)
                        }
                    }
                    return
                }
            case .alertSecondButtonReturn: // Don't Save
                break
            default: // Cancel
                return
            }
        }
        
        // Perform the actual close operation
        performTabClose(at: index)
    }
    
    // Make internal instead of private so CustomWindowDelegate can use it
    // Modified for direct updating
    func performTabClose(at index: Int) {
        // Double-check index validity before removal
        guard index < tabs.count else {
            print("Error: Tab array was modified during save operation")
            return
        }
        
        // Use direct update for responsiveness
        DispatchQueue.main.async {
            // Remove the tab
            self.tabs.remove(at: index)
            
            // Safely handle currentTab adjustment
            if self.tabs.isEmpty {
                self.newDocument()
            } else {
                // Adjust currentTab to remain valid
                if self.currentTab == index {
                    self.currentTab = min(index, self.tabs.count - 1)
                } else if let current = self.currentTab, current > index {
                    self.currentTab = current - 1
                }
                
                // Final validation - ensure currentTab is valid
                if let current = self.currentTab {
                    if current >= self.tabs.count || current < 0 {
                        self.currentTab = !self.tabs.isEmpty ? 0 : nil
                    }
                }
            }
            
            // Force a UI refresh
            self.objectWillChange.send()
            
            // Post notification
            NotificationCenter.default.post(
                name: .appStateTabDidChange,
                object: self
            )
        }
    }
    
    // MARK: - Formatting Actions
    func toggleBold() {
        NSApp.sendAction(#selector(DummyResponder.bold(_:)), to: nil, from: nil)
    }

    func toggleItalic() {
        NSApp.sendAction(#selector(DummyResponder.italic(_:)), to: nil, from: nil)
    }

    func toggleUnderline() {
        NSApp.sendAction(#selector(DummyResponder.underline(_:)), to: nil, from: nil)
    }
    
    func alignLeft() {
        NSApp.sendAction(#selector(NSTextView.alignLeft(_:)), to: nil, from: nil)
    }
    
    func alignCenter() {
        NSApp.sendAction(#selector(NSTextView.alignCenter(_:)), to: nil, from: nil)
    }
    
    func alignRight() {
        NSApp.sendAction(#selector(NSTextView.alignRight(_:)), to: nil, from: nil)
    }
    
    func showFontPanel() {
        NSFontManager.shared.orderFrontFontPanel(nil)
    }
    
    // MARK: - Edit Operations
    func undo() {
        NSApp.sendAction(#selector(UndoManager.undo), to: nil, from: nil)
    }
    
    func redo() {
        NSApp.sendAction(#selector(UndoManager.redo), to: nil, from: nil)
    }
    
    func cut() {
        NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
    }
    
    func copy() {
        NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
    }
    
    func paste() {
        NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
    }
    
    func selectAll() {
        NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
    }
    
    // Delete selected text
    func delete() {
        NSApp.sendAction(#selector(NSText.delete(_:)), to: nil, from: nil)
    }
    
    // Auto-indent selected text or current line
    func autoIndentSelection() {
        guard let currentTab = currentTab,
              currentTab >= 0 && currentTab < tabs.count else { return }
        
        let document = tabs[currentTab]
        let language = document.language
        
        // Get the current text view
        guard let textView = NSApp.keyWindow?.firstResponder as? NSTextView else { return }
        
        let selectedRange = textView.selectedRange()
        let text = textView.string
        
        if selectedRange.length > 0 {
            // Auto-indent selected text
            let selectedText = (text as NSString).substring(with: selectedRange)
            let indentedText = SmartIndenter.autoIndentText(selectedText, language: language)
            
            if textView.shouldChangeText(in: selectedRange, replacementString: indentedText) {
                textView.textStorage?.replaceCharacters(in: selectedRange, with: indentedText)
                textView.didChangeText()
                
                // Update selection to cover the newly indented text
                let newRange = NSRange(location: selectedRange.location, length: indentedText.count)
                textView.setSelectedRange(newRange)
            }
        } else {
            // Auto-indent current line
            let lineRange = (text as NSString).lineRange(for: selectedRange)
            let lineText = (text as NSString).substring(with: lineRange)
            let indentedLine = SmartIndenter.autoIndentText(lineText, language: language)
            
            if textView.shouldChangeText(in: lineRange, replacementString: indentedLine) {
                textView.textStorage?.replaceCharacters(in: lineRange, with: indentedLine)
                textView.didChangeText()
                
                // Maintain cursor position relative to line content
                let originalCursorInLine = selectedRange.location - lineRange.location
                let newCursorPosition = lineRange.location + min(originalCursorInLine, indentedLine.count)
                textView.setSelectedRange(NSRange(location: newCursorPosition, length: 0))
            }
        }
    }
    
    // MARK: - Search Operations
    func showFindPanel() {
        findManager.showFindPanel = true
        findManager.showReplacePanel = false
    }

    func showReplacePanel() {
        findManager.showFindPanel = true
        findManager.showReplacePanel = true
    }
    
    func findNext() {
        if findManager.searchText.isEmpty {
            showFindPanel()
        } else {
            findManager.findNext()
        }
    }
    
    func findPrevious() {
        if findManager.searchText.isEmpty {
            showFindPanel()
        } else {
            findManager.findPrevious()
        }
    }
    
    // MARK: - Additional Search Features
    func showFindInFilesWindow() {
        // For now, show a simple alert until FindInFilesView is added to project
        // let alert = NSAlert()
        // alert.messageText = "Find in Files"
        // alert.informativeText = "This feature will search for text across multiple files in a directory."
        // alert.addButton(withTitle: "OK")
        // alert.runModal()
        
        // TODO: Once FindInFilesView.swift is added to Xcode project, use this:
        let findInFilesView = FindInFilesView()
            .environmentObject(self)
            .frame(minWidth: 600, idealWidth: 800, minHeight: 400, idealHeight: 600)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.setFrameAutosaveName("FindInFilesWindow")
        window.contentView = NSHostingView(rootView: findInFilesView)
        window.title = "Find in Files"
        window.makeKeyAndOrderFront(nil)
        
        self.findInFilesWindow = window
    }
    
    func showJumpToLinePanel() {
        // Present a simple input dialog for line number
        let alert = NSAlert()
        alert.messageText = "Jump to Line"
        alert.informativeText = "Enter line number:"
        
        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        inputTextField.placeholderString = "Line number"
        
        alert.accessoryView = inputTextField
        alert.addButton(withTitle: "Go")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let lineNumber = Int(inputTextField.stringValue) {
                jumpToLine(lineNumber)
            }
        }
    }
    
    private func jumpToLine(_ lineNumber: Int) {
        guard let currentTab = currentTab,
              currentTab >= 0 && currentTab < tabs.count else { return }
        
        let text = tabs[currentTab].text
        let lines = text.components(separatedBy: .newlines)
        
        if lineNumber > 0 && lineNumber <= lines.count {
            // Calculate character position for the line
            let lineIndex = lineNumber - 1
            var charPosition = 0
            
            for i in 0..<lineIndex {
                charPosition += lines[i].count + 1 // +1 for newline
            }
            
            // Send the command to jump to that position
            NSApp.sendAction(#selector(NSTextView.scrollRangeToVisible(_:)),
                           to: nil,
                           from: NSRange(location: charPosition, length: 0))
        }
    }
    
    // MARK: - Print Operation
    func printDocument() {
        // Get the current text view and print it
        guard let currentTab = currentTab,
              currentTab >= 0 && currentTab < tabs.count else {
            print("Error: Cannot print - no valid tab selected")
            return
        }
        
        // Create a temporary text view for printing
        let printTextView = NSTextView()
        printTextView.string = tabs[currentTab].text
        
        // Use NSAttributedString if available
        if tabs[currentTab].attributedText.length > 0 {
            printTextView.textStorage?.setAttributedString(tabs[currentTab].attributedText)
        }
        
        // Set up print info
        let printInfo = NSPrintInfo.shared
        printInfo.topMargin = 72.0
        printInfo.bottomMargin = 72.0
        printInfo.leftMargin = 72.0
        printInfo.rightMargin = 72.0
        
        // Create print operation
        let printOperation = NSPrintOperation(view: printTextView, printInfo: printInfo)
        printOperation.showsPrintPanel = true
        printOperation.showsProgressPanel = true
        
        // Set document name
        if let fileName = tabs[currentTab].fileURL?.lastPathComponent {
            printOperation.jobTitle = fileName
        } else {
            printOperation.jobTitle = tabs[currentTab].displayName
        }
        
        // Run print operation directly
        printOperation.run()
    }
    
    // MARK: - Tab Renaming
    func renameTab(at index: Int, newName: String) {
        guard index >= 0 && index < tabs.count else {
            print("Error: Cannot rename tab - invalid index")
            return
        }
        
        // Prevent empty names
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            // Use direct update for responsiveness
            DispatchQueue.main.async {
                self.tabs[index].customName = trimmedName
                self.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Split View Management
    func toggleSplitView() {
        splitViewEnabled.toggle()
        if splitViewEnabled && splitViewTabIndex == nil {
            // Select the next tab for split view, or first tab if only one exists
            if let currentTab = currentTab {
                if tabs.count > 1 {
                    splitViewTabIndex = (currentTab + 1) % tabs.count
                } else {
                    splitViewTabIndex = currentTab
                }
            }
        } else if !splitViewEnabled {
            splitViewTabIndex = nil
        }
    }
    
    func setSplitViewTab(_ index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        splitViewTabIndex = index
    }
    
    func toggleSplitOrientation() {
        splitViewOrientation = splitViewOrientation == .horizontal ? .vertical : .horizontal
    }
}
