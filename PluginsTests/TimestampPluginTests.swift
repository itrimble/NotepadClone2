import XCTest
@testable import NotepadClone // Assuming the module name is NotepadClone

class TimestampPluginTests: XCTestCase {

    var appState: AppState!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Initialize a dummy AppState for use in tests
        // This might need adjustment if AppState has complex dependencies
        appState = AppState()
    }

    override func tearDownWithError() throws {
        appState = nil
        try super.tearDownWithError()
    }

    func testExecute() throws {
        // 1. Create an instance of TimestampPlugin
        let plugin = TimestampPlugin()

        // 2. Create a dummy MCPContext
        //    MCPContext requires an AppState instance.
        //    Other properties of MCPContext (currentText, selectedText, currentFileURL)
        //    are not directly used by TimestampPlugin, so they can be nil or default.
        let context = MCPContext(
            appState: appState,
            currentText: nil,
            selectedText: nil,
            currentFileURL: nil
        )

        // 3. Call plugin.execute(context: context)
        let result = try plugin.execute(context: context)

        // 4. Assert that result.success is true
        XCTAssertTrue(result.success, "Plugin execution should be successful.")

        // 5. Assert that result.insertedText is not nil and is a string
        XCTAssertNotNil(result.insertedText, "Inserted text should not be nil.")
        XCTAssertTrue(result.insertedText is String, "Inserted text should be a String.")

        // 6. Verify the date format is "yyyy-MM-dd HH:mm:ss"
        if let insertedText = result.insertedText {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateFromString = formatter.date(from: insertedText)
            XCTAssertNotNil(dateFromString, "Inserted text '\(insertedText)' should match the format 'yyyy-MM-dd HH:mm:ss'.")
        } else {
            XCTFail("insertedText was nil, cannot verify format.")
        }
    }
}
