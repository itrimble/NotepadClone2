import XCTest
@testable import NotepadClone // Assuming the module name is NotepadClone

class MCPManagerTests: XCTestCase {

    var appState: AppState!
    var mcpManager: MCPManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Initialize AppState and MCPManager for use in tests
        // AppState initializes MCPManager internally
        appState = AppState()
        mcpManager = appState.mcpManager // MCPManager is initialized by AppState
    }

    override func tearDownWithError() throws {
        appState = nil
        mcpManager = nil
        try super.tearDownWithError()
    }

    func testLoadPlugins() throws {
        // MCPManager's init calls loadPlugins, which should load TimestampPlugin

        // 1. Assert that manager.availablePlugins is not empty
        XCTAssertFalse(mcpManager.availablePlugins.isEmpty, "Available plugins should not be empty after initialization.")

        // 2. Assert that one of the loaded plugins has the ID "com.example.timestamp"
        let timestampPluginExists = mcpManager.availablePlugins.contains { plugin in
            plugin.id == "com.example.timestamp"
        }
        XCTAssertTrue(timestampPluginExists, "TimestampPlugin (ID: com.example.timestamp) should be loaded.")
    }

    func testExecutePlugin() throws {
        // 1. Create a dummy MCPContext
        let context = MCPContext(
            appState: appState,
            currentText: nil,
            selectedText: nil,
            currentFileURL: nil
        )

        // 2. Call manager.executePlugin for TimestampPlugin
        let pluginID = "com.example.timestamp"
        let result = try mcpManager.executePlugin(byId: pluginID, context: context)

        // 3. Assert that the execution is successful and result.insertedText is not nil
        XCTAssertTrue(result.success, "Plugin execution should be successful.")
        XCTAssertNotNil(result.insertedText, "Inserted text should not be nil after executing TimestampPlugin.")

        // Optional: Verify format if needed, though TimestampPluginTests covers this more directly
        if let insertedText = result.insertedText {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            XCTAssertNotNil(formatter.date(from: insertedText), "Inserted text format should be yyyy-MM-dd HH:mm:ss")
        }
    }

    func testExecuteNonExistentPlugin() throws {
        // 1. Create a dummy MCPContext
        let context = MCPContext(
            appState: appState,
            currentText: nil,
            selectedText: nil,
            currentFileURL: nil
        )

        let nonExistentPluginID = "non.existent.plugin.id"

        // 2. Call manager.executePlugin with a non-existent ID and assert that an error is thrown
        XCTAssertThrowsError(try mcpManager.executePlugin(byId: nonExistentPluginID, context: context)) { error in
            // Optionally, assert the type of error or its properties
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "MCPManagerError", "Error domain should be MCPManagerError.")
            XCTAssertEqual(nsError.code, 1, "Error code should indicate plugin not found.")
            XCTAssertTrue(nsError.localizedDescription.contains("Plugin with ID \(nonExistentPluginID) not found."), "Error message mismatch.")
        }
    }
}
