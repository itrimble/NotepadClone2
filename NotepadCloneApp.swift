//
//  NotepadCloneApp.swift (Updated for Detachable Tabs - Phase 1)
//  NotepadClone2
//
//  Created by Ian Trimble on 5/10/25.
//  Updated by Ian Trimble on 5/13/25. // Assuming date update for new changes
//  Version: 2025-05-13
//

import SwiftUI
// import NotepadClone2

@main
struct NotepadCloneApp: App {
    // Main AppState for the initial window
    @StateObject var mainAppState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @Environment(\.openWindow) var openWindow

    // Define the notification name
    static let requestNewWindowForDocumentID = Notification.Name("requestNewWindowForDocumentID")

    init() {
        // Register observer for detaching tabs
        NotificationCenter.default.addObserver(
            forName: NotepadCloneApp.requestNewWindowForDocumentID,
            object: nil,
            queue: .main
        ) { notification in
            if let documentID = notification.userInfo?["documentID"] as? UUID {
                print("Received request to open new window for document ID: \(documentID)")
                // Ensure this is called on the main thread if openWindow requires it
                // (SwiftUI environment actions are generally main-thread safe)
                self.openWindow(id: "document-window", value: documentID)
            } else {
                print("Error: Could not extract documentID from notification for new window.")
            }
        }
    }
    
    var body: some Scene {
        // Main Window Group
        WindowGroup(id: "main") { // Provide an explicit ID for the main window group
            ContentView()
                .environmentObject(mainAppState) // Use mainAppState for the primary window
                .onAppear {
                    AppDelegate.setAppState(mainAppState) // Connect AppDelegate to the main AppState
                    setupWindowConfiguration(for: NSApp.mainWindow) // Configure main window
                }
        }
        .defaultSize(width: 1000, height: 700)
        .commands {
            // Commands will apply to the focused window, which will have its own AppState instance.
            // For actions, we need to ensure they target the AppState of the *current* window.
            // This is typically handled by SwiftUI if @EnvironmentObject is used correctly in command targets,
            // but global commands here might need a way to get the focused AppState if not using direct @FocusedValue.
            // For now, assuming appState in commands refers to the focused window's appState.
            // This part needs careful review if commands don't work as expected for secondary windows.
            // The current structure with menu commands directly calling 'appState.method()'
            // will refer to 'mainAppState' due to the @StateObject here.
            // This needs to be refactored if commands should target the focused scene's AppState.
            // A common solution is to move command definitions into the ContentView or a Commands struct
            // that can access the focused scene's environment.
            // For this subtask, we'll leave commands as they are, but acknowledge this limitation.
            // Let's assume 'appState' in commands implicitly means 'mainAppState' for now.
            // To make commands work for any window, we'd need a different approach.
            // However, the prompt doesn't ask to refactor commands, just to set up new window creation.

            // **Important Note for Command Targeting:**
            // The `appState` used in the commands below will be `mainAppState`.
            // To make them context-aware for multiple windows, this structure needs changes,
            // e.g., by using `@FocusedValue(\.appState)` or passing AppState via menu item actions.
            // For simplicity of this subtask, this is not addressed yet.

            // Settings/Preferences in the app menu
            CommandGroup(after: .appInfo) {
                Divider()
                Button("Preferences...") {
                    // This should open preferences for the main app or focused window.
                    // If `mainAppState` holds global prefs, this is okay.
                    openPreferencesWindow(appState: mainAppState)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            
            // Remove default system View menu items to prevent duplication
            CommandGroup(replacing: .toolbar) { }
            CommandGroup(replacing: .sidebar) { }
            
            // File Menu
            CommandGroup(replacing: .newItem) {
                Button(action: {
                    // Debug info to track when command is executed
                    print("New Tab command executed: \(Date())")
                    appState.newDocument()
                }) {
                    Label("New Tab", systemImage: "plus")
                }
                .keyboardShortcut("t", modifiers: [.command])
                
                Button(action: {
                    appState.openDocument()
                }) {
                    Label("Open...", systemImage: "folder.badge.plus")
                }
                .keyboardShortcut("o")
                
                Button(action: { appState.saveDocument() }) {
                    Label("Save", systemImage: "doc.badge.plus")
                }
                .keyboardShortcut("s")
                
                Button(action: { appState.saveDocumentAs() }) {
                    Label("Save As...", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("S")
                
                Divider()
                
                Button(action: {
                    if let currentTab = appState.currentTab {
                        appState.closeDocument(at: currentTab)
                    }
                }) {
                    Label("Close Tab", systemImage: "xmark")
                }
                .keyboardShortcut("w")

                Button(action: {
                    NSApp.keyWindow?.close()
                }) {
                    Label("Close Window", systemImage: "xmark.circle")
                }
                .keyboardShortcut("w", modifiers: [.command, .shift])
                
                Divider()
                
                Button(action: { appState.printDocument() }) {
                    Label("Print...", systemImage: "printer")
                }
                .keyboardShortcut("p")
            }
            
            // Edit Menu
            CommandGroup(replacing: .textEditing) {
                Button(action: { appState.undo() }) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .keyboardShortcut("z")
                
                Button(action: { appState.redo() }) {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                }
                .keyboardShortcut("Z")
                
                Divider()
                
                Button(action: { appState.cut() }) {
                    Label("Cut", systemImage: "scissors")
                }
                .keyboardShortcut("x")
                
                Button(action: { appState.copy() }) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .keyboardShortcut("c")
                
                Button(action: { appState.paste() }) {
                    Label("Paste", systemImage: "doc.on.clipboard")
                }
                .keyboardShortcut("v")
                
                Button(action: { appState.selectAll() }) {
                    Label("Select All", systemImage: "checkmark.rectangle")
                }
                .keyboardShortcut("a")
                
                Divider()
                
                Button(action: { appState.delete() }) {
                    Label("Delete", systemImage: "delete.left")
                }
                .keyboardShortcut(.delete)
            }
            
            // Search Menu
            CommandMenu("Search") {
                Button(action: { appState.showFindPanel() }) {
                    Label("Find", systemImage: "magnifyingglass")
                }
                .keyboardShortcut("f")
                
                Button(action: { appState.showReplacePanel() }) {
                    Label("Find and Replace", systemImage: "arrow.left.arrow.right")
                }
                .keyboardShortcut("f", modifiers: [.command, .option])
                
                Button(action: { appState.findNext() }) {
                    Label("Find Next", systemImage: "arrow.down.circle")
                }
                .keyboardShortcut("g")
                
                Button(action: { appState.findPrevious() }) {
                    Label("Find Previous", systemImage: "arrow.up.circle")
                }
                .keyboardShortcut("G")
                
                Divider()
                
                Button(action: { appState.showFindInFilesWindow() }) {
                    Label("Find in Files...", systemImage: "doc.text.magnifyingglass")
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
                
                Divider()
                
                Button(action: { appState.showJumpToLinePanel() }) {
                    Label("Jump to Line", systemImage: "arrow.right.to.line")
                }
                .keyboardShortcut("l")
                
                Divider()
                
                Button(action: { appState.autoIndentSelection() }) {
                    Label("Auto Indent", systemImage: "increase.indent")
                }
                .keyboardShortcut("i", modifiers: [.command, .option])
            }
            
            // Format Menu
            CommandMenu("Format") {
                Button(action: { appState.toggleBold() }) {
                    Label("Bold", systemImage: "bold")
                }
                .keyboardShortcut("b")
                
                Button(action: { appState.toggleItalic() }) {
                    Label("Italic", systemImage: "italic")
                }
                .keyboardShortcut("i")
                
                Button(action: { appState.toggleUnderline() }) {
                    Label("Underline", systemImage: "underline")
                }
                .keyboardShortcut("u")
                
                Divider()
                
                Button(action: { appState.alignLeft() }) {
                    Label("Align Left", systemImage: "text.alignleft")
                }
                .keyboardShortcut("{")
                
                Button(action: { appState.alignCenter() }) {
                    Label("Center", systemImage: "text.aligncenter")
                }
                .keyboardShortcut("|")
                
                Button(action: { appState.alignRight() }) {
                    Label("Align Right", systemImage: "text.alignright")
                }
                .keyboardShortcut("}")
                
                Divider()
                
                Button(action: { appState.showFontPanel() }) {
                    Label("Font...", systemImage: "textformat")
                }
                .keyboardShortcut("t", modifiers: [.command, .option])
            }
            
            // View Menu (includes Enter Full Screen from system menu)
            CommandMenu("View") {
                // Enter Full Screen (moved from system View menu)
                Button(action: {
                    if let window = NSApp.mainWindow {
                        window.toggleFullScreen(nil)
                    }
                }) {
                    Label("Enter Full Screen", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .keyboardShortcut("f", modifiers: [.control, .command])
                
                Divider()
                
                // Updated to use a single Theme menu
                Menu("Theme") {
                    ForEach(AppTheme.allCases) { theme in
                        Button(action: {
                            appState.setTheme(theme)
                        }) {
                            HStack {
                                Image(systemName: theme.iconName)
                                Text(theme.rawValue)
                                if appState.appTheme == theme {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
                Toggle(isOn: $appState.showStatusBar) {
                    Label("Status Bar", systemImage: "rectangle.bottomthird.inset.filled")
                }
                
                Toggle(isOn: $appState.showLineNumbers) {
                    Label("Line Numbers", systemImage: "number")
                }
                .keyboardShortcut("L", modifiers: [.command, .shift])
                
                Toggle(isOn: $appState.showFileExplorer) {
                    Label("File Explorer", systemImage: "folder")
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                
                Toggle(isOn: $appState.terminalManager.showTerminal) {
                    Label("Terminal", systemImage: "terminal")
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                
                Divider()
                
                Toggle(isOn: $appState.splitViewEnabled) {
                    Label("Split Editor", systemImage: "rectangle.split.2x1")
                }
                .keyboardShortcut("\\", modifiers: [.command])
                
                if appState.splitViewEnabled {
                    Button(action: { appState.toggleSplitOrientation() }) {
                        Label("Toggle Split Direction", systemImage: "arrow.left.arrow.right")
                    }
                    .keyboardShortcut("\\", modifiers: [.command, .shift])
                }
                
                Divider()
                
                // Markdown Preview
                Toggle(isOn: $appState.showMarkdownPreview) {
                    Label("Markdown Preview", systemImage: "doc.richtext")
                }
                .disabled(!appState.currentDocumentIsMarkdown)
                .keyboardShortcut("m", modifiers: [.command, .shift])
                
                if appState.showMarkdownPreview && appState.currentDocumentIsMarkdown {
                    Picker("Preview Mode", selection: $appState.markdownPreviewMode) {
                        ForEach(MarkdownPreviewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }

            // AI Menu (New)
            CommandMenu("AI") {
                Button("AI Preferences...") {
                    appState.requestedPreferenceTab = .ai // Set the desired tab
                    openPreferencesWindow() 
                }
                // This menu item should be enabled now as the functionality is present.

                Divider()

                Toggle(isOn: $appState.showAIAssistantPanel) {
                     Label("Show AI Assistant Panel", systemImage: "brain.head.profile.fill")
                }
                .keyboardShortcut("a", modifiers: [.option, .command])

                // Placeholder for selecting different AI models/services
                Menu("Select AI Model") {
                    Button("Ollama (Local)") {}
                        .disabled(true) // Example, make selectable later
                    Button("Claude API") {}
                        .disabled(true)
                    Button("OpenAI API") {}
                        .disabled(true)
                }
                .disabled(true) // Disable the whole sub-menu for now
            }
            
            // Tab Selection Keyboard Shortcuts
            CommandGroup(after: .windowArrangement) {
                ForEach(1...9, id: \.self) { number in
                    Button(action: {
                        appState.selectTabByNumber(number)
                    }) {
                        Label("Tab \(number)", systemImage: "\(number).square")
                    }
                    .keyboardShortcut(KeyEquivalent(Character(String(number))), modifiers: .command)
                }
                
                // Additional tab navigation shortcuts
                Button(action: {
                    if let current = appState.currentTab, current < appState.tabs.count - 1 {
                        appState.selectTab(at: current + 1)
                    }
                }) {
                    Label("Next Tab", systemImage: "arrow.right")
                }
                .keyboardShortcut("]", modifiers: .command)
                
                Button(action: {
                    if let current = appState.currentTab, current > 0 {
                        appState.selectTab(at: current - 1)
                    }
                }) {
                    Label("Previous Tab", systemImage: "arrow.left")
                }
                .keyboardShortcut("[", modifiers: .command)
            }
            
            // Help menu
            CommandGroup(after: .help) {
                Button(action: { openHelpWindow() }) {
                    Label("NotepadClone2 Help", systemImage: "questionmark.circle")
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }
    }
    
    // Configure window to match Notepad++ style
    private func setupWindowConfiguration() {
        DispatchQueue.main.async {
            // Find the main window
            if let window = NSApplication.shared.windows.first {
                // Configure as needed
                window.titleVisibility = .visible
                window.titlebarAppearsTransparent = false
                
                // Set minimum window size
                window.minSize = NSSize(width: 800, height: 600)
                
                // If window is too small, resize it
                if window.frame.width < 800 || window.frame.height < 600 {
                    var frame = window.frame
                    frame.size = NSSize(width: max(800, frame.width), height: max(600, frame.height))
                    window.setFrame(frame, display: true)
                }
                
                // Set up window restoration using the concrete class
                window.isRestorable = true
                // window.restorationClass = NotepadWindowRestorer.self // Commented out for diagnostics
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func openPreferencesWindow() {
        let preferencesWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        preferencesWindow.center()
        // Pass appState to PreferencesWindow if it needs it via EnvironmentObject
        preferencesWindow.contentView = NSHostingView(rootView: PreferencesWindow().environmentObject(appState))
        preferencesWindow.title = "Preferences"
        preferencesWindow.makeKeyAndOrderFront(nil)
    }
    
    private func openHelpWindow() {
        // Open built-in help or external documentation
        let helpText = """
        Welcome to NotepadClone2!
        
        Key Features:
        • Rich text editing with syntax highlighting
        • Multi-tab interface
        • Keyboard shortcuts for efficient editing
        • Auto-save functionality
        • Find and replace with regex support
        • Multiple themes including Notepad++ style
        
        Quick Tips:
        • Cmd+T to create a new tab
        • Cmd+W to close current tab
        • Cmd+F to find text
        • Cmd+/ for quick find
        • Cmd+1-9 to switch between tabs
        • Change themes in the View menu
        """
        
        let alert = NSAlert()
        alert.messageText = "NotepadClone2 Help"
        alert.informativeText = helpText
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        // Create a scroll view for the help text if it gets too long
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        
        let textView = NSTextView()
        textView.string = helpText
        textView.isEditable = false
        textView.font = NSFont.systemFont(ofSize: 13)
        textView.textContainerInset = NSSize(width: 10, height: 10)
        
        scrollView.documentView = textView
        scrollView.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
        
        alert.accessoryView = scrollView
        alert.runModal()
    }
}
