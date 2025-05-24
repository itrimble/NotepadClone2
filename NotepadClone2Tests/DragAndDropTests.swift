import XCTest
import SwiftUI
import UniformTypeIdentifiers
@testable import NotepadClone2

class DragAndDropTests: XCTestCase {
    var appState: AppState!
    var tempDirectory: URL!
    var testFiles: [URL] = []
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create test app state
        appState = AppState()
        
        // Create temporary directory for test files
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("DragDropTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        // Create test files
        try createTestFiles()
    }
    
    override func tearDownWithError() throws {
        // Clean up test files
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        
        appState = nil
        testFiles.removeAll()
        
        try super.tearDownWithError()
    }
    
    private func createTestFiles() throws {
        // Create a plain text file
        let textFile = tempDirectory.appendingPathComponent("test.txt")
        try "Hello, World!".write(to: textFile, atomically: true, encoding: .utf8)
        testFiles.append(textFile)
        
        // Create a Swift file
        let swiftFile = tempDirectory.appendingPathComponent("test.swift")
        try "import Foundation\nprint(\"Hello, Swift!\")".write(to: swiftFile, atomically: true, encoding: .utf8)
        testFiles.append(swiftFile)
        
        // Create a JSON file
        let jsonFile = tempDirectory.appendingPathComponent("test.json")
        try "{\"message\": \"Hello, JSON!\"}".write(to: jsonFile, atomically: true, encoding: .utf8)
        testFiles.append(jsonFile)
        
        // Create a file with no extension
        let noExtFile = tempDirectory.appendingPathComponent("README")
        try "This is a README file".write(to: noExtFile, atomically: true, encoding: .utf8)
        testFiles.append(noExtFile)
        
        // Create an unsupported binary file
        let binaryFile = tempDirectory.appendingPathComponent("test.bin")
        let binaryData = Data([0x00, 0x01, 0x02, 0x03, 0xFF])
        try binaryData.write(to: binaryFile)
        testFiles.append(binaryFile)
    }
    
    // MARK: - File Opening Tests
    
    func testOpenSingleDocument() {
        // Given
        let textFile = testFiles[0] // test.txt
        let initialTabCount = appState.tabs.count
        
        // When
        let success = appState.openDocument(from: textFile)
        
        // Then
        XCTAssertTrue(success, "Should successfully open text file")
        XCTAssertEqual(appState.tabs.count, initialTabCount + 1, "Should add one new tab")
        
        // Verify the document content
        let newTab = appState.tabs.last!
        XCTAssertEqual(newTab.fileURL, textFile, "Document should have correct file URL")
        XCTAssertEqual(newTab.text, "Hello, World!", "Document should have correct content")
        XCTAssertFalse(newTab.hasUnsavedChanges, "Newly opened document should not have unsaved changes")
    }
    
    func testOpenMultipleDocuments() {
        // Given
        let filesToOpen = Array(testFiles.prefix(3)) // text, swift, json files
        let initialTabCount = appState.tabs.count
        
        // When
        appState.openDocuments(from: filesToOpen)
        
        // Then
        XCTAssertEqual(appState.tabs.count, initialTabCount + filesToOpen.count, "Should add correct number of tabs")
        
        // Verify each file was opened correctly
        let newTabs = appState.tabs.suffix(filesToOpen.count)
        for (index, tab) in newTabs.enumerated() {
            XCTAssertEqual(tab.fileURL, filesToOpen[index], "Tab \(index) should have correct file URL")
            XCTAssertFalse(tab.hasUnsavedChanges, "Tab \(index) should not have unsaved changes")
        }
    }
    
    func testOpenAlreadyOpenDocument() {
        // Given
        let textFile = testFiles[0]
        let success = appState.openDocument(from: textFile)
        XCTAssertTrue(success)
        let tabCountAfterFirstOpen = appState.tabs.count
        let originalTabIndex = appState.currentTab
        
        // When - try to open the same file again
        let successSecond = appState.openDocument(from: textFile)
        
        // Then
        XCTAssertTrue(successSecond, "Should return success when switching to existing tab")
        XCTAssertEqual(appState.tabs.count, tabCountAfterFirstOpen, "Should not create a new tab")
        
        // Should switch to the existing tab
        let expectation = XCTestExpectation(description: "Tab should switch")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Find the tab with this file URL
            if let existingTabIndex = self.appState.tabs.firstIndex(where: { $0.fileURL == textFile }) {
                XCTAssertEqual(self.appState.currentTab, existingTabIndex, "Should switch to existing tab")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testOpenNonExistentFile() {
        // Given
        let nonExistentFile = tempDirectory.appendingPathComponent("nonexistent.txt")
        let initialTabCount = appState.tabs.count
        
        // When
        let success = appState.openDocument(from: nonExistentFile)
        
        // Then
        XCTAssertFalse(success, "Should fail to open non-existent file")
        XCTAssertEqual(appState.tabs.count, initialTabCount, "Should not add any new tabs")
    }
    
    // MARK: - File Validation Tests
    
    func testValidFileTypes() {
        // Test supported file types
        let textFile = testFiles[0] // .txt
        let swiftFile = testFiles[1] // .swift
        let jsonFile = testFiles[2] // .json
        let noExtFile = testFiles[3] // no extension
        
        XCTAssertTrue(isValidFileForOpening(textFile), "Should accept .txt files")
        XCTAssertTrue(isValidFileForOpening(swiftFile), "Should accept .swift files")
        XCTAssertTrue(isValidFileForOpening(jsonFile), "Should accept .json files")
        XCTAssertTrue(isValidFileForOpening(noExtFile), "Should accept files with no extension")
    }
    
    func testInvalidFileTypes() {
        // Test unsupported file types
        let binaryFile = testFiles[4] // .bin
        XCTAssertFalse(isValidFileForOpening(binaryFile), "Should reject .bin files")
        
        // Test non-existent file
        let nonExistentFile = tempDirectory.appendingPathComponent("nonexistent.txt")
        XCTAssertFalse(isValidFileForOpening(nonExistentFile), "Should reject non-existent files")
    }
    
    // MARK: - Theme Integration Tests
    
    func testOpenedDocumentUsesCurrentTheme() {
        // Given
        appState.setTheme(.dark)
        let textFile = testFiles[0]
        
        // When
        let success = appState.openDocument(from: textFile)
        
        // Then
        XCTAssertTrue(success)
        let newTab = appState.tabs.last!
        XCTAssertEqual(newTab.appTheme, .dark, "Opened document should use current app theme")
    }
    
    // MARK: - Performance Tests
    
    func testOpenManyFilesPerformance() {
        // Create multiple temporary files
        var manyFiles: [URL] = []
        
        for i in 0..<10 {
            let file = tempDirectory.appendingPathComponent("perf_test_\(i).txt")
            try! "Content for file \(i)".write(to: file, atomically: true, encoding: .utf8)
            manyFiles.append(file)
        }
        
        // Measure performance of opening many files
        measure {
            appState.openDocuments(from: manyFiles)
        }
        
        // Verify all files were opened
        XCTAssertGreaterThanOrEqual(appState.tabs.count, manyFiles.count, "Should have opened all files")
    }
    
    // MARK: - Error Handling Tests
    
    func testOpenFileWithReadPermissionDenied() {
        // This test simulates a file that exists but can't be read
        // In a real scenario, this would be a file with restricted permissions
        
        let protectedFile = tempDirectory.appendingPathComponent("protected.txt")
        try! "Protected content".write(to: protectedFile, atomically: true, encoding: .utf8)
        
        // Remove read permissions (this might not work in all test environments)
        var attributes = try! FileManager.default.attributesOfItem(atPath: protectedFile.path)
        attributes[.posixPermissions] = 0o000
        try! FileManager.default.setAttributes(attributes, ofItemAtPath: protectedFile.path)
        
        let initialTabCount = appState.tabs.count
        
        // When
        let success = appState.openDocument(from: protectedFile)
        
        // Then
        XCTAssertFalse(success, "Should fail to open protected file")
        XCTAssertEqual(appState.tabs.count, initialTabCount, "Should not add any new tabs")
        
        // Restore permissions for cleanup
        attributes[.posixPermissions] = 0o644
        try! FileManager.default.setAttributes(attributes, ofItemAtPath: protectedFile.path)
    }
    
    // MARK: - Tab Management Integration Tests
    
    func testOpenDocumentSwitchesToNewTab() {
        // Given
        let initialCurrentTab = appState.currentTab
        let textFile = testFiles[0]
        
        // When
        let success = appState.openDocument(from: textFile)
        
        // Then
        XCTAssertTrue(success)
        
        let expectation = XCTestExpectation(description: "Should switch to new tab")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.appState.currentTab, self.appState.tabs.count - 1, "Should switch to the newly opened tab")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testOpenEmptyFile() {
        // Given
        let emptyFile = tempDirectory.appendingPathComponent("empty.txt")
        try! "".write(to: emptyFile, atomically: true, encoding: .utf8)
        
        // When
        let success = appState.openDocument(from: emptyFile)
        
        // Then
        XCTAssertTrue(success, "Should successfully open empty file")
        let newTab = appState.tabs.last!
        XCTAssertEqual(newTab.text, "", "Empty file should have empty text content")
        XCTAssertEqual(newTab.attributedText.string, "", "Empty file should have empty attributed text")
    }
    
    // MARK: - Helper Methods
    
    /// Validates if a file can be opened in the editor (same logic as ContentView)
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
}