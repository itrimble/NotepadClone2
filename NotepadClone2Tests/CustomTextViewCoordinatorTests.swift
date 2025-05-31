import XCTest
@testable import NotepadClone2
import SwiftUI // For CustomTextView, AppTheme, Document etc.
import AppKit  // For NSTextView

// Mock NSTextView for testing coordinator logic without a full UI
class MockTextView: NSTextView {
    var scrollToVisibleRectCalledWith: CGRect?
    var lastScrolledToPoint: NSPoint?
    var lastSelectedRange: NSRange?

    override func scrollToVisible(_ rect: CGRect) {
        scrollToVisibleRectCalledWith = rect
        // super.scrollToVisible(rect) // Call super if needed, or just record
        // For testing, we often don't want actual UI side effects, so recording is enough.
    }

    override func scroll(_ point: NSPoint) {
        lastScrolledToPoint = point
        // super.scroll(point)
    }

    override func setSelectedRange(_ charRange: NSRange) {
        lastSelectedRange = charRange
        // super.setSelectedRange(charRange)
    }

    // Simulate content height
    var simulatedContentHeight: CGFloat = 1000.0

    // We need a valid textStorage for layoutManager operations
    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        self.textStorage?.append(NSAttributedString(string: String(repeating: "line\n", count: 100))) // Populate with some text
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var textContainer: NSTextContainer? {
        let container = super.textContainer ?? NSTextContainer()
        container.size = CGSize(width: 500, height: simulatedContentHeight) // Use simulated height
        // Ensure lineFragmentPadding is zero if calculations depend on it
        container.lineFragmentPadding = 0
        return container
    }

    override var layoutManager: NSLayoutManager? {
        let lm = super.layoutManager ?? NSLayoutManager()
        if let tc = self.textContainer {
            if lm.textContainers.isEmpty {
                 lm.addTextContainer(tc)
            }
            // This is tricky. To make layoutManager.usedRect(for: textContainer).height return simulatedContentHeight,
            // the textStorage, textContainer, and layoutManager need to be set up in a way that results in this.
            // For simplicity, the coordinator's calculation will be tested against this simulated value,
            // assuming that in a real scenario, usedRect would provide the correct total height.
            // One way to influence usedRect is by ensuring the textStorage has enough content.
        }
        return lm
    }

    // Helper to simulate that usedRect(for:) would return a certain height
    func mockUsedRectHeight(_ height: CGFloat) {
        self.simulatedContentHeight = height
        // Adjust text storage to reflect this height if necessary, or ensure layout manager calculations use it.
        // For this mock, we'll rely on the override of textContainer.size.height
        // and assume layoutManager.usedRect(for: textContainer) will reflect this.
        // For a more accurate mock, one might need to subclass NSLayoutManager or use a more complex setup.
        // The test for handleMinimapNavigation will directly use simulatedContentHeight in its assertion
        // to check against the coordinator's expected behavior given such a height.
    }

    // Override visibleRect to provide a mock value
    override var visibleRect: CGRect {
        // Return a plausible visible rect for testing postVisibleRectUpdate
        return CGRect(x: 0, y: 0, width: 500, height: 100)
    }
}

// Mock NSClipView for testing bounds changes
class MockClipView: NSClipView {
    // We can post notifications directly from the test if needed
}


class CustomTextViewCoordinatorTests: XCTestCase {

    var coordinator: CustomTextView.Coordinator!
    var mockTextView: MockTextView!
    var parentCustomTextView: CustomTextView!
    var mockDocument: Document!
    @State var textState: String = "Initial Text"
    @State var attributedTextState: NSAttributedString = NSAttributedString(string: "Initial Text")

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockDocument = Document(text: "Line1\nLine2\nLine3\nLine4\nLine5\nLine6\nLine7\nLine8\nLine9\nLine10")
        mockDocument.id = UUID() // Ensure it has an ID

        // Initialize CustomTextView with bindings
        parentCustomTextView = CustomTextView(
            text: $textState,
            attributedText: $attributedTextState,
            appTheme: .defaultLight, // Or any theme
            showLineNumbers: true,
            language: .swift,
            document: mockDocument
        )
        coordinator = parentCustomTextView.makeCoordinator()

        // Use default initializer for MockTextView
        mockTextView = MockTextView(frame: .zero, textContainer: nil)
        mockTextView.mockUsedRectHeight(2000) // Simulate a total content height of 2000px
        coordinator.textView = mockTextView // Assign the mock text view to the coordinator
    }

    override func tearDownWithError() throws {
        coordinator = nil
        mockTextView = nil
        parentCustomTextView = nil
        mockDocument = nil
        // Remove observers if coordinator doesn't do it in deinit or if coordinator could be nil
        NotificationCenter.default.removeObserver(self) // General cleanup for any observers added by tests
        try super.tearDownWithError()
    }

    func testHandleMinimapNavigation_ScrollsTextView() {
        let clickYRatio: CGFloat = 0.5 // Click in the middle
        let expectedTotalContentHeight = mockTextView.simulatedContentHeight // The height coordinator should use

        // Post the notification that the coordinator listens to
        NotificationCenter.default.post(name: .minimapNavigateToRatio, object: clickYRatio)

        // Give a tiny moment for notification to be processed (though it should be synchronous for direct calls)
        // Using expectation for a more robust async wait if any part of handling becomes async.
        let expectation = self.expectation(description: "Minimap navigation processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // Increased delay slightly
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.2)


        // Check if scrollToVisible was called on the mockTextView
        XCTAssertNotNil(mockTextView.scrollToVisibleRectCalledWith, "scrollToVisible should have been called.")

        if let targetRect = mockTextView.scrollToVisibleRectCalledWith {
            // Expected Y = totalContentHeight * ratio
            // Ensure this matches the logic in `handleMinimapNavigation` for `clampedTargetY`
            let expectedY = expectedTotalContentHeight * clickYRatio
            // The coordinator clamps targetY: min(targetY, max(0, totalContentHeight - textView.visibleRect.height > 0 ? totalContentHeight - textView.visibleRect.height : 1))
            // Given visibleRect.height = 100 (from mock), expectedTotalContentHeight = 2000
            // max(0, 2000 - 100) = 1900
            // So, targetY (1000) should be clamped to min(1000, 1900) which is 1000.
            let clampedExpectedY = min(expectedY, max(0, expectedTotalContentHeight - mockTextView.visibleRect.height > 0 ? expectedTotalContentHeight - mockTextView.visibleRect.height : 1))

            XCTAssertEqual(targetRect.origin.y, clampedExpectedY, accuracy: 1.0, "TextView not scrolled to the correct Y position. Expected \(clampedExpectedY), got \(targetRect.origin.y)")
        }
    }

    func testBoundsChange_PostsCustomTextViewDidScrollNotification() {
        // Simulate a bounds change scenario
        let expectation = XCTNSNotificationExpectation(name: .customTextViewDidScroll)
        expectation.handler = { notification -> Bool in
            guard let userInfo = notification.userInfo,
                  let rect = userInfo["visibleRect"] as? CGRect,
                  let docId = userInfo["documentId"] as? UUID else {
                XCTFail("Notification userInfo is not as expected.")
                return false
            }
            // Compare with the visibleRect from our MockTextView
            XCTAssertEqual(rect, self.mockTextView.visibleRect, "Visible rect in notification does not match mock's visibleRect.")
            XCTAssertEqual(docId, self.mockDocument.id, "Document ID in notification does not match.")
            return true
        }

        // Directly call the method that would be triggered by NSView.boundsDidChangeNotification
        coordinator.postVisibleRectUpdate(for: mockTextView)

        wait(for: [expectation], timeout: 1.0)
    }
}
