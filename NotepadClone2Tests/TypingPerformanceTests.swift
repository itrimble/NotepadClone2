import XCTest
import SwiftUI
@testable import NotepadClone2

class TypingPerformanceTests: XCTestCase {
    
    var document: Document!
    var appState: AppState!
    
    override func setUp() {
        super.setUp()
        document = Document()
        appState = AppState()
    }
    
    override func tearDown() {
        document = nil
        appState = nil
        super.tearDown()
    }
    
    // MARK: - Basic Typing Tests
    
    func testBasicTyping() {
        // Given
        let testText = "Hello, World!"
        
        // When
        document.text = testText
        
        // Then
        XCTAssertEqual(document.text, testText)
        XCTAssertTrue(document.hasUnsavedChanges)
    }
    
    func testRapidTyping() {
        // Given
        let characters = "abcdefghijklmnopqrstuvwxyz"
        var resultText = ""
        
        // When - Simulate rapid typing
        measure {
            resultText = ""
            for char in characters {
                resultText.append(char)
                document.text = resultText
            }
        }
        
        // Then
        XCTAssertEqual(document.text, characters)
        XCTAssertEqual(document.text.count, 26)
    }
    
    func testTypingWithWordCount() {
        // Given
        let testText = "The quick brown fox jumps over the lazy dog"
        
        // When
        document.text = testText
        
        // Wait a bit for word count to update
        let expectation = XCTestExpectation(description: "Word count update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
        
        // Then
        XCTAssertEqual(document.wordCount, 9)
    }
    
    // MARK: - Concurrent Update Tests
    
    func testConcurrentTextUpdates() {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent updates")
        expectation.expectedFulfillmentCount = 100
        
        // When - Simulate concurrent updates
        for i in 0..<100 {
            DispatchQueue.global().async {
                self.document.text = "Update \(i)"
                expectation.fulfill()
            }
        }
        
        // Wait for all updates
        wait(for: [expectation], timeout: 5.0)
        
        // Then - Document should have a valid state
        XCTAssertFalse(document.text.isEmpty)
        XCTAssertTrue(document.hasUnsavedChanges)
    }
    
    // MARK: - State Update Tests
    
    func testNoCircularUpdates() {
        // Given
        var updateCount = 0
        let cancellable = document.$text.sink { _ in
            updateCount += 1
        }
        
        // When
        document.text = "Test"
        
        // Wait a bit to ensure no circular updates
        let expectation = XCTestExpectation(description: "No circular updates")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
        
        // Then - Should only have one update
        XCTAssertEqual(updateCount, 1, "Text should only update once, not circularly")
        
        cancellable.cancel()
    }
    
    func testAttributedTextSync() {
        // Given
        let testText = "Test attributed text"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.black
        ]
        let attributedString = NSAttributedString(string: testText, attributes: attributes)
        
        // When
        document.attributedText = attributedString
        
        // Wait for sync
        let expectation = XCTestExpectation(description: "Attributed text sync")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
        
        // Then
        XCTAssertEqual(document.text, testText)
        XCTAssertEqual(document.attributedText.string, testText)
    }
    
    // MARK: - Performance Tests
    
    func testLargeTextPerformance() {
        // Given
        let largeText = String(repeating: "Lorem ipsum dolor sit amet. ", count: 1000)
        
        // When/Then - Measure performance
        measure {
            document.text = largeText
        }
        
        XCTAssertEqual(document.text.count, largeText.count)
    }
    
    func testTypingResponsiveness() {
        // Given
        let testString = "Testing typing responsiveness"
        var currentText = ""
        
        // When - Simulate typing with timing
        let startTime = Date()
        
        for char in testString {
            currentText.append(char)
            document.text = currentText
        }
        
        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)
        
        // Then - Should complete quickly (less than 1 second for ~30 characters)
        XCTAssertLessThan(totalTime, 1.0, "Typing should be responsive")
        XCTAssertEqual(document.text, testString)
    }
    
    // MARK: - Cursor Position Tests
    
    func testCursorPositionUpdate() {
        // Given
        document.text = "Hello, World!"
        let range = NSRange(location: 5, length: 0)
        
        // When
        document.updateCursorPosition(from: range)
        
        // Then
        XCTAssertEqual(document.cursorPosition, 5)
        XCTAssertEqual(document.lineNumber, 1)
        XCTAssertEqual(document.columnNumber, 6) // 1-based
    }
    
    func testCursorPositionWithNewlines() {
        // Given
        document.text = "Line 1\nLine 2\nLine 3"
        let range = NSRange(location: 14, length: 0) // Position in "Line 3"
        
        // When
        document.updateCursorPosition(from: range)
        
        // Then
        XCTAssertEqual(document.lineNumber, 3)
        XCTAssertEqual(document.columnNumber, 1)
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyTextHandling() {
        // Given/When
        document.text = ""
        
        // Then
        XCTAssertEqual(document.text, "")
        XCTAssertEqual(document.wordCount, 0)
        XCTAssertEqual(document.lineNumber, 1)
        XCTAssertEqual(document.columnNumber, 1)
    }
    
    func testUnicodeTextHandling() {
        // Given
        let unicodeText = "Hello 👋 World 🌍 Test 🧪"
        
        // When
        document.text = unicodeText
        
        // Then
        XCTAssertEqual(document.text, unicodeText)
        XCTAssertTrue(document.hasUnsavedChanges)
    }
    
    func testVeryLongLineHandling() {
        // Given
        let longLine = String(repeating: "a", count: 10000)
        
        // When
        let startTime = Date()
        document.text = longLine
        let endTime = Date()
        
        // Then
        XCTAssertEqual(document.text.count, 10000)
        XCTAssertLessThan(endTime.timeIntervalSince(startTime), 0.5, "Should handle long lines efficiently")
    }
}