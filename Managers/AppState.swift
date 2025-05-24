import SwiftUI
import UniformTypeIdentifiers
import AppKit

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
                // Notify observers
                objectWillChange.send()
            }
        }
    }
    
    // Keep colorScheme for backward compatibility
    @Published var colorScheme: ColorScheme? = nil
    
    // User preference for tab switching
    @AppStorage("switch_to_new_tab") var switchToNewTab = false // Default: don't switch
    
    // Find Panel Manager
    var findManager: FindPanelManager!
    
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
    
    init() {
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
            print("Session restored successfully")
        } else {
            // Create new document if no session to restore
            newDocument()
        }
        
        // Set up auto-save timer
        setupAutoSave()
        setupDisplayChangeHandling()
        setupWindowHandling()
        
        // Save session when app terminates
        setupSessionSaving()
        
        // Set up window delegate for all windows
        setupWindowDelegates()
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
            tab.updateTheme()
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
            self.tabs.append(newDoc)
            
            // If this is the first tab, always select it.
            // Otherwise, honor the switchToNewTab preference.
            if self.tabs.count == 1 {
                self.currentTab = 0
            } else {
                if self.switchToNewTab {
                    self.currentTab = self.tabs.count - 1
                }
            }
            
            // Force UI update
            self.objectWillChange.send()
            
            // Post notification about tab change
            NotificationCenter.default.post(
                name: .appStateTabDidChange,
                object: self
            )
            
            // Debug info
            print("Tab created at \(now), total tabs: \(self.tabs.count)")
        }
    }
    
    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.rtf, UTType.plainText]
        
        // Run panel on main thread
        DispatchQueue.main.async {
            guard panel.runModal() == .OK, let url = panel.url else { return }
            
            // Check if file is already open
            if let existingIndex = self.tabs.firstIndex(where: { $0.fileURL == url }) {
                // Use direct update for responsiveness
                DispatchQueue.main.async {
                    self.currentTab = existingIndex
                    self.objectWillChange.send()
                }
                return
            }
            
            do {
                var documentAttributes: NSDictionary?
                let content = try NSAttributedString(url: url, options: [:], documentAttributes: &documentAttributes)
                
                let newDoc = Document()
                if content.length == 0 {
                    newDoc.attributedText = NSAttributedString(string: "")
                    newDoc.text = ""
                } else {
                    newDoc.attributedText = content
                    newDoc.text = content.string
                }
                newDoc.fileURL = url
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
                
            } catch {
                let alert = NSAlert()
                alert.messageText = "Error Opening File"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
                alert.runModal()
            }
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
}
