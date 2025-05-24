import XCTest
import AppKit
import SwiftUI
@testable import NotepadClone2

class TextInputTests: XCTestCase {
    var appState: AppState!
    var window: NSWindow!
    
    override func setUp() {
        super.setUp()
        appState = AppState()
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
    }
    
    override func tearDown() {
        window = nil
        appState = nil
        super.tearDown()
    }
    
    func testTextViewIsEditableOnCreation() {
        // Given
        let customTextView = CustomTextView(
            text: .constant(""),
            attributedText: .constant(NSAttributedString()),
            appTheme: .system,
            showLineNumbers: false,
            language: .none,
            document: Document()
        )
        
        // When
        let scrollView = customTextView.makeNSView(context: TestContext(customTextView))
        let textView = scrollView.documentView as! NSTextView
        
        // Then
        XCTAssertTrue(textView.isEditable, "Text view should be editable")
        XCTAssertTrue(textView.isSelectable, "Text view should be selectable")
        XCTAssertFalse(textView.isFieldEditor, "Text view should not be a field editor")
    }
    
    func testTextViewAcceptsFirstResponder() {
        // Given
        let customTextView = CustomTextView(
            text: .constant(""),
            attributedText: .constant(NSAttributedString()),
            appTheme: .system,
            showLineNumbers: false,
            language: .none,
            document: Document()
        )
        
        // When
        let scrollView = customTextView.makeNSView(context: TestContext(customTextView))
        let textView = scrollView.documentView as! NSTextView
        window.contentView = scrollView
        
        // Then
        XCTAssertTrue(textView.acceptsFirstResponder, "Text view should accept first responder")
    }
    
    func testTextViewCanBecomeFirstResponder() {
        // Given
        let customTextView = CustomTextView(
            text: .constant(""),
            attributedText: .constant(NSAttributedString()),
            appTheme: .system,
            showLineNumbers: false,
            language: .none,
            document: Document()
        )
        
        // When
        let scrollView = customTextView.makeNSView(context: TestContext(customTextView))
        let textView = scrollView.documentView as! NSTextView
        window.contentView = scrollView
        window.makeKeyAndOrderFront(nil)
        
        let becameFirstResponder = window.makeFirstResponder(textView)
        
        // Then
        XCTAssertTrue(becameFirstResponder, "Text view should successfully become first responder")
        XCTAssertEqual(window.firstResponder, textView, "Window's first responder should be the text view")
    }
    
    func testTextInputUpdatesBinding() {
        // Given
        var text = ""
        var attributedText = NSAttributedString()
        let document = Document()
        
        let customTextView = CustomTextView(
            text: Binding(get: { text }, set: { text = $0 }),
            attributedText: Binding(get: { attributedText }, set: { attributedText = $0 }),
            appTheme: .system,
            showLineNumbers: false,
            language: .none,
            document: document
        )
        
        let context = TestContext(customTextView)
        let scrollView = customTextView.makeNSView(context: context)
        let textView = scrollView.documentView as! NSTextView
        
        // When
        textView.string = "Hello, World!"
        
        // Simulate text did change notification
        NotificationCenter.default.post(
            name: NSText.didChangeNotification,
            object: textView
        )
        
        // Allow time for async updates
        let expectation = XCTestExpectation(description: "Text binding updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(text, "Hello, World!", "Text binding should be updated")
    }
    
    func testTypingDoesNotTriggerColorPicker() {
        // Given
        let customTextView = CustomTextView(
            text: .constant(""),
            attributedText: .constant(NSAttributedString()),
            appTheme: .system,
            showLineNumbers: false,
            language: .none,
            document: Document()
        )
        
        // When
        let scrollView = customTextView.makeNSView(context: TestContext(customTextView))
        let textView = scrollView.documentView as! NSTextView
        
        // Then
        XCTAssertFalse(textView.usesFontPanel, "Font panel should be disabled")
        XCTAssertFalse(textView.usesInspectorBar, "Inspector bar should be disabled")
    }
}

// Test helper for creating context
private struct TestContext {
    let coordinator: CustomTextView.Coordinator
    
    init(_ customTextView: CustomTextView) {
        self.coordinator = customTextView.makeCoordinator()
    }
}