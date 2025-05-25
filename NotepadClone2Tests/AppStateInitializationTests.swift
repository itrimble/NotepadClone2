import XCTest
@testable import NotepadClone2

final class AppStateInitializationTests: XCTestCase {
    
    func testAppStateInitializesWithAtLeastOneTab() {
        // Given: A new AppState instance
        let appState = AppState()
        
        // Then: It should have at least one tab
        XCTAssertFalse(appState.tabs.isEmpty, "AppState should initialize with at least one tab")
        XCTAssertNotNil(appState.currentTab, "AppState should have a current tab selected")
        
        if let currentTab = appState.currentTab {
            XCTAssertTrue(currentTab >= 0 && currentTab < appState.tabs.count, 
                         "Current tab index should be valid")
        }
    }
    
    func testAppStateShowsFileExplorerByDefault() {
        // Given: A new AppState instance
        let appState = AppState()
        
        // Then: File explorer should be visible by default
        XCTAssertTrue(appState.showFileExplorer, "File explorer should be visible by default")
    }
    
    func testAppStateSplitViewDisabledByDefault() {
        // Given: A new AppState instance
        let appState = AppState()
        
        // Then: Split view should be disabled by default
        XCTAssertFalse(appState.splitViewEnabled, "Split view should be disabled by default")
    }
    
    func testAppStateCreatesDefaultDocumentWhenNoSession() {
        // Given: UserDefaults cleared to ensure no session
        UserDefaults.standard.removeObject(forKey: "restore_session")
        UserDefaults.standard.removeObject(forKey: "session_tabs")
        
        // When: Creating a new AppState
        let appState = AppState()
        
        // Then: Should have exactly one untitled document
        XCTAssertEqual(appState.tabs.count, 1, "Should have exactly one tab")
        XCTAssertEqual(appState.tabs[0].displayName, "Untitled", "Default document should be untitled")
        XCTAssertEqual(appState.currentTab, 0, "Current tab should be the first tab")
    }
    
    func testContentViewDisplaysCorrectlyOnStartup() {
        // Given: An AppState with default initialization
        let appState = AppState()
        
        // When: App starts up (split view is disabled by default)
        XCTAssertFalse(appState.splitViewEnabled)
        
        // Then: The single editor mode should be active
        // And there should be a valid current tab to display
        XCTAssertNotNil(appState.currentTab)
        if let currentTab = appState.currentTab {
            XCTAssertTrue(currentTab < appState.tabs.count, "Current tab should be valid")
            
            // The document should be ready to display
            let document = appState.tabs[currentTab]
            XCTAssertNotNil(document.attributedText, "Document should have attributed text")
        }
    }
}