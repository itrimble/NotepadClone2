import SwiftUI

@main
struct NotepadCloneApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .commands {
            // File Menu
            CommandGroup(replacing: .newItem) {
                Button("New Tab") { appState.newDocument() }
                    .keyboardShortcut("t")
                Button("Open...") { appState.openDocument() }
                    .keyboardShortcut("o")
                Button("Save") { appState.saveDocument() }
                    .keyboardShortcut("s")
                Button("Save As...") { appState.saveDocumentAs() }
                    .keyboardShortcut("S")
                Divider()
                Button("Close Tab") {
                    if let currentTab = appState.currentTab {
                        appState.closeDocument(at: currentTab)
                    }
                }
                .keyboardShortcut("w")
                Divider()
                Button("Print...") { appState.printDocument() }
                    .keyboardShortcut("p")
            }
            
            // Edit Menu
            CommandGroup(replacing: .textEditing) {
                Button("Undo") { appState.undo() }
                    .keyboardShortcut("z")
                Button("Redo") { appState.redo() }
                    .keyboardShortcut("Z")
                Divider()
                Button("Cut") { appState.cut() }
                    .keyboardShortcut("x")
                Button("Copy") { appState.copy() }
                    .keyboardShortcut("c")
                Button("Paste") { appState.paste() }
                    .keyboardShortcut("v")
                Button("Select All") { appState.selectAll() }
                    .keyboardShortcut("a")
                Divider()
                Button("Find") { appState.showFindPanel() }
                    .keyboardShortcut("f")
                Button("Replace") { appState.showReplacePanel() }
                    .keyboardShortcut("f", modifiers: [.command, .option])
                Button("Find Next") { appState.findNext() }
                    .keyboardShortcut("g")
                Button("Find Previous") { appState.findPrevious() }
                    .keyboardShortcut("G")
            }
            
            // Format Menu
            CommandMenu("Format") {
                Button("Bold") { appState.toggleBold() }
                    .keyboardShortcut("b")
                Button("Italic") { appState.toggleItalic() }
                    .keyboardShortcut("i")
                Button("Underline") { appState.toggleUnderline() }
                    .keyboardShortcut("u")
                Divider()
                Button("Align Left") { appState.alignLeft() }
                    .keyboardShortcut("{")
                Button("Center") { appState.alignCenter() }
                    .keyboardShortcut("|")
                Button("Align Right") { appState.alignRight() }
                    .keyboardShortcut("}")
                Divider()
                Button("Font...") { appState.showFontPanel() }
                    .keyboardShortcut("t")
            }
            
            // View Menu
            CommandMenu("View") {
                Picker("Appearance", selection: $appState.colorScheme) {
                    Text("System").tag(nil as ColorScheme?)
                    Text("Light").tag(ColorScheme.light)
                    Text("Dark").tag(ColorScheme.dark)
                }
                Toggle("Status Bar", isOn: $appState.showStatusBar)
            }
            
            // Tab Selection Keyboard Shortcuts
            CommandGroup(after: .windowArrangement) {
                ForEach(1...9, id: \.self) { number in
                    Button("Tab \(number)") {
                        // Fixed: Remove $ prefix for method calls
                        appState.selectTabByNumber(number)
                    }
                    .keyboardShortcut(KeyEquivalent(Character(String(number))), modifiers: .command)
                }
                
                // Additional tab navigation shortcuts
                Button("Next Tab") {
                    if let current = appState.currentTab, current < appState.tabs.count - 1 {
                        appState.selectTab(at: current + 1)
                    }
                }
                .keyboardShortcut("]", modifiers: .command)
                
                Button("Previous Tab") {
                    if let current = appState.currentTab, current > 0 {
                        appState.selectTab(at: current - 1)
                    }
                }
                .keyboardShortcut("[", modifiers: .command)
            }
        }
        .windowToolbarStyle(.unified)
    }
}
