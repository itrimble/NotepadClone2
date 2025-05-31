import XCTest
@testable import NotepadClone2 // Ensure main app target is importable
import AppKit
import Combine // Added import

class ColumnarNSTextViewTests: XCTestCase {

    var textView: ColumnarNSTextView!
    var coordinator: CustomTextView.Coordinator!
    var scrollView: NSScrollView!
    var appState: AppState! // New property
    var cancellables: Set<AnyCancellable> = [] // New property

    // Dummy parent CustomTextView for coordinator initialization
    @State var dummyText: String = ""
    @State var dummyAttributedText: NSAttributedString = NSAttributedString(string: "")

    override func setUpWithError() throws {
        try super.setUpWithError()
        appState = AppState() // Initialize AppState

        // Dummy CustomTextView struct instance to pass to Coordinator
        let dummyParentViewStruct = CustomTextView(
            text: $dummyText,
            attributedText: $dummyAttributedText,
            // appState is provided via @EnvironmentObject in real use,
            // but makeCoordinator directly passes it to Coordinator.
            // So we need to ensure our Coordinator gets it.
            appTheme: .defaultLight,
            showLineNumbers: false,
            language: .plaintext,
            document: Document(text: "")
        )
        // Pass our test appState to the coordinator
        // Note: CustomTextView's makeCoordinator uses its own @EnvironmentObject AppState.
        // For testing the coordinator's interaction with AppState, we must ensure
        // *this* coordinator instance under test has *our* test AppState instance.
        coordinator = CustomTextView.Coordinator(dummyParentViewStruct, appState: self.appState)

        textView = ColumnarNSTextView(frame: NSRect(x: 0, y: 0, width: 500, height: 500))
        textView.columnCoordinator = coordinator
        coordinator.textView = textView // Link back from coordinator

        // Basic NSTextView setup for layout manager to work
        // Ensure there's a layoutManager and a textContainer
        // These are typically set up when the view is part of a scroll view and window.

        // NSTextView automatically creates a layoutManager and a textStorage if they are nil.
        // It also creates a textContainer for its layoutManager if one is not added.
        // We need to ensure the textContainer has a defined size for layout calculations.
        if textView.layoutManager == nil {
            let layoutManager = NSLayoutManager()
            textView.textStorage?.addLayoutManager(layoutManager)
        }

        if textView.textContainer == nil {
            // This path might not be typically hit if layoutManager is present, as LM usually has a TC.
            let textContainer = NSTextContainer(size: NSSize(width: textView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
            textContainer.widthTracksTextView = true
            textView.layoutManager?.addTextContainer(textContainer)
            // NSTextView has a 'textContainer' property, but it's typically managed by its layout manager.
            // Forcing it might be complex. Usually, we configure the existing one.
        }

        // Configure the existing text container
        textView.textContainer?.size = NSSize(width: textView.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true // Ensure it tracks view width
        textView.textContainerInset = .zero // Simplify for tests by removing insets


        scrollView = NSScrollView(frame: textView.bounds)
        scrollView.documentView = textView

        // Adding to a window and performing layout can sometimes be necessary for full initialization.
        // For unit tests, we try to avoid this, but be aware if layout-dependent values are zero.
        // let window = NSWindow()
        // window.contentView = scrollView
        // textView.layoutManager?.ensureLayout(for: textView.textContainer!)

        // Clear pasteboard before each test that might use it
        NSPasteboard.general.clearContents()
    }

    override func tearDownWithError() throws {
        NSPasteboard.general.clearContents()
        cancellables.forEach { $0.cancel() } // Cancel Combine subscriptions
        cancellables.removeAll()
        appState = nil // Nil out appState
        textView = nil
        coordinator = nil
        scrollView = nil
        try super.tearDownWithError()
    }

    private func createEvent(type: NSEvent.EventType, location: NSPoint, modifierFlags: NSEvent.ModifierFlags = []) -> NSEvent {
        // Convert view-relative point to window coordinates for the event.
        // For tests, if the view is not in a window, this conversion might be identity
        // or based on a dummy window. Let's assume location is already window-relative for simplicity
        // if the view's window property is nil.
        // However, ColumnarNSTextView uses `self.convert(event.locationInWindow, from: nil)`
        // so the event should indeed carry window coordinates.
        // If textView.window is nil, event.locationInWindow would be meaningless if not set carefully.
        // For this test, we'll assume location is passed as if it were in window coordinates,
        // and self.convert will handle it (even if it means identity transform if no window/superview).
        return NSEvent.mouseEvent(
            with: type,
            location: location,
            modifierFlags: modifierFlags,
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: type == .leftMouseUp ? 0 : 0.5
        )!
    }

    private func setupTextViewContent(_ content: String, font: NSFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)) {
        let attributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: NSColor.textColor]
        textView.string = ""
        textView.textStorage?.replaceCharacters(in: NSRange(location: 0, length: 0),
                                                with: NSAttributedString(string: content, attributes: attributes))

        // Critical for tests: ensure layout is performed so characterIndexForInsertion and lineFragmentRect work.
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        // If still issues, forcing glyph generation can help:
        // textView.layoutManager?.ensureGlyphs(forCharacterRange: NSRange(location: 0, length: textView.textStorage?.length ?? 0))

        // printLineGeometries() // Uncomment for debugging test geometry
    }

    // func printLineGeometries() {
    //     guard let layoutManager = textView.layoutManager,
    //           let textStorage = textView.textStorage,
    //           let textContainer = textView.textContainer else { return }
    //     print("--- Line Geometries (View Bounds: \(textView.bounds)) ---")
    //     var charIndex = 0
    //     while charIndex < textStorage.length {
    //         var lineGlyphRange = NSRange()
    //         let lineRect = layoutManager.lineFragmentRect(forGlyphAt: layoutManager.glyphIndexForCharacter(at: charIndex), effectiveRange: &lineGlyphRange)
    //         let lineCharRange = layoutManager.characterRange(forGlyphRange: lineGlyphRange, actualGlyphRange: nil)
    //         print("Line (char \(lineCharRange.location)-\(NSMaxRange(lineCharRange)-1)): ContainerRect Y: \(lineRect.origin.y), Height: \(lineRect.height)")

    //         // Test characterIndexForInsertion at start of this line fragment rect (in view coords)
    //         let testPointInView = textView.convert(lineRect.origin, from: nil) // Convert container origin to view
    //         let testCharIdx = textView.characterIndexForInsertion(at: testPointInView)
    //         print("  Test charIndexForInsertion at line fragment origin (\(testPointInView)): \(testCharIdx)")

    //         for i in lineCharRange.location..<NSMaxRange(lineCharRange) {
    //             let glyphIdxForChar = layoutManager.glyphIndexForCharacter(at: i)
    //             let charRect = layoutManager.boundingRect(forGlyphRange: NSMakeRange(glyphIdxForChar, 1), in: textContainer)
    //             print("  Char '\(textStorage.string[textStorage.string.index(textStorage.string.startIndex, offsetBy: i)])' (\(i)): ContainerRect X: \(charRect.origin.x), Width: \(charRect.width)")
    //         }
    //         if NSMaxRange(lineCharRange) >= textStorage.length { break }
    //         charIndex = NSMaxRange(lineCharRange)
    //     }
    //     print("----------------------")
    // }


    func testColumnSelection_SingleLine_FullWidth() {
        let testString = "Hello World"
        setupTextViewContent(testString)

        coordinator.isOptionKeyDown = true

        // Simulate mouse events with points assumed to be in view coordinates for ColumnarNSTextView's methods.
        // The createEvent helper takes window coordinates. If view is not in window, these are effectively view coords.
        let startPointView = NSPoint(x: 1, y: 5) // Near start of text
        // Estimate end point based on typical monospaced font char width (e.g., 7-8px for 12pt font)
        // "Hello World" is 11 chars. 11 * 7 = 77px.
        let endPointXEstimate = CGFloat(testString.count) * 7.0
        let dragPointView = NSPoint(x: endPointXEstimate, y: 5)

        // mouseDown uses convert(event.locationInWindow, from: nil).
        // If view not in window, locationInWindow is tricky.
        // We'll directly set columnSelectionAnchorPoint with view coords for test precision.
        textView.mouseDown(with: createEvent(type: .leftMouseDown, location: startPointView, modifierFlags: .option))
        coordinator.columnSelectionAnchorPoint = startPointView // Override with precise view coords

        textView.mouseDragged(with: createEvent(type: .leftMouseDragged, location: dragPointView, modifierFlags: .option))

        XCTAssertEqual(coordinator.currentColumnSelections.count, 1, "Should be one selection range for a single line.")
        if let selection = coordinator.currentColumnSelections.first {
            XCTAssertTrue(selection.location >= 0, "Selection location should be non-negative.")
            // Expect full line selection from near start to near end
            // This depends on characterIndexForInsertion's behavior with the font.
            // It's safer to check that a substantial part of the line is selected.
            XCTAssertGreaterThan(selection.length, 0, "Selection length should be positive.")
            XCTAssertLessThanOrEqual(selection.location + selection.length, testString.count, "Selection should not exceed string length.")

            // Example of a more specific check IF font metrics were perfectly known and stable in test:
            // let expectedSelectedText = (testString as NSString).substring(with: selection)
            // XCTAssertEqual(expectedSelectedText, testString) // If full line selected
        }

        textView.mouseUp(with: createEvent(type: .leftMouseUp, location: dragPointView, modifierFlags: .option))
        XCTAssertNil(coordinator.columnSelectionAnchorPoint, "Anchor point should be cleared on mouseUp.")
    }

    func testColumnSelection_MultiLine_Carets() {
        let testString = "Line1\nLine2\nLine3"
        setupTextViewContent(testString)
        coordinator.isOptionKeyDown = true

        // Assume each line is approx 15px high. Select a column of carets at X=5.
        // Points are in view coordinates.
        let startPointView = NSPoint(x: 5, y: 5)   // On Line1, near first char
        let dragPointView = NSPoint(x: 5, y: 35)  // Drag down to mid-Line3 (approx 5 + 15 (line1) + 15 (line2) = 35)

        textView.mouseDown(with: createEvent(type: .leftMouseDown, location: startPointView, modifierFlags: .option))
        coordinator.columnSelectionAnchorPoint = startPointView

        textView.mouseDragged(with: createEvent(type: .leftMouseDragged, location: dragPointView, modifierFlags: .option))

        XCTAssertEqual(coordinator.currentColumnSelections.count, 3, "Should be selections on 3 lines.")
        var lineIndex = 0
        let lines = testString.components(separatedBy: "\n")
        var previousLineMaxLocation = -1

        for selection in coordinator.currentColumnSelections {
            XCTAssertEqual(selection.length, 0, "Selections should be zero-length (carets) for line \(lineIndex).")
            // Check that caret is placed at a plausible position (e.g. start of line for x=5)
            let lineStartCharIndex = lines.prefix(lineIndex).map { $0.count + 1 }.reduce(0, +)
            XCTAssertTrue(selection.location >= lineStartCharIndex, "Caret on line \(lineIndex) is before line start.")
            XCTAssertTrue(selection.location <= lineStartCharIndex + lines[lineIndex].count, "Caret on line \(lineIndex) is after line end.")
            XCTAssertGreaterThan(selection.location, previousLineMaxLocation, "Caret locations should be increasing.")
            previousLineMaxLocation = selection.location
            lineIndex += 1
        }

        textView.mouseUp(with: createEvent(type: .leftMouseUp, location: dragPointView, modifierFlags: .option))
        XCTAssertNil(coordinator.columnSelectionAnchorPoint)
    }

    func testColumnSelection_EndsWhenOptionKeyReleased() {
        setupTextViewContent("Some text\nAnother line")
        coordinator.isOptionKeyDown = true

        let startPointView = NSPoint(x: 5, y: 5)
        textView.mouseDown(with: createEvent(type: .leftMouseDown, location: startPointView, modifierFlags: .option))
        coordinator.columnSelectionAnchorPoint = startPointView

        // Perform a column drag first
        let columnDragPointView = NSPoint(x: 10, y: 20) // Drag a small column
        textView.mouseDragged(with: createEvent(type: .leftMouseDragged, location: columnDragPointView, modifierFlags: .option))
        XCTAssertFalse(coordinator.currentColumnSelections.isEmpty, "Column selections should exist after option-drag.")

        // Simulate releasing Option key (via flagsChanged mechanism in ColumnarNSTextView)
        let flagsChangedEventNoOption = createEvent(type: .flagsChanged, location: columnDragPointView, modifierFlags: [])
        textView.flagsChanged(with: flagsChangedEventNoOption) // This should set coordinator.isOptionKeyDown = false
        XCTAssertFalse(coordinator.isOptionKeyDown, "isOptionKeyDown should be false after flagsChanged without option.")

        // Now, a subsequent drag should be a normal drag, not a column drag.
        // The current implementation of mouseDragged calls super.mouseDragged if not in column mode.
        // super.mouseDragged will set a normal selection and should not affect currentColumnSelections.
        // The mouseDown without option key (if another click happened) would clear currentColumnSelections.
        // Let's test if a drag *after* option release continues to modify currentColumnSelections.
        // It should NOT.

        let previousColumnCount = coordinator.currentColumnSelections.count
        let normalDragPointView = NSPoint(x: 50, y: 5) // A normal drag on the first line
        textView.mouseDragged(with: createEvent(type: .leftMouseDragged, location: normalDragPointView, modifierFlags: [])) // No option key

        // If column selection logic was correctly bypassed, currentColumnSelections should remain as they were
        // from the last column drag, or be cleared if normal selection logic clears them.
        // The key is that this normal drag should not *add* or *modify* them according to column logic.
        // Given current mouseDown, if a new non-option click happened, it would clear currentColumnSelections.
        // If it's just a continued drag after option release, currentColumnSelections might persist but not update via column logic.
        // The most important thing is that the column selection *mode* is exited.

        // To be more specific: if a mouseUp occurs, then a new mouseDown without option, then drag:
        textView.mouseUp(with: createEvent(type: .leftMouseUp, location: columnDragPointView, modifierFlags: [])) // End previous drag sequence

        let normalMouseDownPoint = NSPoint(x:1, y:5)
        textView.mouseDown(with: createEvent(type: .leftMouseDown, location: normalMouseDownPoint, modifierFlags: [])) // No option
        XCTAssertTrue(coordinator.currentColumnSelections.isEmpty, "Column selections should be cleared by a normal mouseDown.")

        textView.mouseDragged(with: createEvent(type: .leftMouseDragged, location: normalDragPointView, modifierFlags: []))
        XCTAssertTrue(coordinator.currentColumnSelections.isEmpty, "Column selections should remain empty during a normal drag.")
    }

    // MARK: - Multi-Cursor Input / Deletion Tests

    func testMultiCursorTyping_SingleCharacterAtCarets() {
        let initialText = "abc\ndef\nghi"
        setupTextViewContent(initialText)

        coordinator.currentColumnSelections = [
            NSMakeRange(0, 0), // Before 'a'
            NSMakeRange(4, 0), // Before 'd'
            NSMakeRange(8, 0)  // Before 'g'
        ]

        let handledByDelegate = coordinator.textView(
            textView,
            shouldChangeTextIn: textView.selectedRange(),
            replacementString: "X"
        )

        XCTAssertFalse(handledByDelegate, "Delegate should handle multi-cursor typing and return false.")

        let expectedText = "Xabc\nXdef\nXghi"
        XCTAssertEqual(textView.string, expectedText, "Text not updated correctly after multi-cursor typing.")

        // Original carets: 0, 4, 8. Insert "X" (len 1) at each.
        // New carets, after insertion and sorted:
        // 1st X at 0 -> new caret at 1
        // 2nd X at 4 -> new caret at 4+1=5
        // 3rd X at 8 -> new caret at 8+1=9
        let expectedSelections = [
            NSMakeRange(1, 0),
            NSMakeRange(5, 0),
            NSMakeRange(9, 0)
        ]
        XCTAssertEqual(coordinator.currentColumnSelections, expectedSelections, "Caret positions not updated correctly.")
    }

    func testMultiCursorTyping_OverlappingSelections() {
        let initialText = "SELECT ME\nAND ME TOO" // Line 1: "SELECT ME" (len 9), newline (len 1). Line 2 starts at 10.
        setupTextViewContent(initialText)
        coordinator.currentColumnSelections = [
            NSMakeRange(0, 6), // "SELECT"
            NSMakeRange(10, 3) // "AND"
        ]

        let replacement = "REPLACED"
        let handled = coordinator.textView(textView, shouldChangeTextIn: NSMakeRange(0,0), replacementString: replacement)
        XCTAssertFalse(handled)

        let expectedText = "REPLACED ME\nREPLACED ME TOO"
        XCTAssertEqual(textView.string, expectedText)

        // Implementation iterates currentColumnSelections in reverse order of location.
        // 1. Range (10,3) "AND" is replaced with "REPLACED" (len 8).
        //    Text becomes: "SELECT ME\nREPLACED ME TOO"
        //    New caret for this operation: location 10 + length of "REPLACED" = 10 + 8 = 18.
        // 2. Range (0,6) "SELECT" is replaced with "REPLACED" (len 8).
        //    Text becomes: "REPLACED ME\nREPLACED ME TOO" (original text for this op was "SELECT ME...")
        //    New caret for this operation: location 0 + length of "REPLACED" = 0 + 8 = 8.
        // Final selections are collected and sorted:
        let expectedSelections = [
            NSMakeRange(8, 0),
            NSMakeRange(10 + replacement.utf16.count - 3 + (replacement.utf16.count - 6) , 0) //This calculation is tricky.
                                                                                                // Let's use the simpler calculation based on final text structure.
                                                                                                // First "REPLACED" ends at index 8.
                                                                                                // Text " ME\n" is 4 chars.
                                                                                                // Second "REPLACED" starts after "REPLACED ME\n", so at 8+4=12. Ends at 12+8=20.
        ]
         let expectedSelectionsCorrected = [
            NSMakeRange( (replacement as NSString).length, 0), // Caret after first "REPLACED"
            NSMakeRange( ("REPLACED ME\n" as NSString).length + (replacement as NSString).length, 0) // Caret after second "REPLACED"
        ]
        XCTAssertEqual(coordinator.currentColumnSelections, expectedSelectionsCorrected, "Carets not updated correctly after multi-selection replace.")
    }

    // MARK: - Column Copy/Paste Tests

    func testColumnCopy_SelectedTextAndCarets() {
        let initialText = "L1: Hello\nL2: World\nL3: Test!"
        setupTextViewContent(initialText)

        // L1: "L1: Hello" (idx 0-8) -> "He" is (4,2)
        // L2: "L2: World" (idx 9-17) -> Before 'W' is (13,0)
        // L3: "L3: Test!" (idx 18-26) -> "Test" is (22,4)
        coordinator.currentColumnSelections = [
            NSMakeRange(4, 2),  // "He"
            NSMakeRange(13, 0), // Caret before 'W'
            NSMakeRange(22, 4) // "Test"
        ].sorted(by: { $0.location < $1.location })

        textView.copy(nil)

        let expectedPasteboardContent = "He\n\nTest"
        let actualPasteboardContent = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(actualPasteboardContent, expectedPasteboardContent, "Pasteboard content not as expected for column copy.")
    }

    func testColumnPaste_SingleLineToMultipleCarets() {
        let initialText = "aaa\nbbb\nccc"
        setupTextViewContent(initialText)

        coordinator.currentColumnSelections = [NSMakeRange(0,0), NSMakeRange(4,0), NSMakeRange(8,0)]

        let textToPaste = "XYZ"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(textToPaste, forType: .string)

        textView.paste(nil)

        let expectedText = "XYZaaa\nXYZbbb\nXYZccc"
        XCTAssertEqual(textView.string, expectedText, "Text not updated correctly after pasting single line to multiple carets.")

        let lenXYZ = (textToPaste as NSString).length
        let expectedSelections = [
            NSMakeRange(lenXYZ, 0),
            NSMakeRange(4 + lenXYZ, 0),
            NSMakeRange(8 + lenXYZ, 0)
        ]
        XCTAssertEqual(coordinator.currentColumnSelections, expectedSelections, "Caret positions incorrect after single line paste.")
    }

    func testColumnPaste_MultipleLinesToMultipleCarets_EqualCount() {
        let initialText = "111\n222\n333"
        setupTextViewContent(initialText)
        coordinator.currentColumnSelections = [NSMakeRange(0,0), NSMakeRange(4,0), NSMakeRange(8,0)]

        let textToPaste = "AA\nBB\nCC"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(textToPaste, forType: .string)

        textView.paste(nil)

        let expectedText = "AA111\nBB222\nCC333"
        XCTAssertEqual(textView.string, expectedText)

        let expectedSelections = [NSMakeRange(2,0), NSMakeRange(6,0), NSMakeRange(10,0)]
        XCTAssertEqual(coordinator.currentColumnSelections, expectedSelections)
    }

    func testColumnPaste_FewerLinesThanCarets() {
        let initialText = "111\n222\n333"
        setupTextViewContent(initialText)
        coordinator.currentColumnSelections = [NSMakeRange(0,0), NSMakeRange(4,0), NSMakeRange(8,0)]

        let textToPaste = "AA\nBB"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(textToPaste, forType: .string)

        textView.paste(nil)

        let expectedText = "AA111\nBB222\n333"
        XCTAssertEqual(textView.string, expectedText)

        let expectedSelections = [NSMakeRange(2,0), NSMakeRange(6,0), NSMakeRange(8,0)]
        XCTAssertEqual(coordinator.currentColumnSelections, expectedSelections)
    }

    func testColumnPaste_MoreLinesThanCarets() {
        let initialText = "111\n222"
        setupTextViewContent(initialText)
        coordinator.currentColumnSelections = [NSMakeRange(0,0), NSMakeRange(4,0)]

        let textToPaste = "AA\nBB\nCC\nDD"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(textToPaste, forType: .string)

        textView.paste(nil)

        let expectedText = "AA111\nBB222"
        XCTAssertEqual(textView.string, expectedText)

        let expectedSelections = [NSMakeRange(2,0), NSMakeRange(6,0)]
        XCTAssertEqual(coordinator.currentColumnSelections, expectedSelections)
    }

    func testColumnPaste_ReplacesExistingColumnSelection() {
        let initialText = "abc:value1\ndef:value2\nghi:value3"
        setupTextViewContent(initialText)

        coordinator.currentColumnSelections = [NSMakeRange(4,6), NSMakeRange(14,6), NSMakeRange(24,6)]

        let textToPaste = "NEW1\nNEW2\nNEW3"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(textToPaste, forType: .string)

        textView.paste(nil)

        let expectedText = "abc:NEW1\ndef:NEW2\nghi:NEW3"
        XCTAssertEqual(textView.string, expectedText)

        let expectedSelections = [NSMakeRange(8,0), NSMakeRange(18,0), NSMakeRange(28,0)]
        XCTAssertEqual(coordinator.currentColumnSelections, expectedSelections)
    }

    func testMultiCursorDeleteBackward_FromCaretsAtLineStarts() {
        // Text: "abc\ndef\nghi"
        // Carets: (0,0) before 'a', (4,0) before 'd', (8,0) before 'g'
        // \n is at index 3, 7
        setupTextViewContent("abc\ndef\nghi")
        coordinator.currentColumnSelections = [NSMakeRange(0,0), NSMakeRange(4,0), NSMakeRange(8,0)]

        textView.deleteBackward(nil)

        // Expected behavior:
        // Caret at 8 (before 'g'): deletes newline at 7. Text: "abc\ndefghi". New caret: 7.
        // Caret at 4 (before 'd'): deletes newline at 3. Text: "abcdefghi". New caret: 3.
        // Caret at 0 (before 'a'): no change. New caret: 0.
        // Sorted new carets: [ (0,0), (3,0), (7,0) ] -> No, (3,0) becomes (3,0), (7,0) becomes (7-1=6,0)
        // Let's trace carefully based on reverse iteration:
        // 1. Selection (8,0): Deletes char at 7 ('\n'). Text: "abc\ndefghi". New caret for this op: (7,0).
        // 2. Selection (4,0): Deletes char at 3 ('\n'). Text: "abcdefghi". New caret for this op: (3,0).
        // 3. Selection (0,0): No deletion. New caret for this op: (0,0).
        // Final sorted selections:
        let expectedSelections = [NSMakeRange(0,0), NSMakeRange(3,0), NSMakeRange(3 + "def".count, 0)] // 0, 3, 6
        XCTAssertEqual(textView.string, "abcdefghi")
        XCTAssertEqual(coordinator.currentColumnSelections, expectedSelections)
    }

    func testMultiCursorDeleteBackward_FromCarets_MidLine() {
        setupTextViewContent("abc\ndef\nghi")
        // Carets: after a (idx 1), after d (idx 5), after g (idx 9)
        coordinator.currentColumnSelections = [NSMakeRange(1,0), NSMakeRange(5,0), NSMakeRange(9,0)]

        textView.deleteBackward(nil)

        // Expected: removes 'a', 'd', 'g'
        // 1. Sel (9,0) deletes 'g'. Text: "abc\ndef\nhi". Caret for op: (8,0)
        // 2. Sel (5,0) deletes 'd'. Text: "abc\nef\nhi". Caret for op: (4,0)
        // 3. Sel (1,0) deletes 'a'. Text: "bc\nef\nhi". Caret for op: (0,0)
        // Final sorted carets:
        let expectedSelections = [NSMakeRange(0,0), NSMakeRange(3,0), NSMakeRange(6,0)]
        XCTAssertEqual(textView.string, "bc\nef\nhi")
        XCTAssertEqual(coordinator.currentColumnSelections, expectedSelections)
    }

    func testMultiCursorDeleteBackward_WithSelections() {
        setupTextViewContent("DELETE ME\nAND ME TOO")
        // Selections: "DELETE" (0,6), "AND" (10,3)
        coordinator.currentColumnSelections = [NSMakeRange(0,6), NSMakeRange(10,3)]

        textView.deleteBackward(nil)
        // Expect: " ME\n ME TOO"
        // 1. Sel (10,3) "AND" deleted. Text: "DELETE ME\n ME TOO". Caret for op: (10,0)
        // 2. Sel (0,6) "DELETE" deleted. Text: " ME\n ME TOO". Caret for op: (0,0)
        // Final sorted carets:
        // First caret at 0.
        // Second caret's original location 10 is now shifted by -6 (length of "DELETE"). So, 10-6 = 4.
        let expectedSelections = [NSMakeRange(0,0), NSMakeRange( (" ME\n" as NSString).length ,0)]
        XCTAssertEqual(textView.string, " ME\n ME TOO")
        XCTAssertEqual(coordinator.currentColumnSelections, expectedSelections)
    }

    func testMultiCursorDeleteForward_FromCarets() {
        setupTextViewContent("abc\ndef\nghi")
        // Carets: before a (0,0), before d (4,0), before g (8,0)
        coordinator.currentColumnSelections = [NSMakeRange(0,0), NSMakeRange(4,0), NSMakeRange(8,0)]

        textView.deleteForward(nil)
        // Expected: remove 'a', 'd', 'g'
        // 1. Sel (8,0) deletes 'g'. Text: "abc\ndef\nhi". Caret for op: (8,0)
        // 2. Sel (4,0) deletes 'd'. Text: "abc\nef\nhi". Caret for op: (4,0)
        // 3. Sel (0,0) deletes 'a'. Text: "bc\nef\nhi". Caret for op: (0,0)
        // Final sorted carets (locations remain same as text before them is removed):
        // (0,0), (original 4, now 3 because 'a' is gone), (original 8, now 3+3=6 because 'a' and 'd' are gone)
        let expectedSelections = [NSMakeRange(0,0), NSMakeRange(3,0), NSMakeRange(6,0)]
        XCTAssertEqual(textView.string, "bc\nef\nhi")
        XCTAssertEqual(coordinator.currentColumnSelections, expectedSelections)
    }

    func testMultiCursorDeleteForward_WithSelections() {
        setupTextViewContent("DELETE ME\nAND ME TOO")
        coordinator.currentColumnSelections = [NSMakeRange(0,6), NSMakeRange(10,3)] // "DELETE", "AND"

        textView.deleteForward(nil)
        // Expect: " ME\n ME TOO"
        // 1. Sel (10,3) "AND" deleted. Text: "DELETE ME\n ME TOO". Caret for op: (10,0)
        // 2. Sel (0,6) "DELETE" deleted. Text: " ME\n ME TOO". Caret for op: (0,0)
        // Final sorted carets:
        // First caret at 0.
        // Second caret's original location 10 is now shifted by -6 (length of "DELETE"). So, 10-6 = 4.
        let expectedSelections = [NSMakeRange(0,0), NSMakeRange( (" ME\n" as NSString).length ,0)]
        XCTAssertEqual(textView.string, " ME\n ME TOO")
        XCTAssertEqual(coordinator.currentColumnSelections, expectedSelections)
    }

    // MARK: - AppState Interaction Test

    func testAppStateIsColumnModeActive_UpdatesWithColumnSelections() {
        // Initial state check
        XCTAssertFalse(appState.isColumnModeActive, "Initially, column mode should be inactive in AppState.")

        var cancellables = Set<AnyCancellable>() // Store cancellable for Combine sink

        // Expectation for isColumnModeActive to become true
        let expectationTrue = XCTestExpectation(description: "AppState.isColumnModeActive should become true")

        appState.$isColumnModeActive
            .dropFirst() // Ignore initial value
            .sink { newValue in
                if newValue == true {
                    expectationTrue.fulfill()
                }
            }
            .store(in: &cancellables)

        // Activate column selection by modifying coordinator's property
        coordinator.currentColumnSelections = [NSMakeRange(0, 1)]
        // The didSet on currentColumnSelections in Coordinator updates appState.isColumnModeActive (on main async)

        wait(for: [expectationTrue], timeout: 2.0) // Wait for async update
        XCTAssertTrue(appState.isColumnModeActive, "Column mode should be active in AppState after selections are added.")

        cancellables.removeAll() // Clear previous cancellables

        // Expectation for isColumnModeActive to become false
        let expectationFalse = XCTestExpectation(description: "AppState.isColumnModeActive should become false")

        appState.$isColumnModeActive
            .dropFirst() // Ignore current value (which is true)
            .sink { newValue in
                if newValue == false {
                    expectationFalse.fulfill()
                }
            }
            .store(in: &cancellables)

        // Deactivate column selection
        coordinator.currentColumnSelections = []

        wait(for: [expectationFalse], timeout: 2.0) // Wait for async update
        XCTAssertFalse(appState.isColumnModeActive, "Column mode should be inactive in AppState after selections are cleared.")

        cancellables.removeAll()
    }
}
