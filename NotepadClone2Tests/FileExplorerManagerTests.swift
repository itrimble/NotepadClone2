import XCTest
@testable import NotepadClone2 // Ensure main app target is importable
import Foundation // For URL

// Helper to access the private key if needed, or redefine for test
private let testExpandedItemsKey = "fileExplorerExpandedItemsKey"

// Mock FileSystemWatcher for testing
class MockFileSystemWatcher: FileSystemWatcher {
    var startCalled = false
    var stopCalled = false
    var lastWatchedURL: URL?
    var internalEventHandler: (() -> Void)?

    override init(url: URL, eventHandler: @escaping () -> Void) {
        self.lastWatchedURL = url
        self.internalEventHandler = eventHandler
        super.init(url: url, eventHandler: eventHandler)
    }

    @discardableResult
    override func start() -> Bool {
        startCalled = true
        // Simulate successful start for tests
        // super.start() // Don't call super.start() to avoid actual file system watching in mock
        return true
    }

    override func stop() {
        stopCalled = true
        // super.stop() // Don't call super.stop() for the same reason
    }

    // Helper to manually trigger the event handler for testing
    func triggerEvent() {
        internalEventHandler?()
    }
}

class FileExplorerManagerTests: XCTestCase {

    var fileManager: FileExplorerManager!
    let userDefaults = UserDefaults.standard // Use standard UserDefaults for testing this feature

    // Mock directory structure
    let tempRootURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("FileExplorerManagerTestsRoot")
    var itemA_URL: URL! // dir
    var itemB_URL: URL! // file in itemA
    var itemC_URL: URL! // dir
    var itemD_URL: URL! // file in root
    var subFolderAA_URL: URL! // tempRootURL/FolderA/SubFolderAA/
    var fileAA1_URL: URL!   // tempRootURL/FolderA/SubFolderAA/FileAA1.txt
    var folderE_URL: URL!   // tempRootURL/FolderE/ (empty folder)


    override func setUpWithError() throws {
        try super.setUpWithError()

        // Clean up UserDefaults before each test for this key
        userDefaults.removeObject(forKey: testExpandedItemsKey)

        // Create mock file system structure
        try? FileManager.default.removeItem(at: tempRootURL) // Clear previous runs
        try FileManager.default.createDirectory(at: tempRootURL, withIntermediateDirectories: true, attributes: nil)

        itemA_URL = tempRootURL.appendingPathComponent("FolderA")
        try FileManager.default.createDirectory(at: itemA_URL, withIntermediateDirectories: true, attributes: nil)

        itemB_URL = itemA_URL.appendingPathComponent("FileB.txt")
        try "contentB".write(to: itemB_URL, atomically: true, encoding: .utf8)

        itemC_URL = tempRootURL.appendingPathComponent("FolderC")
        try FileManager.default.createDirectory(at: itemC_URL, withIntermediateDirectories: true, attributes: nil)

        itemD_URL = tempRootURL.appendingPathComponent("FileD.txt")
        try "contentD".write(to: itemD_URL, atomically: true, encoding: .utf8)

        // Additional items for move tests
        subFolderAA_URL = itemA_URL.appendingPathComponent("SubFolderAA")
        try FileManager.default.createDirectory(at: subFolderAA_URL, withIntermediateDirectories: true, attributes: nil)

        fileAA1_URL = subFolderAA_URL.appendingPathComponent("FileAA1.txt")
        try "contentAA1".write(to: fileAA1_URL, atomically: true, encoding: .utf8)

        folderE_URL = tempRootURL.appendingPathComponent("FolderE")
        try FileManager.default.createDirectory(at: folderE_URL, withIntermediateDirectories: true, attributes: nil)

        fileManager = FileExplorerManager() // This will load from UserDefaults
    }

    override func tearDownWithError() throws {
        userDefaults.removeObject(forKey: testExpandedItemsKey)
        try? FileManager.default.removeItem(at: tempRootURL)
        fileManager = nil
        try super.tearDownWithError()
    }

    func testInitialLoading_NoSavedState() {
        // Manager is initialized in setUp, UserDefaults is clean for the key
        XCTAssertTrue(fileManager.expandedItems.isEmpty, "expandedItems should be empty if no state was saved.")
    }

    func testSavingAndLoadingExpansionState() {
        // 1. Simulate setting a root and expanding a folder
        fileManager.setRootDirectory(tempRootURL)
        guard let rootItem = fileManager.rootItem else {
            XCTFail("Root item should not be nil after setRootDirectory.")
            return
        }
        // Root item itself might load children depending on its own persisted state (or lack thereof)
        // For this test, ensure children are loaded to find FolderA
        if !rootItem.isLoaded { rootItem.loadChildren() }


        guard let folderA_Item = rootItem.children.first(where: { $0.url == itemA_URL }) else {
            XCTFail("Could not find FolderA in mock structure. Root children: \(rootItem.children.map { $0.name })")
            return
        }

        XCTAssertFalse(folderA_Item.isExpanded, "FolderA should not be expanded initially by default if not in loaded state.")

        fileManager.toggleExpansion(for: folderA_Item) // Expand FolderA
        XCTAssertTrue(folderA_Item.isExpanded, "FolderA should now be expanded.")
        XCTAssertTrue(fileManager.expandedItems.contains(itemA_URL.path), "Manager's expandedItems should contain FolderA's path after toggle.")

        // Check if UserDefaults was updated (indirectly, by seeing if a new manager loads it)
        let savedPaths = userDefaults.array(forKey: testExpandedItemsKey) as? [String]
        XCTAssertNotNil(savedPaths, "UserDefaults should have saved paths.")
        XCTAssertTrue(savedPaths?.contains(itemA_URL.path) ?? false, "Saved paths in UserDefaults should include FolderA.")

        // 2. Create a new FileExplorerManager instance - it should load the saved state
        let newManager = FileExplorerManager()
        XCTAssertTrue(newManager.expandedItems.contains(itemA_URL.path), "New manager should load FolderA's path from UserDefaults.")

        // 3. Set root for the new manager and check if FolderA is marked as expanded
        newManager.setRootDirectory(tempRootURL)
        guard let newRootItem = newManager.rootItem else {
            XCTFail("New root item should not be nil.")
            return
        }
        // Ensure children of newRootItem are loaded if newRootItem itself was expanded, or load them to find newFolderA_Item
        if newRootItem.isExpanded && !newRootItem.isLoaded { newRootItem.loadChildren() }
        else if !newRootItem.isLoaded { newRootItem.loadChildren()}


        guard let newFolderA_Item = newRootItem.children.first(where: { $0.url == itemA_URL }) else {
            XCTFail("Could not find FolderA in new manager's structure. New root children: \(newRootItem.children.map { $0.name })")
            return
        }

        // Because FileSystemItem.init now checks manager.expandedItems and sets isExpanded,
        // and calls loadChildren if true, newFolderA_Item should be expanded.
        XCTAssertTrue(newFolderA_Item.isExpanded, "FolderA in new manager should be expanded due to loaded state.")
        XCTAssertTrue(newFolderA_Item.isLoaded, "FolderA's children should be loaded if it was expanded from persistent state.")
        XCTAssertFalse(newFolderA_Item.children.isEmpty, "FolderA should have children loaded (FileB.txt). Child count: \(newFolderA_Item.children.count)")
    }

    func testToggleExpansion_AddsAndRemovesFromPersistence() {
        fileManager.setRootDirectory(tempRootURL)
        guard let rootItem = fileManager.rootItem else { XCTFail("Root missing"); return }
        if !rootItem.isLoaded { rootItem.loadChildren() }


        guard let folderA_Item = rootItem.children.first(where: { $0.url == itemA_URL }),
              let folderC_Item = rootItem.children.first(where: { $0.url == itemC_URL }) else {
            XCTFail("Mock items not found.")
            return
        }

        // Expand FolderA
        fileManager.toggleExpansion(for: folderA_Item)
        var savedPaths = userDefaults.array(forKey: testExpandedItemsKey) as? [String] ?? []
        XCTAssertTrue(savedPaths.contains(itemA_URL.path))
        XCTAssertFalse(savedPaths.contains(itemC_URL.path))

        // Expand FolderC
        fileManager.toggleExpansion(for: folderC_Item)
        savedPaths = userDefaults.array(forKey: testExpandedItemsKey) as? [String] ?? []
        XCTAssertTrue(savedPaths.contains(itemA_URL.path))
        XCTAssertTrue(savedPaths.contains(itemC_URL.path))

        // Collapse FolderA
        fileManager.toggleExpansion(for: folderA_Item) // This now makes it not expanded
        savedPaths = userDefaults.array(forKey: testExpandedItemsKey) as? [String] ?? []
        XCTAssertFalse(savedPaths.contains(itemA_URL.path), "FolderA path should be removed from persistence after collapse.")
        XCTAssertTrue(savedPaths.contains(itemC_URL.path))
    }

    func testFileSystemItemInitialization_RespectsManagerExpandedSet() {
        // Pre-populate user defaults and load a manager
        let pathsToPreExpand = [itemA_URL.path, itemC_URL.path]
        userDefaults.set(pathsToPreExpand, forKey: testExpandedItemsKey)

        let freshManager = FileExplorerManager()
        XCTAssertEqual(freshManager.expandedItems, Set(pathsToPreExpand))

        // Create a root FileSystemItem with this manager
        // Its children (FolderA, FolderC) should become expanded and load their children.
        // This requires root to load its children first to instantiate them.
        let rootForFreshManager = FileSystemItem(url: tempRootURL, manager: freshManager)
        if !rootForFreshManager.isLoaded { // Ensure root's children are loaded for the test assertions below
            rootForFreshManager.loadChildren()
        }

        let childFolderA = rootForFreshManager.children.first { $0.url == itemA_URL }
        let childFolderC = rootForFreshManager.children.first { $0.url == itemC_URL }

        XCTAssertNotNil(childFolderA, "Child FolderA should exist.")
        XCTAssertTrue(childFolderA?.isExpanded ?? false, "Child FolderA should be expanded based on freshManager's state.")
        XCTAssertTrue(childFolderA?.isLoaded ?? false, "Child FolderA should have loaded its children.")
        XCTAssertFalse(childFolderA?.children.isEmpty ?? true, "Child FolderA should have children items (FileB.txt).")

        XCTAssertNotNil(childFolderC, "Child FolderC should exist.")
        XCTAssertTrue(childFolderC?.isExpanded ?? false, "Child FolderC should be expanded based on freshManager's state.")
        // FolderC is empty in mock setup, so children array will be empty, but isLoaded should be true.
        XCTAssertTrue(childFolderC?.isLoaded ?? false, "Child FolderC should have attempted to load children.")
        XCTAssertTrue(childFolderC?.children.isEmpty ?? false, "Child FolderC has no children in mock setup.")
    }

    // MARK: - FileSystemWatcher Integration Tests

    func testSetRootDirectory_InitializesAndStartsWatcher_Placeholder() {
        // This test acknowledges the limitation of not being able to directly inject/inspect
        // the private FileSystemWatcher instance without refactoring FileExplorerManager.
        // A full test of this would require DI or making the watcher property 'internal'.

        let newRootURL = tempRootURL.appendingPathComponent("NewWatchedRoot")
        try? FileManager.default.createDirectory(at: newRootURL, withIntermediateDirectories: true, attributes: nil)
        defer { try? FileManager.default.removeItem(at: newRootURL) }

        fileManager.setRootDirectory(newRootURL)

        // Indirect verification:
        // If FileSystemWatcher.start() logs a specific message, we could capture logs.
        // Or, if FileExplorerManager had a public property indicating watcher status.
        // For now, this test serves as a placeholder for future improvement if DI is introduced.
        // We will test the *effect* of the watcher in the next test.
        XCTAssertTrue(true, "Placeholder: Direct watcher instance/start test requires refactoring FileExplorerManager for DI or internal access to the watcher.")
    }

    func testFileSystemChangeEvent_TriggersRefresh() {
        let expectation = XCTestExpectation(description: "File system change detected and refresh occurs on rootItem")

        // Use a fresh manager for this test to ensure watcher is for tempRootURL
        let managerWithRealWatcher = FileExplorerManager()
        managerWithRealWatcher.setRootDirectory(tempRootURL)

        guard let rootItem = managerWithRealWatcher.rootItem else {
            XCTFail("RootItem is nil after setting root directory.")
            return
        }

        // Ensure root item is initially loaded so we can detect a refresh (isLoaded becomes false, then true)
        // Or, more reliably, check if a newly added file appears.
        if !rootItem.isLoaded {
            rootItem.loadChildren() // Initial load
        }
        let initialChildrenNames = Set(rootItem.children.map { $0.name })

        // Perform a file system operation that the watcher should detect
        let newFileName = "testTriggerFile_\(UUID().uuidString).txt"
        let newFileURL = tempRootURL.appendingPathComponent(newFileName)

        // Write a new file to trigger the watcher
        do {
            try "trigger content".write(to: newFileURL, atomically: true, encoding: .utf8)
            print("[Test] Created trigger file: \(newFileURL.path)")
        } catch {
            XCTFail("Failed to create trigger file: \(error)")
            return
        }

        // Wait for a short period to allow the FileSystemWatcher to detect the event
        // and for FileExplorerManager to process it (which involves async dispatch to main for refresh).
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Increased delay for FS events + refresh
            defer {
                try? FileManager.default.removeItem(at: newFileURL) // Clean up trigger file
            }

            guard let refreshedRootItem = managerWithRealWatcher.rootItem else {
                XCTFail("RootItem became nil after FS event, which is unexpected.")
                expectation.fulfill()
                return
            }

            // Check if the new file is now part of the children, indicating a refresh happened.
            let refreshedChildrenNames = Set(refreshedRootItem.children.map { $0.name })
            if refreshedChildrenNames.contains(newFileName) {
                print("[Test] Refresh successful, new file '\(newFileName)' found.")
                expectation.fulfill()
            } else {
                print("[Test] Refresh did not find new file. Initial children: \(initialChildrenNames). Refreshed children: \(refreshedChildrenNames)")
                // It's possible the refresh happened, but children didn't update as expected.
                // Check if isLoaded was toggled if that's part of refresh logic for root.
                // However, the most robust check is whether the content reflects the FS change.
                XCTFail("File system change did not result in the new file appearing in the root item's children.")
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 3.0) // Increased timeout for async operations and FS event propagation
    }

    // MARK: - Drag and Drop (Move) Tests

    func testHandleDrop_SuccessfulMove_FileToDirectory() throws {
        fileManager.setRootDirectory(tempRootURL)

        let sourceURL = self.itemD_URL! // FileD.txt in root
        let destFolderURL = self.itemA_URL! // FolderA in root

        guard let rootItem = fileManager.rootItem else { XCTFail("Root missing"); return }
        if !rootItem.isLoaded { rootItem.loadChildren() } // Ensure children are loaded to find items

        guard let destinationFolderItem = rootItem.children.first(where: { $0.url == destFolderURL && $0.isDirectory }) else {
            XCTFail("Setup error: Could not find destination FolderA in manager. Children: \(rootItem.children.map{$0.name})")
            return
        }

        // Pre-check: FileD exists in root, not in FolderA
        XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destFolderURL.appendingPathComponent(sourceURL.lastPathComponent)))
        XCTAssertTrue(rootItem.children.contains(where: { $0.url == sourceURL }))
        XCTAssertFalse(destinationFolderItem.children.contains(where: { $0.name == sourceURL.lastPathComponent }))

        fileManager.handleDrop(sourceURL: sourceURL, destinationDirectoryItem: destinationFolderItem)

        // Post-check: FileD moved to FolderA
        XCTAssertFalse(FileManager.default.fileExists(atPath: sourceURL.path), "Source file should no longer exist at old path.")
        let newPathForFileD = destFolderURL.appendingPathComponent(sourceURL.lastPathComponent)
        XCTAssertTrue(FileManager.default.fileExists(atPath: newPathForFileD.path), "File should exist at new path in destination folder.")

        // Check manager's internal state (tree structure)
        XCTAssertFalse(rootItem.children.contains(where: { $0.url == sourceURL }), "Root item should no longer contain the moved file.")
        XCTAssertTrue(destinationFolderItem.children.contains(where: { $0.name == sourceURL.lastPathComponent }), "Destination folder should now contain the moved file.")
        XCTAssertTrue(destinationFolderItem.isLoaded, "Destination folder should have been reloaded (isLoaded should be true if children were loaded).")
    }

    func testHandleDrop_SuccessfulMove_FolderToDirectory() throws {
        fileManager.setRootDirectory(tempRootURL)

        let sourceFolderURL = self.itemC_URL! // FolderC in root
        let destFolderURL = self.itemA_URL!   // FolderA in root

        guard let rootItem = fileManager.rootItem else { XCTFail("Root missing"); return }
        if !rootItem.isLoaded { rootItem.loadChildren() }

        guard let destinationFolderItem = rootItem.children.first(where: { $0.url == destFolderURL && $0.isDirectory }) else {
            XCTFail("Setup error: Could not find destination FolderA.")
            return
        }
         XCTAssertTrue(rootItem.children.contains(where: { $0.url == sourceFolderURL }), "FolderC should be in root initially.")

        fileManager.handleDrop(sourceURL: sourceFolderURL, destinationDirectoryItem: destinationFolderItem)

        XCTAssertFalse(FileManager.default.fileExists(atPath: sourceFolderURL.path), "Source folder should no longer exist at old path.")
        let newPathForFolderC = destFolderURL.appendingPathComponent(sourceFolderURL.lastPathComponent)
        XCTAssertTrue(FileManager.default.fileExists(atPath: newPathForFolderC.path), "Folder should exist at new path in destination folder.")

        XCTAssertFalse(rootItem.children.contains(where: { $0.url == sourceFolderURL }), "Root item should no longer contain FolderC.")
        XCTAssertTrue(destinationFolderItem.children.contains(where: { $0.name == sourceFolderURL.lastPathComponent }), "FolderA should now contain FolderC.")
        XCTAssertTrue(destinationFolderItem.isLoaded)
    }

    func testHandleDrop_Error_DestinationIsNotDirectory() throws {
        fileManager.setRootDirectory(tempRootURL)

        let sourceURL = self.itemD_URL! // FileD.txt from root
        let destFileURL = self.itemB_URL! // FileB.txt in FolderA (a file)

        guard let rootItem = fileManager.rootItem else { XCTFail("Root missing"); return }
        if !rootItem.isLoaded { rootItem.loadChildren() }
        guard let folderA = rootItem.children.first(where: {$0.url == itemA_URL}) else {XCTFail("FolderA missing"); return}
        if !folderA.isLoaded {folderA.loadChildren()}


        guard let destinationFileItem = folderA.children.first(where: { $0.url == destFileURL && !$0.isDirectory }) else {
            XCTFail("Setup error: Could not find destination FileB.txt.")
            return
        }

        // Record current state
        let initialRootChildrenCount = rootItem.children.count
        let initialFolderAChildrenCount = folderA.children.count

        fileManager.handleDrop(sourceURL: sourceURL, destinationDirectoryItem: destinationFileItem)

        // Assert no change in file system
        XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path), "Source file should still exist at old path.")
        // Assert no change in manager's tree
        XCTAssertEqual(rootItem.children.count, initialRootChildrenCount, "Root item's children count should not change.")
        XCTAssertEqual(folderA.children.count, initialFolderAChildrenCount, "FolderA's children count should not change.")
        XCTAssertTrue(rootItem.children.contains(where: { $0.url == sourceURL }))
    }

    func testHandleDrop_Error_MoveIntoSelf() throws {
        fileManager.setRootDirectory(tempRootURL)
        let folderA_URL = self.itemA_URL!

        guard let rootItem = fileManager.rootItem else { XCTFail("Root missing"); return }
        if !rootItem.isLoaded { rootItem.loadChildren() }

        guard let folderA_Item = rootItem.children.first(where: { $0.url == folderA_URL }) else {
            XCTFail("Setup error: Could not find FolderA.")
            return
        }
        let initialRootChildrenCount = rootItem.children.count

        fileManager.handleDrop(sourceURL: folderA_URL, destinationDirectoryItem: folderA_Item)

        XCTAssertTrue(FileManager.default.fileExists(atPath: folderA_URL.path), "FolderA should still exist at its original path.")
        XCTAssertEqual(rootItem.children.count, initialRootChildrenCount, "Root item's children count should not change.")
    }

    func testHandleDrop_Error_MoveParentIntoChild() throws {
        fileManager.setRootDirectory(tempRootURL)
        let folderA_URL = self.itemA_URL!
        let subFolderAA_URL = self.subFolderAA_URL!

        guard let rootItem = fileManager.rootItem else { XCTFail("Root missing"); return }
        if !rootItem.isLoaded { rootItem.loadChildren() } // Load root children (FolderA)

        guard let folderA_Item = rootItem.children.first(where: { $0.url == folderA_URL }) else {
            XCTFail("Setup error: Could not find FolderA.")
            return
        }
        if !folderA_Item.isExpanded || !folderA_Item.isLoaded { // Ensure SubFolderAA is loaded
             fileManager.toggleExpansion(for: folderA_Item) // Expands and loads children
        }

        guard let subFolderAA_Item = folderA_Item.children.first(where: { $0.url == subFolderAA_URL }) else {
            XCTFail("Setup error: Could not find SubFolderAA. Children of A: \(folderA_Item.children.map{$0.name})")
            return
        }
        let initialRootChildrenCount = rootItem.children.count

        fileManager.handleDrop(sourceURL: folderA_URL, destinationDirectoryItem: subFolderAA_Item)

        XCTAssertTrue(FileManager.default.fileExists(atPath: folderA_URL.path), "FolderA should still exist at its original path.")
        XCTAssertTrue(FileManager.default.fileExists(atPath: subFolderAA_URL.path), "SubFolderAA should still exist.")
        XCTAssertEqual(rootItem.children.count, initialRootChildrenCount, "Root item's children count should not change.")
    }

    func testHandleDrop_Error_NameConflictAtDestination() throws {
        // Create FileD.txt inside FolderA for conflict
        let conflictingFilePath = itemA_URL.appendingPathComponent(itemD_URL.lastPathComponent) // tempRootURL/FolderA/FileD.txt
        try "conflict content".write(to: conflictingFilePath, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: conflictingFilePath) } // Cleanup

        fileManager.setRootDirectory(tempRootURL)
        let sourceURL = self.itemD_URL! // tempRootURL/FileD.txt
        let destFolderURL = self.itemA_URL! // tempRootURL/FolderA/

        guard let rootItem = fileManager.rootItem else { XCTFail("Root missing"); return }
        if !rootItem.isLoaded { rootItem.loadChildren() }

        guard let destinationFolderItem = rootItem.children.first(where: { $0.url == destFolderURL }) else {
            XCTFail("Setup error: Could not find destination FolderA.")
            return
        }
         let initialRootChildrenCount = rootItem.children.count
         let initialDestChildrenCount = destinationFolderItem.children.count


        fileManager.handleDrop(sourceURL: sourceURL, destinationDirectoryItem: destinationFolderItem)

        // Assert no move occurred
        XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path), "Source FileD.txt should still exist in root.")
        XCTAssertTrue(FileManager.default.fileExists(atPath: conflictingFilePath.path), "Conflicting FileD.txt in FolderA should still exist.")
        let contentOfConflictingFile = try String(contentsOf: conflictingFilePath)
        XCTAssertEqual(contentOfConflictingFile, "conflict content", "Content of conflicting file should not have changed.")

        XCTAssertEqual(rootItem.children.count, initialRootChildrenCount, "Root item's children count should not change.")
        XCTAssertEqual(destinationFolderItem.children.count, initialDestChildrenCount, "Destination folder's children count should not change after failed drop.")
        XCTAssertTrue(rootItem.children.contains(where: {$0.url == sourceURL}) , "Source file should still be in root item's children")
    }
}
