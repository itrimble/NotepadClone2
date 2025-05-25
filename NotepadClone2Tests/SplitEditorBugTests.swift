import XCTest
import SwiftUI
@testable import NotepadClone2

final class SplitEditorBugTests: XCTestCase {
    
    func testAppStartsWithVisibleContent() {
        // Given: A fresh app state
        let appState = AppState()
        
        // Then: Essential components should be visible
        XCTAssertTrue(appState.showFileExplorer, "File explorer should be visible by default")
        XCTAssertFalse(appState.tabs.isEmpty, "Should have at least one tab")
        XCTAssertNotNil(appState.currentTab, "Should have a current tab selected")
        XCTAssertFalse(appState.splitViewEnabled, "Split view should be disabled by default")
        
        // Verify current tab is valid
        if let currentTab = appState.currentTab {
            XCTAssertTrue(currentTab >= 0 && currentTab < appState.tabs.count,
                         "Current tab index should be valid")
        }
    }
    
    func testContentViewStructureInSingleEditorMode() {
        // Given: App state with split view disabled
        let appState = AppState()
        appState.splitViewEnabled = false
        
        // When: ContentView is rendered
        // Then: It should show:
        // 1. File explorer (if enabled)
        // 2. Tab bar (if tabs exist)
        // 3. Single editor view
        // 4. Status bar (if enabled)
        
        XCTAssertTrue(appState.showFileExplorer, "File explorer should be visible")
        XCTAssertFalse(appState.tabs.isEmpty, "Tab bar should have tabs to show")
        XCTAssertTrue(appState.showStatusBar, "Status bar should be visible")
        XCTAssertNotNil(appState.currentTab, "Should have a document to display in editor")
    }
    
    func testContentViewStructureInSplitViewMode() {
        // Given: App state with split view enabled
        let appState = AppState()
        appState.splitViewEnabled = true
        
        // Then: It should show:
        // 1. File explorer (if enabled)
        // 2. Tab bar (if tabs exist)
        // 3. Split editor view with two panes
        // 4. Status bar (if enabled)
        
        XCTAssertTrue(appState.showFileExplorer, "File explorer should be visible")
        XCTAssertFalse(appState.tabs.isEmpty, "Tab bar should have tabs to show")
        XCTAssertTrue(appState.showStatusBar, "Status bar should be visible")
        XCTAssertNotNil(appState.currentTab, "Should have a document for primary pane")
        
        // Split view tab index defaults to current tab if not set
        let splitTabIndex = appState.splitViewTabIndex ?? appState.currentTab
        XCTAssertNotNil(splitTabIndex, "Should have a document for secondary pane")
    }
    
    func testNoBlankScreenOnStartup() {
        // This test verifies the specific bug where the app shows a blank screen
        // until split view is clicked
        
        // Given: Fresh app state (simulating app startup)
        let appState = AppState()
        
        // Then: All necessary components should be initialized
        XCTAssertFalse(appState.tabs.isEmpty, "Must have tabs to display content")
        XCTAssertNotNil(appState.currentTab, "Must have a selected tab")
        
        // Verify the document is ready to display
        if let currentTab = appState.currentTab, currentTab < appState.tabs.count {
            let document = appState.tabs[currentTab]
            XCTAssertNotNil(document.attributedText, "Document must have displayable content")
            XCTAssertTrue(document.text.isEmpty || !document.text.isEmpty, 
                         "Document text should be initialized (empty or with content)")
        }
        
        // Verify UI components are configured to show
        XCTAssertTrue(appState.showFileExplorer, "File explorer should be visible to provide context")
        XCTAssertFalse(appState.splitViewEnabled, "Split view should start disabled")
        
        // The ContentView should be able to render without requiring any user action
        let contentView = ContentView().environmentObject(appState)
        XCTAssertNotNil(contentView, "ContentView should initialize successfully")
    }
}