import SwiftUI
import UniformTypeIdentifiers
import AppKit

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
    @Published var colorScheme: ColorScheme? = nil
    
    // Find Panel Manager
    var findManager: FindPanelManager!
    
    // Auto-save timer
    private var autoSaveTimer: Timer?
    
    @AppStorage("auto_save_enabled") private var autoSaveEnabled = true
    @AppStorage("auto_save_interval") private var autoSaveInterval = 30.0
    
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
        // Initialize find manager with reference to self
        self.findManager = FindPanelManager(appState: self)
        // Start with one empty document
        newDocument()
        
        // Set up auto-save timer
        setupAutoSave()
    }
    
    deinit {
        autoSaveTimer?.invalidate()
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
            // Optionally show user alert for save errors
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
    
    // MARK: - File Operations
    func newDocument() {
        let newDoc = Document()
        tabs.append(newDoc)
        currentTab = tabs.count - 1
    }
    
    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.rtf, UTType.plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        
        // Check if file is already open
        if let existingIndex = tabs.firstIndex(where: { $0.fileURL == url }) {
            currentTab = existingIndex
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
            
            tabs.append(newDoc)
            currentTab = tabs.count - 1
            
        } catch {
            let alert = NSAlert()
            alert.messageText = "Error Opening File"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
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
        guard panel.runModal() == .OK, let url = panel.url else { return }
        saveTo(url: url)
        tabs[currentTab].fileURL = url
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
                currentTab = 0
            }
            return
        }
        
        currentTab = index
    }
    
    // MARK: - Tab Selection by Number
    func selectTabByNumber(_ number: Int) {
        // Convert 1-based tab number to 0-based index
        let index = number - 1
        
        // Use the existing selectTab method with validation
        selectTab(at: index)
    }
    
    func closeDocument(at index: Int) {
        // Validate index bounds
        guard index >= 0 && index < tabs.count else {
            print("Error: Attempted to close tab at invalid index \(index). Valid range: 0..<\(tabs.count)")
            return
        }
        
        if tabs[index].hasUnsavedChanges {
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
                currentTab = index
                saveDocument()
                if tabs.count > index && tabs[index].hasUnsavedChanges { // If save was cancelled
                    return
                }
            case .alertSecondButtonReturn: // Don't Save
                break
            default: // Cancel
                return
            }
        }
        
        tabs.remove(at: index)
        
        if tabs.isEmpty {
            newDocument()
        } else if currentTab == index {
            currentTab = min(index, tabs.count - 1)
        } else if let current = currentTab, current > index {
            currentTab = current - 1
        }
        
        // Final validation
        if let current = currentTab, current >= tabs.count || current < 0 {
            currentTab = tabs.isEmpty ? nil : 0
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
        
        // Run print operation
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
            tabs[index].customName = trimmedName
        }
    }
}
