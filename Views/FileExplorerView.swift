import SwiftUI
import Foundation
import AppKit

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
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        
        var isDir: ObjCBool = false
        self.isDirectory = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }
    
    func loadChildren() {
        guard isDirectory && !isLoaded else { return }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
                options: []
            )
            
            children = contents
                .filter { !$0.lastPathComponent.hasPrefix(".") } // Filter hidden files
                .map { FileSystemItem(url: $0) }
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
    @Published var expandedItems: Set<String> = []
    
    /// Sets the root directory for the file explorer
    func setRootDirectory(_ url: URL) {
        rootItem = FileSystemItem(url: url)
        rootItem?.loadChildren()
        rootItem?.isExpanded = true
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
                Rectangle()
                    .fill(isSelected ? Color(appState.appTheme.tabBarSelectedColor()) : Color.clear)
                    .opacity(isSelected ? 0.3 : 0)
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