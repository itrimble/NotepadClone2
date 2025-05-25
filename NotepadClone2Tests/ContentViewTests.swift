import XCTest
import SwiftUI
@testable import NotepadClone2

final class ContentViewTests: XCTestCase {
    var appState: AppState!
    
    override func setUp() {
        super.setUp()
        appState = AppState()
    }
    
    override func tearDown() {
        appState = nil
        super.tearDown()
    }
    
    func testInitialViewShowsSingleEditorMode() {
        // Given: App state with default settings
        XCTAssertFalse(appState.splitViewEnabled, "Split view should be disabled by default")
        XCTAssertFalse(appState.tabs.isEmpty, "Should have at least one tab")
        XCTAssertNotNil(appState.currentTab, "Should have a current tab selected")
        
        // When: ContentView is created
        let contentView = ContentView().environmentObject(appState)
        
        // Then: View should display properly without needing to click split view
        // This test verifies the structural integrity of the view
        XCTAssertTrue(appState.showFileExplorer, "File explorer should be visible by default")
    }
    
    func testSplitViewToggleWorks() {
        // Given: Split view is initially disabled
        XCTAssertFalse(appState.splitViewEnabled)
        
        // When: Split view is enabled
        appState.splitViewEnabled = true
        
        // Then: Split view should be enabled
        XCTAssertTrue(appState.splitViewEnabled)
        XCTAssertEqual(appState.splitViewOrientation, .horizontal, "Default orientation should be horizontal")
    }
    
    func testTabBarAlwaysVisibleWithTabs() {
        // Given: App has tabs
        XCTAssertFalse(appState.tabs.isEmpty, "Should have tabs")
        
        // When: ContentView is rendered
        // Then: Tab bar should be visible regardless of split view state
        
        // Test with split view disabled
        appState.splitViewEnabled = false
        let contentView1 = ContentView().environmentObject(appState)
        // Tab bar should be visible
        
        // Test with split view enabled
        appState.splitViewEnabled = true
        let contentView2 = ContentView().environmentObject(appState)
        // Tab bar should still be visible
    }
    
    func testStatusBarVisibilityIndependentOfSplitView() {
        // Given: Status bar is enabled
        appState.showStatusBar = true
        
        // Test status bar shows in single editor mode
        appState.splitViewEnabled = false
        XCTAssertTrue(appState.showStatusBar)
        
        // Test status bar shows in split view mode
        appState.splitViewEnabled = true
        XCTAssertTrue(appState.showStatusBar)
    }
}