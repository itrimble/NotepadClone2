import SwiftUI

// Note: FileExplorerView should be imported if in separate module

// Helper class to force view refreshes with debouncing
class RefreshTrigger: ObservableObject {
    @Published var id = UUID()
    private var refreshTimer: Timer?
    
    func refresh() {
        // Cancel any pending refresh
        refreshTimer?.invalidate()
        
        // Schedule refresh with a small delay to batch multiple requests
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { [weak self] _ in
            self?.id = UUID()
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    // Add explicit refresh trigger for forcing UI updates
    @StateObject private var refreshTrigger = RefreshTrigger()
    
    // Drag and drop state
    @State private var isDragOver = false
    
    // Force initial render state
    @State private var hasAppeared = false
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // File Explorer Sidebar
                if appState.showFileExplorer {
                    FileExplorerView()
                        .environmentObject(appState)
                        .frame(width: 250)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    
                    Divider()
                }
                
                // Main Content Area
                mainContentView() // Extracted
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Terminal Panel
                // TODO: Uncomment when Terminal files are added to Xcode project
                if appState.terminalManager.showTerminal {
                    if appState.terminalManager.terminalPosition == .bottom {
                        Divider()
                        TerminalPanelView(terminalManager: appState.terminalManager)
                            .frame(height: appState.terminalManager.terminalHeight)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            } // End HStack
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Terminal Panel (Right position)
            // TODO: Uncomment when Terminal files are added to Xcode project
            if appState.terminalManager.showTerminal && appState.terminalManager.terminalPosition == .right {
                Divider()
                TerminalPanelView(terminalManager: appState.terminalManager)
                    .frame(width: appState.terminalManager.terminalWidth) // Using terminalWidth from manager
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            
            // Find Panel overlay
            if appState.findManager.showFindPanel || appState.findManager.showReplacePanel {
                VStack {
                    HStack {
                        Spacer()
                        FindPanel(findManager: appState.findManager)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .shadow(radius: 4)
                            .padding()
                    }
                    Spacer()
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(appState.colorScheme)
        .navigationTitle(appState.windowTitle)
        .animation(.easeInOut(duration: 0.2), value: appState.showStatusBar)
        .animation(.easeInOut(duration: 0.2), value: appState.showFileExplorer)
        .animation(.easeInOut(duration: 0.2), value: appState.findManager.showFindPanel)
        .animation(.easeInOut(duration: 0.2), value: appState.findManager.showReplacePanel)
        .animation(.easeInOut(duration: 0.2), value: appState.splitViewEnabled)
        // TODO: Uncomment when Terminal files are added to Xcode project
        .animation(.easeInOut(duration: 0.2), value: appState.terminalManager.showTerminal)
        // Drag and drop support
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
        }
        // Visual feedback for drag operations
        .overlay(
            isDragOver ? 
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue, lineWidth: 2)
                .background(Color.blue.opacity(0.1))
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                        Text("Drop files to open")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: isDragOver)
            : nil
        )
        // Subscribe to document text change notifications
        .onAppear {
            setupNotificationObservers()
            setupSelectionObserver()
            
            print("ContentView onAppear. Initial states: showFileExplorer=\(appState.showFileExplorer), splitViewEnabled=\(appState.splitViewEnabled), tabs.count=\(appState.tabs.count), currentTab=\(String(describing: appState.currentTab))")
            
            // Force an immediate refresh on appear
            refreshTrigger.refresh()
            
            // WORKAROUND: Force view to re-render after initial layout
            if !hasAppeared {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    hasAppeared = true
                }
            }
        }
        // Make view dependent on refresh trigger and relevant state changes
        .id("contentView_\(refreshTrigger.id)_\(appState.appTheme.rawValue)_\(appState.showFileExplorer)_\(appState.splitViewEnabled)_\(hasAppeared)")
        // Cleanup on disappear
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
    }

    // MARK: - Extracted ViewBuilder Methods

    @ViewBuilder
    private func mainContentView() -> some View {
        VStack(spacing: 0) {
            // Tab Bar
            if !appState.tabs.isEmpty {
                TabBarView()
                    .environmentObject(appState)
            }

            // Editor Area
            editorAreaView()

            // Status Bar
            if appState.showStatusBar {
                statusBarView() // Further extraction for clarity
            }
        }
    }

    @ViewBuilder
    private func editorAreaView() -> some View {
        if appState.splitViewEnabled {
            splitEditorView()
        } else {
            singleEditorView()
        }
    }

    @ViewBuilder
    private func splitEditorView() -> some View {
        GeometryReader { geometry in
            if appState.splitViewOrientation == .horizontal {
                HSplitView {
                    editorPane(for: appState.currentTab, refreshTrigger: refreshTrigger)
                        .frame(minWidth: 200)
                    Divider()
                    editorPane(for: appState.splitViewTabIndex ?? appState.currentTab, refreshTrigger: refreshTrigger)
                        .frame(minWidth: 200)
                }
            } else {
                VSplitView {
                    editorPane(for: appState.currentTab, refreshTrigger: refreshTrigger)
                        .frame(minHeight: 100)
                    Divider()
                    editorPane(for: appState.splitViewTabIndex ?? appState.currentTab, refreshTrigger: refreshTrigger)
                        .frame(minHeight: 100)
                }
            }
        }
    }

    @ViewBuilder
    private func singleEditorView() -> some View {
        if let currentIndex = appState.currentTab,
           currentIndex >= 0 && currentIndex < appState.tabs.count {
            
            let currentDocument = appState.tabs[currentIndex]
            
            if appState.showMarkdownPreview && appState.currentDocumentIsMarkdown {
                markdownPreviewOrSplitView(for: currentDocument)
            } else {
                CustomTextView(
                    text: $appState.tabs[currentIndex].text,
                    attributedText: $appState.tabs[currentIndex].attributedText,
                    appTheme: appState.appTheme,
                    showLineNumbers: appState.showLineNumbers,
                    language: appState.tabs[currentIndex].language,
                    document: appState.tabs[currentIndex]
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id("tab_\(currentIndex)_\(currentDocument.id)")
                .focusable(true)
            }
        } else {
            // Fallback for invalid tab state
            Text("No document selected")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func markdownPreviewOrSplitView(for document: Document) -> some View {
        if appState.markdownPreviewMode == .split {
            MarkdownSplitView(
                appState: appState,
                document: document
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            MarkdownPreviewView(
                markdownText: document.text,
                scrollPosition: .constant(0), // Assuming placeholder or state managed elsewhere
                theme: appState.appTheme.name
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    @ViewBuilder
    private func statusBarView() -> some View {
        if let currentIndex = appState.currentTab,
           currentIndex >= 0 && currentIndex < appState.tabs.count {
            let currentDocument = appState.tabs[currentIndex]
            StatusBar(
                characterCount: currentDocument.text.count,
                wordCount: currentDocument.wordCount,
                lineNumber: currentDocument.lineNumber,
                columnNumber: currentDocument.columnNumber,
                selectedRange: currentDocument.selectedRange,
                encoding: currentDocument.encoding,
                onLineColumnClick: { appState.showGoToLineDialog() },
                onEncodingClick: { appState.showEncodingMenu() }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .id("status_\(refreshTrigger.id)")
        }
    }
    
    // MARK: - Drag and Drop Handling
    
    /// Handles file drop operations
    /// - Parameter providers: The drop providers containing file URLs
    /// - Returns: True if files were successfully handled
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                group.enter()
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (urlData, error) in
                    defer { group.leave() }
                    
                    if let error = error {
                        print("Error loading dropped file: \(error)")
                        return
                    }
                    
                    if let urlData = urlData as? Data,
                       let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                        // Validate file type and accessibility
                        if isValidFileForOpening(url) {
                            urls.append(url)
                        }
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if !urls.isEmpty {
                self.appState.openDocuments(from: urls)
            }
        }
        
        return !providers.isEmpty
    }
    
    /// Validates if a file can be opened in the editor
    /// - Parameter url: The file URL to validate
    /// - Returns: True if the file can be opened
    private func isValidFileForOpening(_ url: URL) -> Bool {
        // Check if file exists and is readable
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            return false
        }
        
        // Check if it's a supported file type
        let supportedExtensions = ["txt", "rtf", "md", "swift", "js", "py", "html", "css", "json", "xml", "log"]
        let fileExtension = url.pathExtension.lowercased()
        
        // Allow files with no extension (like config files) or supported extensions
        return fileExtension.isEmpty || supportedExtensions.contains(fileExtension)
    }
    
    // Separate method for observer setup to improve code organization
    private func setupNotificationObservers() {
        // Only observe critical notifications that require view updates
        
        // Observe tab changes in app state
        NotificationCenter.default.addObserver(
            forName: .appStateTabDidChange,
            object: nil,
            queue: .main
        ) { [weak refreshTrigger] _ in
            // Force refresh when tabs change
            refreshTrigger?.refresh()
        }
        
        // Observe theme changes
        NotificationCenter.default.addObserver(
            forName: .themeDidChange,
            object: nil,
            queue: .main
        ) { [weak refreshTrigger] _ in
            // Force refresh when theme changes
            refreshTrigger?.refresh()
        }
    }
    
    private func setupSelectionObserver() {
        // Observe text view selection changes
        NotificationCenter.default.addObserver(
            forName: .textViewSelectionDidChange,
            object: nil,
            queue: .main
        ) { [weak appState] notification in
            guard let selectedRange = notification.userInfo?["selectedRange"] as? NSRange,
                  let currentIndex = appState?.currentTab,
                  let tabs = appState?.tabs,
                  currentIndex >= 0 && currentIndex < tabs.count else { return }
            
            // Update the current document's cursor position without triggering refresh
            tabs[currentIndex].updateCursorPosition(from: selectedRange)
        }
    }
    
    // Helper function to create editor pane for split view
    @ViewBuilder
    private func editorPane(for tabIndex: Int?, refreshTrigger: RefreshTrigger) -> some View {
        // This check is important to ensure tabIndex is valid
        guard let index = tabIndex, index >= 0 && index < appState.tabs.count else {
            return AnyView( // Return an empty or placeholder view if index is invalid
                VStack {
                    Spacer()
                    Text("No document for this pane")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.textBackgroundColor))
            )
        }
        
        // Use a specific ID for the document to ensure view identity
        let document = appState.tabs[index]
        
        return AnyView(
            VStack(spacing: 0) {
                // Optional header showing which file is open
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text(document.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(appState.appTheme.tabBarBackgroundColor()).opacity(0.5))
                
                CustomTextView(
                    text: $appState.tabs[index].text, // Binding directly to the tab's text
                    attributedText: $appState.tabs[index].attributedText, // Binding for attributed text
                    appTheme: appState.appTheme,
                    showLineNumbers: appState.showLineNumbers,
                    language: document.language, // Use document's language
                    document: document // Pass the document itself
                )
                .id("split_pane_\(index)_\(document.id)_\(refreshTrigger.id)") // Ensure unique ID
            }
        )
    }
}

// Preview for Xcode development
#Preview {
    ContentView()
        .environmentObject(AppState()) // Ensure AppState is provided for preview
}
