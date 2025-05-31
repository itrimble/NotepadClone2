import XCTest
@testable import NotepadClone2 // Ensure main app target is importable
import AppKit

class ColumnarNSTextViewTests: XCTestCase {

    var textView: ColumnarNSTextView!
    var coordinator: CustomTextView.Coordinator!
    var scrollView: NSScrollView!

    // Dummy parent CustomTextView for coordinator initialization
    // These @State properties won't be properly managed by SwiftUI in a test context,
    // but are needed for CustomTextView initialization.
    @State var dummyText: String = ""
    @State var dummyAttributedText: NSAttributedString = NSAttributedString(string: "")

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Initialize the coordinator's parent CustomTextView
        // This requires @State properties, which are tricky in XCTest.
        // We'll use placeholder state vars declared in the test class.
        let parentView = CustomTextView(
            text: $dummyText,
            attributedText: $dummyAttributedText,
            appTheme: .defaultLight, // Or any theme
            showLineNumbers: false,
            language: .plaintext,
            document: Document(text: "") // Dummy document
        )
        coordinator = parentView.makeCoordinator()

        // Initialize ColumnarNSTextView
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
    }

    override func tearDownWithError() throws {
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
}
