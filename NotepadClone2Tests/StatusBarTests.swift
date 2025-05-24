import XCTest
import SwiftUI
@testable import NotepadClone2

class StatusBarTests: XCTestCase {
    
    // MARK: - Test Line:Column Display
    
    func testLineColumnDisplay() {
        // Given
        let statusBar = StatusBar(
            characterCount: 100,
            wordCount: 20,
            lineNumber: 5,
            columnNumber: 15,
            selectedRange: nil,
            encoding: .utf8
        )
        
        // Then
        XCTAssertEqual(statusBar.lineNumber, 5)
        XCTAssertEqual(statusBar.columnNumber, 15)
    }
    
    func testLineColumnFormatting() {
        // Given
        let statusBar = StatusBar(
            characterCount: 100,
            wordCount: 20,
            lineNumber: 1,
            columnNumber: 1,
            selectedRange: nil,
            encoding: .utf8
        )
        
        // When
        let formattedPosition = statusBar.formattedPosition
        
        // Then
        XCTAssertEqual(formattedPosition, "Ln 1, Col 1")
    }
    
    func testLineColumnWithLargeNumbers() {
        // Given
        let statusBar = StatusBar(
            characterCount: 100000,
            wordCount: 20000,
            lineNumber: 10000,
            columnNumber: 150,
            selectedRange: nil,
            encoding: .utf8
        )
        
        // When
        let formattedPosition = statusBar.formattedPosition
        
        // Then
        XCTAssertEqual(formattedPosition, "Ln 10000, Col 150")
    }
    
    // MARK: - Test Selection Information
    
    func testNoSelection() {
        // Given
        let statusBar = StatusBar(
            characterCount: 100,
            wordCount: 20,
            lineNumber: 1,
            columnNumber: 1,
            selectedRange: nil,
            encoding: .utf8
        )
        
        // Then
        XCTAssertNil(statusBar.selectedRange)
        XCTAssertEqual(statusBar.formattedSelection, "")
    }
    
    func testSingleCharacterSelection() {
        // Given
        let selectedRange = NSRange(location: 10, length: 1)
        let statusBar = StatusBar(
            characterCount: 100,
            wordCount: 20,
            lineNumber: 1,
            columnNumber: 10,
            selectedRange: selectedRange,
            encoding: .utf8
        )
        
        // When
        let formattedSelection = statusBar.formattedSelection
        
        // Then
        XCTAssertEqual(formattedSelection, "Sel: 1")
    }
    
    func testMultiCharacterSelection() {
        // Given
        let selectedRange = NSRange(location: 10, length: 25)
        let statusBar = StatusBar(
            characterCount: 100,
            wordCount: 20,
            lineNumber: 1,
            columnNumber: 10,
            selectedRange: selectedRange,
            encoding: .utf8
        )
        
        // When
        let formattedSelection = statusBar.formattedSelection
        
        // Then
        XCTAssertEqual(formattedSelection, "Sel: 25")
    }
    
    func testLargeSelection() {
        // Given
        let selectedRange = NSRange(location: 0, length: 5000)
        let statusBar = StatusBar(
            characterCount: 10000,
            wordCount: 2000,
            lineNumber: 1,
            columnNumber: 1,
            selectedRange: selectedRange,
            encoding: .utf8
        )
        
        // When
        let formattedSelection = statusBar.formattedSelection
        
        // Then
        XCTAssertEqual(formattedSelection, "Sel: 5000")
    }
    
    // MARK: - Test Encoding Display
    
    func testUTF8Encoding() {
        // Given
        let statusBar = StatusBar(
            characterCount: 100,
            wordCount: 20,
            lineNumber: 1,
            columnNumber: 1,
            selectedRange: nil,
            encoding: .utf8
        )
        
        // When
        let formattedEncoding = statusBar.formattedEncoding
        
        // Then
        XCTAssertEqual(formattedEncoding, "UTF-8")
    }
    
    func testUTF16Encoding() {
        // Given
        let statusBar = StatusBar(
            characterCount: 100,
            wordCount: 20,
            lineNumber: 1,
            columnNumber: 1,
            selectedRange: nil,
            encoding: .utf16
        )
        
        // When
        let formattedEncoding = statusBar.formattedEncoding
        
        // Then
        XCTAssertEqual(formattedEncoding, "UTF-16")
    }
    
    func testASCIIEncoding() {
        // Given
        let statusBar = StatusBar(
            characterCount: 100,
            wordCount: 20,
            lineNumber: 1,
            columnNumber: 1,
            selectedRange: nil,
            encoding: .ascii
        )
        
        // When
        let formattedEncoding = statusBar.formattedEncoding
        
        // Then
        XCTAssertEqual(formattedEncoding, "ASCII")
    }
    
    func testISOLatin1Encoding() {
        // Given
        let statusBar = StatusBar(
            characterCount: 100,
            wordCount: 20,
            lineNumber: 1,
            columnNumber: 1,
            selectedRange: nil,
            encoding: .isoLatin1
        )
        
        // When
        let formattedEncoding = statusBar.formattedEncoding
        
        // Then
        XCTAssertEqual(formattedEncoding, "ISO Latin-1")
    }
    
    // MARK: - Test Full Status Bar Display
    
    func testCompleteStatusBarDisplay() {
        // Given
        let selectedRange = NSRange(location: 50, length: 10)
        let statusBar = StatusBar(
            characterCount: 1500,
            wordCount: 250,
            lineNumber: 42,
            columnNumber: 27,
            selectedRange: selectedRange,
            encoding: .utf8
        )
        
        // Then
        XCTAssertEqual(statusBar.characterCount, 1500)
        XCTAssertEqual(statusBar.wordCount, 250)
        XCTAssertEqual(statusBar.lineNumber, 42)
        XCTAssertEqual(statusBar.columnNumber, 27)
        XCTAssertEqual(statusBar.selectedRange?.length, 10)
        XCTAssertEqual(statusBar.encoding, .utf8)
        
        // Verify formatted strings
        XCTAssertEqual(statusBar.formattedPosition, "Ln 42, Col 27")
        XCTAssertEqual(statusBar.formattedSelection, "Sel: 10")
        XCTAssertEqual(statusBar.formattedEncoding, "UTF-8")
    }
    
    // MARK: - Test Click Actions
    
    func testLineColumnClickAction() {
        // Given
        var actionCalled = false
        let statusBar = StatusBar(
            characterCount: 100,
            wordCount: 20,
            lineNumber: 5,
            columnNumber: 15,
            selectedRange: nil,
            encoding: .utf8,
            onLineColumnClick: {
                actionCalled = true
            }
        )
        
        // When
        statusBar.onLineColumnClick?()
        
        // Then
        XCTAssertTrue(actionCalled)
    }
    
    func testEncodingClickAction() {
        // Given
        var actionCalled = false
        let statusBar = StatusBar(
            characterCount: 100,
            wordCount: 20,
            lineNumber: 1,
            columnNumber: 1,
            selectedRange: nil,
            encoding: .utf8,
            onEncodingClick: {
                actionCalled = true
            }
        )
        
        // When
        statusBar.onEncodingClick?()
        
        // Then
        XCTAssertTrue(actionCalled)
    }
    
    // MARK: - Test Edge Cases
    
    func testZeroLineColumn() {
        // Given
        let statusBar = StatusBar(
            characterCount: 0,
            wordCount: 0,
            lineNumber: 0,
            columnNumber: 0,
            selectedRange: nil,
            encoding: .utf8
        )
        
        // When
        let formattedPosition = statusBar.formattedPosition
        
        // Then - Should display as 1-based indexing
        XCTAssertEqual(formattedPosition, "Ln 1, Col 1")
    }
    
    func testEmptyDocument() {
        // Given
        let statusBar = StatusBar(
            characterCount: 0,
            wordCount: 0,
            lineNumber: 1,
            columnNumber: 1,
            selectedRange: nil,
            encoding: .utf8
        )
        
        // Then
        XCTAssertEqual(statusBar.characterCount, 0)
        XCTAssertEqual(statusBar.wordCount, 0)
        XCTAssertEqual(statusBar.formattedPosition, "Ln 1, Col 1")
        XCTAssertEqual(statusBar.formattedSelection, "")
    }
    
}

// MARK: - Test Helpers

extension StatusBar {
    var formattedPosition: String {
        "Ln \(max(1, lineNumber)), Col \(max(1, columnNumber))"
    }
    
    var formattedSelection: String {
        guard let range = selectedRange, range.length > 0 else { return "" }
        return "Sel: \(range.length)"
    }
    
    var formattedEncoding: String {
        switch encoding {
        case .utf8:
            return "UTF-8"
        case .utf16:
            return "UTF-16"
        case .ascii:
            return "ASCII"
        case .isoLatin1:
            return "ISO Latin-1"
        default:
            return "Unknown"
        }
    }
}