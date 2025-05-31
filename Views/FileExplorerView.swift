import SwiftUI
import Foundation
import AppKit
import UniformTypeIdentifiers // Added import

// MARK: - File System Models

/// Represents a file or directory in the file explorer tree
class FileSystemItem: ObservableObject, Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    @Published var isExpanded: Bool = false
    @Published var children: [FileSystemItem] = []
    @Published var isLoaded: Bool = false
    weak var manager: FileExplorerManager? // Added manager reference
    
    var isHidden: Bool {
        name.hasPrefix(".")
    }
    
    var fileExtension: String {
        url.pathExtension.lowercased()
    }
    
    var systemImage: String {
        if isDirectory {
            return isExpanded ? "folder.fill" : "folder"
        } else {
            switch fileExtension {
            case "swift": return "swift"
            case "js", "ts": return "doc.text"
            case "py": return "doc.text"
            case "html", "htm": return "globe"
            case "css": return "paintbrush"
            case "json": return "doc.text"
            case "md": return "doc.richtext"
            case "txt": return "doc.plaintext"
            case "rtf": return "doc.richtext"
            case "xml": return "doc.text"
            case "log": return "doc.text"
            default: return "doc"
            }
        }
    }
    
    init(url: URL, manager: FileExplorerManager) { // Modified signature
        self.url = url
        self.name = url.lastPathComponent
        self.manager = manager // Store the manager

        var isDir: ObjCBool = false
        self.isDirectory = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue

        if self.isDirectory { // Only directories can be expanded
            if let mgr = self.manager, mgr.expandedItems.contains(self.url.path) {
                self.isExpanded = true
                // Automatically load children if persisted as expanded.
                self.loadChildren()
            } else {
                self.isExpanded = false
            }
        } else {
            self.isExpanded = false
        }
    }
    
    func loadChildren() {
        guard isDirectory && !isLoaded else { return }
        guard let manager = self.manager else {
            print("Error: FileSystemItem's manager is nil. Cannot load children.")
            return
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
                options: []
            )
            
            children = contents
                .filter { !$0.lastPathComponent.hasPrefix(".") } // Filter hidden files
                .map { FileSystemItem(url: $0, manager: manager) } // Pass manager
                .sorted { item1, item2 in
                    // Directories first, then files, both alphabetically
                    if item1.isDirectory != item2.isDirectory {
                        return item1.isDirectory && !item2.isDirectory
                    }
                    return item1.name.localizedCaseInsensitiveCompare(item2.name) == .orderedAscending
                }
            
            isLoaded = true
        } catch {
            print("Error loading directory contents: \(error)")
            children = []
            isLoaded = true
        }
    }
    
    static func == (lhs: FileSystemItem, rhs: FileSystemItem) -> Bool {
        lhs.url == rhs.url
    }
}

// MARK: - File Explorer Manager

class FileExplorerManager: ObservableObject {
    @Published var rootItem: FileSystemItem?
    @Published var selectedItem: FileSystemItem?
    @Published var isVisible: Bool = true
    @Published var expandedItems: Set<String> = [] // Already existed, will be populated from UserDefaults
    private var fileSystemWatcher: FileSystemWatcher? // Property for the watcher
    
    private static let expandedItemsKey = "fileExplorerExpandedItemsKey" // UserDefaults key

    init() {
        if let savedPaths = UserDefaults.standard.array(forKey: Self.expandedItemsKey) as? [String] {
            self.expandedItems = Set(savedPaths)
            print("FileExplorerManager: Loaded \(self.expandedItems.count) expanded items from UserDefaults.")
        } else {
            self.expandedItems = [] // Ensure it's initialized
            print("FileExplorerManager: No saved expanded items found or error in loading.")
        }
        // Other properties are initialized with default values or implicitly.
    }

    private func saveExpandedItems() {
        UserDefaults.standard.set(Array(self.expandedItems), forKey: Self.expandedItemsKey)
        print("FileExplorerManager: Saved \(self.expandedItems.count) expanded items to UserDefaults.")
    }

    /// Sets the root directory for the file explorer
    func setRootDirectory(_ url: URL) {
        // Stop previous watcher
        stopWatching()

        rootItem = FileSystemItem(url: url, manager: self) // Pass manager
        // The FileSystemItem's init now handles setting isExpanded based on persisted state
        // and calls loadChildren if it was persisted as expanded.
        if let root = rootItem, !root.isExpanded {
            // Optional: Load first level children if root is not expanded by default
            // root.loadChildren()
        }
        print("FileExplorerManager: Set root directory to \(url). Root item expanded: \(rootItem?.isExpanded ?? false)")

        // Start new watcher for the new root directory
        self.fileSystemWatcher = FileSystemWatcher(url: url) { [weak self] in
            print("[FileExplorerManager] Watcher event triggered for URL: \(url.path)")
            self?.handleFileSystemChange()
        }

        if self.fileSystemWatcher?.start() == true {
            print("[FileExplorerManager] Started watching new root directory: \(url.path)")
        } else {
            print("[FileExplorerManager] Failed to start watching new root directory: \(url.path)")
            self.fileSystemWatcher = nil // Clear if failed to start
        }
    }
    
    private func stopWatching() {
        fileSystemWatcher?.stop()
        fileSystemWatcher = nil
        print("[FileExplorerManager] Stopped watching for file system changes.")
    }

    private func handleFileSystemChange() {
        print("[FileExplorerManager] File system change detected via watcher. Refreshing entire explorer tree.")
        // Ensure refresh is dispatched to the main queue as it likely involves UI updates.
        // FileSystemWatcher already calls its handler on main, so direct call is fine.
        self.refresh()
    }

    /// Toggles the expansion state of a directory
    func toggleExpansion(for item: FileSystemItem) {
        guard item.isDirectory else { return }
        
        if !item.isLoaded {
            item.loadChildren()
        }
        
        item.isExpanded.toggle()
        
        if item.isExpanded {
            expandedItems.insert(item.url.path)
        } else {
            expandedItems.remove(item.url.path)
        }
        saveExpandedItems() // Save after modification
    }
    
    /// Selects a file or directory
    func selectItem(_ item: FileSystemItem) {
        selectedItem = item
    }
    
    /// Refreshes the current directory
    func refresh() {
        guard let root = rootItem else { return }
        refreshItem(root)
    }
    
    private func refreshItem(_ item: FileSystemItem) {
        if item.isDirectory && item.isLoaded {
            item.isLoaded = false
            item.loadChildren()
            
            // Recursively refresh expanded children
            for child in item.children where child.isExpanded {
                refreshItem(child)
            }
        }
    }

    // Helper to find a FileSystemItem for a given URL within a subtree
    // Used to refresh the correct parent after a move operation.
    private func findItem(forURL url: URL, in item: FileSystemItem) -> FileSystemItem? {
        if item.url == url {
            return item
        }
        if item.isDirectory {
            for child in item.children {
                // Check if the child is the item itself or if the item is within the child's subtree
                if child.url == url {
                    return child
                }
                if url.path.hasPrefix(child.url.path + "/") { // Item is deeper in this child's hierarchy
                    if let found = findItem(forURL: url, in: child) {
                        return found
                    }
                }
            }
        }
        return nil
    }

    public func handleDrop(sourceURL: URL, destinationDirectoryItem: FileSystemItem) {
        print("[FileExplorerManager] Handling drop of \(sourceURL.lastPathComponent) onto \(destinationDirectoryItem.name)")

        // 1. Validations
        guard destinationDirectoryItem.isDirectory else {
            print("[FileExplorerManager] Error: Drop destination '\(destinationDirectoryItem.name)' is not a directory.")
            return
        }

        guard sourceURL != destinationDirectoryItem.url else {
            print("[FileExplorerManager] Error: Cannot move an item into itself.")
            return
        }

        // Prevent dragging a parent into its child
        if destinationDirectoryItem.url.path.hasPrefix(sourceURL.path + "/") {
            print("[FileExplorerManager] Error: Cannot move a parent folder into its child.")
            // Consider showing an alert to the user
            return
        }

        let newFileName = sourceURL.lastPathComponent
        let finalDestinationURL = destinationDirectoryItem.url.appendingPathComponent(newFileName)

        // Check if source is already in the destination (no actual move needed if paths are equivalent)
        // This check needs to be careful if sourceURL is a directory itself.
        if sourceURL.deletingLastPathComponent().standardizedFileURL == destinationDirectoryItem.url.standardizedFileURL {
             if sourceURL.standardizedFileURL == finalDestinationURL.standardizedFileURL {
                print("[FileExplorerManager] Item '\(newFileName)' is already in directory '\(destinationDirectoryItem.name)' with the same name. No move needed.")
                return
            }
        }

        // Check if an item with the same name already exists at the destination
        if FileManager.default.fileExists(atPath: finalDestinationURL.path) {
            print("[FileExplorerManager] Error: An item named '\(newFileName)' already exists in '\(destinationDirectoryItem.name)'.")
            // TODO: Implement overwrite confirmation or renaming strategy
            // For now, we just abort the move.
            // Consider showing an alert to the user.
            return
        }

        // 2. Perform Move
        do {
            print("[FileExplorerManager] Attempting to move \(sourceURL.path) to \(finalDestinationURL.path)")
            try FileManager.default.moveItem(at: sourceURL, to: finalDestinationURL)
            print("[FileExplorerManager] Move successful.")

            // 3. Refresh UI
            // Find the original parent of the source item to refresh it
            let oldParentURL = sourceURL.deletingLastPathComponent()
            if let root = self.rootItem, let oldParentNode = findItem(forURL: oldParentURL, in: root) {
                print("[FileExplorerManager] Refreshing old parent: \(oldParentNode.name)")
                oldParentNode.isLoaded = false
                oldParentNode.loadChildren()
            } else {
                print("[FileExplorerManager] Could not find old parent node for \(sourceURL.path). Refreshing root as fallback.")
                self.refresh()
            }

            print("[FileExplorerManager] Refreshing destination directory: \(destinationDirectoryItem.name)")
            destinationDirectoryItem.isLoaded = false
            destinationDirectoryItem.loadChildren()
            // Ensure the destination directory is marked as expanded if it wasn't already,
            // so the newly moved item is visible.
            if !destinationDirectoryItem.isExpanded {
                 destinationDirectoryItem.isExpanded = true
                 // Persist this change if needed by your expandedItems logic
                 self.expandedItems.insert(destinationDirectoryItem.url.path)
                 self.saveExpandedItems()
            }


        } catch {
            print("[FileExplorerManager] Error moving item '\(sourceURL.lastPathComponent)' to '\(destinationDirectoryItem.name)': \(error.localizedDescription)")
            // TODO: Show error alert to the user
        }
    }
}

// MARK: - File Explorer View

struct FileExplorerView: View {
    @StateObject private var fileManager = FileExplorerManager()
    @EnvironmentObject var appState: AppState
    @State private var contextMenuItem: FileSystemItem?
    @State private var showingNewFileAlert = false
    @State private var showingNewFolderAlert = false
    @State private var showingRenameAlert = false
    @State private var showingDeleteAlert = false
    @State private var newItemName = ""
    @State private var renameItemName = ""
    @State private var itemToDelete: FileSystemItem?
    @State private var itemToRename: FileSystemItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Explorer")
                    .font(.headline)
                    .foregroundColor(Color(appState.appTheme.editorTextColor()))
                
                Spacer()
                
                Button(action: {
                    chooseRootDirectory()
                }) {
                    Image(systemName: "folder.badge.plus")
                        .foregroundColor(Color(appState.appTheme.editorTextColor()))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Choose Root Directory")
                
                Button(action: {
                    fileManager.refresh()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(Color(appState.appTheme.editorTextColor()))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Refresh")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(appState.appTheme.tabBarBackgroundColor()))
            
            Divider()
            
            // File Tree
            ScrollView {
                if let rootItem = fileManager.rootItem {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        FileTreeItemView(
                            item: rootItem,
                            level: 0,
                            fileManager: fileManager,
                            appState: appState,
                            onItemSelected: { item in
                                handleItemSelection(item)
                            },
                            onContextMenu: { item in
                                contextMenuItem = item
                            }
                        )
                    }
                    .padding(.top, 4)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No folder selected")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Choose a root directory to explore files")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Choose Folder") {
                            chooseRootDirectory()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
            .background(Color(appState.appTheme.editorBackgroundColor()))
        }
        .frame(maxHeight: .infinity)
        .background(Color(appState.appTheme.editorBackgroundColor()))
        .contextMenu(menuItems: {
            if let item = contextMenuItem {
                Button("Open") {
                    handleItemSelection(item)
                }
                
                if item.isDirectory {
                    Button(item.isExpanded ? "Collapse" : "Expand") {
                        fileManager.toggleExpansion(for: item)
                    }
                }
                
                Divider()
                
                // File/Folder Creation
                if item.isDirectory {
                    Button("New File...") {
                        contextMenuItem = item
                        newItemName = ""
                        showingNewFileAlert = true
                    }
                    
                    Button("New Folder...") {
                        contextMenuItem = item
                        newItemName = ""
                        showingNewFolderAlert = true
                    }
                    
                    Divider()
                }
                
                // Edit Operations
                Button("Rename...") {
                    itemToRename = item
                    renameItemName = item.name
                    showingRenameAlert = true
                }
                
                Button("Delete") {
                    itemToDelete = item
                    showingDeleteAlert = true
                }
                .foregroundColor(.red)
                
                Divider()
                
                Button("Reveal in Finder") {
                    NSWorkspace.shared.selectFile(item.url.path, inFileViewerRootedAtPath: "")
                }
                
                Button("Copy Path") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(item.url.path, forType: .string)
                }
            }
        })
        .onAppear {
            // Set initial root directory to Documents if available
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            if let documentsURL = documentsURL {
                fileManager.setRootDirectory(documentsURL)
            }
        }
        .alert("New File", isPresented: $showingNewFileAlert) {
            TextField("File name", text: $newItemName)
            Button("Create") {
                createNewFile()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a name for the new file")
        }
        .alert("New Folder", isPresented: $showingNewFolderAlert) {
            TextField("Folder name", text: $newItemName)
            Button("Create") {
                createNewFolder()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a name for the new folder")
        }
        .alert("Rename", isPresented: $showingRenameAlert) {
            TextField("New name", text: $renameItemName)
            Button("Rename") {
                renameItem()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a new name for the item")
        }
        .alert("Delete Item", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteItem()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let item = itemToDelete {
                Text("Are you sure you want to delete '\(item.name)'? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - File Operations
    
    private func createNewFile() {
        guard let parentItem = contextMenuItem,
              parentItem.isDirectory,
              !newItemName.isEmpty else { return }
        
        let newFileURL = parentItem.url.appendingPathComponent(newItemName)
        
        do {
            // Create empty file
            try "".write(to: newFileURL, atomically: true, encoding: .utf8)
            
            // Refresh parent directory
            refreshParent(parentItem)
            
            // Open the new file in editor
            appState.openDocument(from: newFileURL)
            
        } catch {
            print("Error creating file: \(error)")
            // TODO: Show error alert
        }
    }
    
    private func createNewFolder() {
        guard let parentItem = contextMenuItem,
              parentItem.isDirectory,
              !newItemName.isEmpty else { return }
        
        let newFolderURL = parentItem.url.appendingPathComponent(newItemName)
        
        do {
            try FileManager.default.createDirectory(at: newFolderURL, withIntermediateDirectories: false, attributes: nil)
            
            // Refresh parent directory
            refreshParent(parentItem)
            
        } catch {
            print("Error creating folder: \(error)")
            // TODO: Show error alert
        }
    }
    
    private func renameItem() {
        guard let item = itemToRename,
              !renameItemName.isEmpty,
              renameItemName != item.name else { return }
        
        let parentURL = item.url.deletingLastPathComponent()
        let newURL = parentURL.appendingPathComponent(renameItemName)
        
        do {
            try FileManager.default.moveItem(at: item.url, to: newURL)
            
            // If this was the currently open document, update its URL
            if let currentIndex = appState.currentTab,
               currentIndex < appState.tabs.count,
               appState.tabs[currentIndex].fileURL == item.url {
                appState.tabs[currentIndex].fileURL = newURL
            }
            
            // Refresh parent directory
            if let parent = findParentItem(for: item) {
                refreshParent(parent)
            } else {
                fileManager.refresh()
            }
            
        } catch {
            print("Error renaming item: \(error)")
            // TODO: Show error alert
        }
    }
    
    private func deleteItem() {
        guard let item = itemToDelete else { return }
        
        do {
            try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
            
            // If this was the currently open document, close it
            if let currentIndex = appState.currentTab,
               currentIndex < appState.tabs.count,
               appState.tabs[currentIndex].fileURL == item.url {
                appState.closeDocument(at: currentIndex)
            }
            
            // Refresh parent directory
            if let parent = findParentItem(for: item) {
                refreshParent(parent)
            } else {
                fileManager.refresh()
            }
            
        } catch {
            print("Error deleting item: \(error)")
            // TODO: Show error alert
        }
    }
    
    private func refreshParent(_ parent: FileSystemItem) {
        parent.isLoaded = false
        parent.loadChildren()
    }
    
    private func findParentItem(for item: FileSystemItem) -> FileSystemItem? {
        guard let root = fileManager.rootItem else { return nil }
        return findParentItem(for: item, in: root)
    }
    
    private func findParentItem(for item: FileSystemItem, in parent: FileSystemItem) -> FileSystemItem? {
        for child in parent.children {
            if child.id == item.id {
                return parent
            }
            if child.isDirectory, let found = findParentItem(for: item, in: child) {
                return found
            }
        }
        return nil
    }
    
    private func handleItemSelection(_ item: FileSystemItem) {
        fileManager.selectItem(item)
        
        if item.isDirectory {
            fileManager.toggleExpansion(for: item)
        } else {
            // Open file in editor
            appState.openDocument(from: item.url)
        }
    }
    
    private func chooseRootDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "Choose Root Directory"
        
        if panel.runModal() == .OK, let url = panel.url {
            fileManager.setRootDirectory(url)
        }
    }
}

// MARK: - File Tree Item View

struct FileTreeItemView: View {
    @ObservedObject var item: FileSystemItem
    let level: Int
    let fileManager: FileExplorerManager
    let appState: AppState
    let onItemSelected: (FileSystemItem) -> Void
    let onContextMenu: (FileSystemItem) -> Void
    @State private var isDropTargeted: Bool = false // For drop target visual feedback
    
    private var indentationWidth: CGFloat {
        CGFloat(level * 16)
    }
    
    private var isSelected: Bool {
        fileManager.selectedItem?.id == item.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Item row
            HStack(spacing: 4) {
                // Indentation
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: indentationWidth, height: 1)
                
                // Expansion triangle for directories
                if item.isDirectory {
                    Button(action: {
                        fileManager.toggleExpansion(for: item)
                    }) {
                        Image(systemName: item.isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(Color(appState.appTheme.editorTextColor()))
                            .frame(width: 12, height: 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 12, height: 12)
                }
                
                // File/folder icon
                Image(systemName: item.systemImage)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
                    .frame(width: 16)
                
                // File/folder name
                Text(item.name)
                    .font(.system(size: 13))
                    .foregroundColor(Color(appState.appTheme.editorTextColor()))
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
            }
            .contentShape(Rectangle())
            .background(
                Group { // Use Group to conditionally apply background layers
                    if isDropTargeted && item.isDirectory {
                        Color.blue.opacity(0.25) // Visual feedback for drop target
                    } else if isSelected {
                        Color(appState.appTheme.tabBarSelectedColor()).opacity(0.3)
                    } else {
                        Color.clear
                    }
                }
            )
            .onTapGesture {
                onItemSelected(item)
            }
            .onTapGesture(count: 2) {
                if item.isDirectory {
                    fileManager.toggleExpansion(for: item)
                } else {
                    onItemSelected(item)
                }
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                onContextMenu(item)
            }
            .frame(height: 22)
            
            // Children (if expanded)
            if item.isDirectory && item.isExpanded {
                ForEach(item.children) { child in
                    FileTreeItemView(
                        item: child,
                        level: level + 1,
                        fileManager: fileManager,
                        appState: appState,
                        onItemSelected: onItemSelected,
                        onContextMenu: onContextMenu
                    )
                }
            }
        }
        .onDrag {
            print("[FileTreeItemView] Dragging item: \(item.name) at URL: \(item.url.path)")
            let itemProvider = NSItemProvider(object: item.url as NSURL)
            return itemProvider
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted) { providers in
            guard self.item.isDirectory else {
                print("[FileTreeItemView] Drop target '\(self.item.name)' is not a directory. Ignoring drop.")
                return false // Cannot handle drop if not a directory
            }

            guard let provider = providers.first(where: { $0.canLoadObject(ofClass: URL.self) }) else {
                print("[FileTreeItemView] No provider found that can load URL.")
                return false
            }

            print("[FileTreeItemView] Item provider received for drop on '\(self.item.name)'. Attempting to load URL.")
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                DispatchQueue.main.async { // Ensure UI updates and file operations are on main thread
                    guard let sourceURL = url else {
                        if let error = error {
                            print("[FileTreeItemView] Error loading dropped item: \(error.localizedDescription)")
                        } else {
                            print("[FileTreeItemView] Failed to get URL from dropped item, but no error reported.")
                        }
                        return
                    }

                    print("[FileTreeItemView] Item with URL \(sourceURL.path) dropped onto directory \(self.item.name) (\(self.item.url.path))")
                    // Pass to FileExplorerManager to handle the actual move and UI refresh
                    self.fileManager.handleDrop(sourceURL: sourceURL, destinationDirectoryItem: self.item)
                }
            }
            return true // Indicate that we can attempt to handle this drop type
        }
    }
    
    private var iconColor: Color {
        if item.isDirectory {
            return Color.blue
        } else {
            switch item.fileExtension {
            case "swift": return Color.orange
            case "js", "ts": return Color.yellow
            case "py": return Color.green
            case "html", "htm": return Color.red
            case "css": return Color.blue
            case "json": return Color.purple
            case "md": return Color.gray
            default: return Color(appState.appTheme.editorTextColor())
            }
        }
    }
}

// Preview for development
#Preview {
    FileExplorerView()
        .environmentObject(AppState())
        .frame(width: 300, height: 500)
}