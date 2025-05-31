import SwiftUI
import AppKit

struct CustomTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var attributedText: NSAttributedString
    @Environment(\.colorScheme) var colorScheme
    let appTheme: AppTheme
    let showLineNumbers: Bool
    let language: SyntaxHighlighter.Language
    let document: Document  // Pass the document directly
    
    func makeNSView(context: Context) -> NSScrollView {
        print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - Creating text view")
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - ScrollView: \(scrollView), TextView: \(textView)")
        
        // Configure scroll view
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder
        
        // Configure text view for proper text handling
        textView.isRichText = true
        textView.usesFontPanel = false  // Disable font panel to prevent color picker
        print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - Initial configuration: usesFontPanel = \(textView.usesFontPanel)")
        textView.allowsUndo = true
        textView.delegate = context.coordinator  // Set delegate after other properties
        print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - Delegate set: \(textView.delegate != nil)")
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = NSSize(width: 10, height: 10)
        
        // CRITICAL: Make text view editable and visible
        textView.isEditable = true
        textView.isSelectable = true
        print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - Initial configuration: isEditable = \(textView.isEditable), isSelectable = \(textView.isSelectable)")
        textView.importsGraphics = false
        print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - Initial configuration: importsGraphics = \(textView.importsGraphics)")
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        
        // Ensure proper cursor and interaction
        textView.insertionPointColor = appTheme.editorTextColor()
        textView.isFieldEditor = false
        textView.usesInspectorBar = false
        textView.drawsBackground = true
        textView.backgroundColor = appTheme.editorBackgroundColor()
        
        // Enable ruler view for line numbers if enabled
        if showLineNumbers {
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
            
            // Create and configure line number ruler with folding support
            let lineNumberView = CodeFoldingRulerView(scrollView: scrollView, orientation: .verticalRuler)
            lineNumberView.clientView = textView
            lineNumberView.ruleThickness = 60.0  // Wider to accommodate fold controls
            lineNumberView.backgroundColor = NSColor(appTheme.tabBarBackgroundColor())
            lineNumberView.textColor = appTheme.editorTextColor() // Make base color more solid
            lineNumberView.language = language
            lineNumberView.coordinator = context.coordinator
            scrollView.verticalRulerView = lineNumberView

            // Add color clash logging for line number ruler
            if lineNumberView.textColor.isApproximatelyEqual(to: lineNumberView.backgroundColor) {
                print("TYPING_DEBUG: WARNING LineNumberView.makeNSView - Line number text color and background color are very similar. Line numbers may be invisible. Text Color: \(lineNumberView.textColor), Background Color: \(lineNumberView.backgroundColor)")
            }
        } else {
            scrollView.hasVerticalRuler = false
            scrollView.rulersVisible = false
        }
        
        // Set up initial theme
        context.coordinator.updateTheme(textView)
        context.coordinator.textView = textView // Store textView instance

        // Setup bounds observer for scrolling
        if let clipView = scrollView.contentView as? NSClipView {
            context.coordinator.setupBoundsObserver(for: clipView)
        }
        
        // Set initial text with proper attributes
        let defaultAttributes = context.coordinator.defaultAttributes()
        
        // Clear approach: set the text directly with attributes
        textView.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: defaultAttributes))
        
        // Ensure text container is properly configured
        if let textContainer = textView.textContainer {
            textContainer.widthTracksTextView = true
            textContainer.containerSize = CGSize(width: max(100, scrollView.frame.width), height: CGFloat.greatestFiniteMagnitude)
        }
        
        // Force initial layout
        textView.needsLayout = true
        scrollView.needsLayout = true
        
        // Set typing attributes for new text
        textView.typingAttributes = defaultAttributes
        print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - Default typing attributes: \(defaultAttributes)") // Corrected typo makeNSVew -> makeNSView
        
        // Make text view the first responder when window is ready.
        // This is deferred to ensure the window and view hierarchy are fully set up.
        DispatchQueue.main.async {
            if let window = textView.window {
                print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - Attempting to make first responder. Window: \(window), isKey: \(window.isKeyWindow), isVisible: \(window.isVisible)")
                print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - Current first responder before attempt: \(String(describing: window.firstResponder))")
                let success = window.makeFirstResponder(textView)
                print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - First responder attempt outcome: \(success ? "SUCCESS" : "FAILURE")")
                print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - Current first responder after attempt: \(String(describing: window.firstResponder))")
            } else {
                print("TYPING_DEBUG: ❌ CustomTextView.makeNSView - No window available for first responder")
            }
        }
        
        print("TYPING_DEBUG: ✅ CustomTextView.makeNSView - Complete, returning scrollView")
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        print("TYPING_DEBUG: 🔄 CustomTextView.updateNSView - Called, textView: \(textView)")
        
        // Always update theme when view updates
        context.coordinator.updateTheme(textView)
        
        // Update line numbers visibility
        if showLineNumbers {
            nsView.hasVerticalRuler = true
            nsView.rulersVisible = true
            if let codeRulerView = nsView.verticalRulerView as? CodeFoldingRulerView {
                codeRulerView.backgroundColor = NSColor(appTheme.tabBarBackgroundColor())
                codeRulerView.textColor = appTheme.editorTextColor() // Make base color more solid
                
                // Add color clash logging for line number ruler
                if codeRulerView.textColor.isApproximatelyEqual(to: codeRulerView.backgroundColor) {
                    print("TYPING_DEBUG: WARNING LineNumberView.updateNSView - Line number text color and background color are very similar. Line numbers may be invisible. Text Color: \(codeRulerView.textColor), Background Color: \(codeRulerView.backgroundColor)")
                }

                codeRulerView.language = language // This was already here
                codeRulerView.needsDisplay = true    // This was already here
            }
        } else {
            nsView.hasVerticalRuler = false
            nsView.rulersVisible = false
        }
        
        // Update text if it has changed
        if let textStorage = textView.textStorage {
            let currentText = textStorage.string
            let newText = attributedText.string
            
            // Check if we need to update
            if currentText != newText || textStorage.length != attributedText.length {
                print("TYPING_DEBUG: 🔄 CustomTextView.updateNSView - Text content is being updated. currentText.count: \(currentText.count), newText.count: \(newText.count), textStorage.length: \(textStorage.length), attributedText.length: \(attributedText.length)")
                // Store the current selection
                let selectedRange = textView.selectedRange()
                
                // Update text storage
                textStorage.beginEditing()
                
                // If attributed text is empty but we have plain text, create attributed version
                if attributedText.length == 0 && !text.isEmpty {
                    let attrs = context.coordinator.defaultAttributes()
                    let attrString = NSAttributedString(string: text, attributes: attrs)
                    textStorage.setAttributedString(attrString)
                } else {
                    textStorage.setAttributedString(attributedText)
                }
                
                textStorage.endEditing()
                
                // Restore selection safely
                let maxLength = textStorage.length
                if selectedRange.location >= 0 && selectedRange.location <= maxLength {
                    let validLength = min(selectedRange.length, maxLength - selectedRange.location)
                    let safeRange = NSRange(location: selectedRange.location, length: max(0, validLength))
                    textView.setSelectedRange(safeRange)
                }
            }
        }
        
        // Ensure text view remains editable
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        
        // Update cursor color for visibility
        textView.insertionPointColor = appTheme.editorTextColor()
        
        // CRITICAL FIX: Safe responder management - Removed redundant makeFirstResponder call from updateNSView.
        // The initial makeFirstResponder in makeNSView (async) should be the primary mechanism.
        // If focus is lost later, it's often due to other UI interactions or window lifecycle events
        // that should ideally be handled by the system or specific event handlers, not generically in updateNSView.
    }
    
    static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
        print("TYPING_DEBUG: 🗑️ CustomTextView.dismantleNSView - Called")
        // CRITICAL FIX: Simplify responder handling
        coordinator.isBeingRemoved = true
        
        // Clean up delegate
        if let textView = nsView.documentView as? NSTextView {
            textView.delegate = nil
            
            // Remove bounds observer
            if let scrollView = textView.enclosingScrollView, let clipView = scrollView.contentView as? NSClipView {
                NotificationCenter.default.removeObserver(coordinator, name: NSView.boundsDidChangeNotification, object: clipView)
            }

            // Let AppKit handle responder transitions naturally
            // DO NOT call resignFirstResponder() directly
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CustomTextView
        weak var textView: NSTextView? // Added property to store textView
        private var isUpdating = false
        private var lastText = ""
        var isBeingRemoved = false // Track if view is being dismantled
        @Published var selectedRange: NSRange = NSRange(location: 0, length: 0)
        var foldableRegions: [FoldableRegion] = []
        
        init(_ parent: CustomTextView) {
            self.parent = parent
            super.init()
            print("TYPING_DEBUG: 🔧 Coordinator.init - Created coordinator")
            
            // Observe jump to line notifications
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleJumpToLine(_:)),
                name: .jumpToLine,
                object: nil
            )

            // Observe minimap navigation clicks
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleMinimapNavigation(_:)),
                name: .minimapNavigateToRatio,
                object: nil
            )
        }
        
        deinit {
            print("TYPING_DEBUG: 🗑️ Coordinator.deinit - Coordinator is being deallocated")
            NotificationCenter.default.removeObserver(self)
        }
        
        func defaultAttributes() -> [NSAttributedString.Key: Any] {
            let theme = parent.appTheme
            return [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: theme.editorTextColor()
            ]
        }
        
        func updateTheme(_ textView: NSTextView) {
            let theme = parent.appTheme
            let foreground = theme.editorTextColor()
            let background = theme.editorBackgroundColor()
            print("TYPING_DEBUG: 🎨 Coordinator.updateTheme - Applying foreground: \(foreground), background: \(background)")

            // Explicitly check if text and background colors are too similar
            if foreground.isApproximatelyEqual(to: background) {
                print("TYPING_DEBUG: WARNING Coordinator.updateTheme - Text color and background color are very similar or identical. Text may be invisible. Foreground: \(foreground), Background: \(background)")
            }
            
            // Update background color
            textView.backgroundColor = background
            
            // Update typing attributes
            var attrs = textView.typingAttributes
            attrs[.foregroundColor] = foreground
            // attrs[.backgroundColor] = background // Removed: Let textView.backgroundColor handle background
            attrs[.font] = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular) // Consistent monospaced font
            textView.typingAttributes = attrs
            
            // Update existing text colors if needed
            if let textStorage = textView.textStorage {
                let range = NSRange(location: 0, length: textStorage.length)
                textStorage.addAttribute(.foregroundColor, value: theme.editorTextColor(), range: range)
                // Also ensure font is set
                if textStorage.length > 0 && textStorage.attribute(.font, at: 0, effectiveRange: nil) == nil {
                    textStorage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular), range: range) // Consistent monospaced font
                }
            }
        }
        
        func textDidChange(_ notification: Notification) {
            print("TYPING_DEBUG: ✏️ Coordinator.textDidChange - Called. isUpdating: \(isUpdating)")
            guard let textView = notification.object as? NSTextView else {
                print("TYPING_DEBUG: ❌ Coordinator.textDidChange - Not a valid NSTextView")
                return
            }
            guard !isUpdating else {
                print("TYPING_DEBUG: ⚠️ Coordinator.textDidChange - Blocked: isUpdating = true")
                return
            }
            guard !isBeingRemoved else {
                print("TYPING_DEBUG: ⚠️ Coordinator.textDidChange - Blocked: isBeingRemoved = true")
                return
            }
            print("TYPING_DEBUG: ✏️ Coordinator.textDidChange - Current text from NSTextView: \(textView.string.prefix(50))...")
            
            let currentText = textView.string
            
            // Only update if text actually changed
            if currentText != lastText {
                lastText = currentText
                
                // Set flag to prevent circular updates
                isUpdating = true
                defer { 
                    isUpdating = false
                    print("TYPING_DEBUG: ✏️ Coordinator.textDidChange - Reset isUpdating to false")
                }
                print("TYPING_DEBUG: ✏️ Coordinator.textDidChange - Set isUpdating to true")
                
                do {
                    // Update foldable regions
                    updateFoldableRegions(for: currentText)
                    
                    // Update line numbers and ruler view
                    if let scrollView = textView.enclosingScrollView,
                       let rulerView = scrollView.verticalRulerView {
                        rulerView.needsDisplay = true
                    }
                    
                    // Update text binding synchronously to avoid state modification during view updates
                    if parent.text != currentText {
                        parent.text = currentText
                        print("TYPING_DEBUG: ✏️ Coordinator.textDidChange - Updated parent.text")
                    } else {
                        print("TYPING_DEBUG: ✏️ Coordinator.textDidChange - parent.text was already up-to-date")
                    }
                    
                    // Update attributed text synchronously
                    if let textStorage = textView.textStorage {
                        let attributedString = textStorage.copy() as! NSAttributedString
                        if !attributedString.isEqual(to: parent.attributedText) {
                            parent.attributedText = attributedString
                            print("TYPING_DEBUG: ✏️ Coordinator.textDidChange - Updated parent.attributedText")
                        } else {
                            print("TYPING_DEBUG: ✏️ Coordinator.textDidChange - parent.attributedText was already up-to-date")
                        }
                    }
                    
                    // Update bracket highlighting after a short delay to allow syntax highlighting to complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                        self?.updateBracketHighlighting(in: textView)
                    }
                } catch {
                    print("TYPING_DEBUG: ERROR Coordinator.textDidChange - Error during text processing: \(error)")
                }
            }
        }
        
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            let replacement = replacementString ?? "nil"
            print("TYPING_DEBUG: 🎹 Coordinator.shouldChangeTextIn - Range: \(affectedCharRange), Replacement: '\(replacement)', Length: \(replacement.count)")
            
            // Log current state
            print("TYPING_DEBUG:    📊 Coordinator.shouldChangeTextIn - Current state: isUpdating = \(isUpdating), isBeingRemoved = \(isBeingRemoved)")
            print("TYPING_DEBUG:    📊 Coordinator.shouldChangeTextIn - TextView state: isEditable = \(textView.isEditable), window = \(textView.window != nil)")
            if let window = textView.window {
                print("TYPING_DEBUG:    📊 Coordinator.shouldChangeTextIn - Window: isKey = \(window.isKeyWindow), isVisible = \(window.isVisible), firstResponder = \(String(describing: window.firstResponder))")
            }
            print("TYPING_DEBUG:    📊 Coordinator.shouldChangeTextIn - Is TextView first responder: \(textView.window?.firstResponder == textView)")
            
            // Prevent changes during updates or when being removed
            guard !isUpdating && !isBeingRemoved else {
                print("TYPING_DEBUG:    ❌ Coordinator.shouldChangeTextIn - BLOCKED: isUpdating=\(isUpdating), isBeingRemoved=\(isBeingRemoved). Returning false.")
                return false
            }
            
            // Handle smart indentation for newlines
            if let replacement = replacementString, replacement == "\n" {
                // Use smart indenter to handle newline with proper indentation
                let handled = SmartIndenter.handleNewlineIndentation(
                    in: textView,
                    language: parent.language
                )
                
                if handled {
                    return false // We handled the insertion ourselves
                }
            }
            
            print("TYPING_DEBUG:    ✅ Coordinator.shouldChangeTextIn - ALLOWING text change. Returning true.")
            return true
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView,
                  !isUpdating else { return }
            
            let newRange = textView.selectedRange()
            
            // Only post if selection actually changed
            if selectedRange != newRange {
                selectedRange = newRange
                
                // Update bracket highlighting
                updateBracketHighlighting(in: textView)
                
                // Debounce selection notifications to avoid excessive updates
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(postSelectionChange), object: nil)
                perform(#selector(postSelectionChange), with: nil, afterDelay: 0.1)
            }
        }
        
        @objc private func postSelectionChange() {
            NotificationCenter.default.post(
                name: .textViewSelectionDidChange,
                object: nil,
                userInfo: ["selectedRange": selectedRange]
            )
        }
        
        @objc private func handleJumpToLine(_ notification: Notification) {
            print("TYPING_DEBUG:  JUMP_TO_LINE Coordinator.handleJumpToLine - Received notification: \(notification)")
            guard let lineNumber = notification.userInfo?["lineNumber"] as? Int,
                  let textView = NSApp.keyWindow?.firstResponder as? NSTextView else {
                print("TYPING_DEBUG: JUMP_TO_LINE Coordinator.handleJumpToLine - Guard failed. LineNumber: \(String(describing: notification.userInfo?["lineNumber"])), TextView: \(String(describing: NSApp.keyWindow?.firstResponder))")
                return
            }
            
            // Check if this coordinator's parent view is the one that should handle this.
            // This is a simple check; more robust might involve passing a document ID.
            guard parent.document.id == (textView.delegate as? Coordinator)?.parent.document.id else {
                print("TYPING_DEBUG: JUMP_TO_LINE Coordinator.handleJumpToLine - Notification is for a different document. Skipping.")
                return
            }
            
            print("TYPING_DEBUG: JUMP_TO_LINE Coordinator.handleJumpToLine - Attempting to jump to line: \(lineNumber) in textView: \(textView)")
            
            let text = textView.string
            let lines = text.components(separatedBy: .newlines)
            
            guard lineNumber > 0 && lineNumber <= lines.count else {
                print("TYPING_DEBUG: JUMP_TO_LINE Coordinator.handleJumpToLine - Invalid line number: \(lineNumber). Total lines: \(lines.count)")
                return
            }
            
            // Calculate character position for the line
            let lineIndex = lineNumber - 1
            var charPosition = 0
            
            for i in 0..<lineIndex {
                charPosition += lines[i].count + 1 // +1 for newline
            }
            
            // Create range for the line
            let lineLength = lines[lineIndex].count
            let lineRange = NSRange(location: charPosition, length: lineLength)
            print("TYPING_DEBUG: JUMP_TO_LINE Coordinator.handleJumpToLine - Calculated charPosition: \(charPosition), lineLength: \(lineLength), lineRange: \(lineRange)")
            
            // Scroll to and select the line
            textView.scrollRangeToVisible(lineRange)
            textView.setSelectedRange(lineRange)
            print("TYPING_DEBUG: JUMP_TO_LINE Coordinator.handleJumpToLine - Scrolled and set selection to range: \(lineRange)")
            
            // Make sure text view is first responder
            let responderSuccess = textView.window?.makeFirstResponder(textView)
            print("TYPING_DEBUG: JUMP_TO_LINE Coordinator.handleJumpToLine - Made textView first responder. Success: \(responderSuccess ?? false)")
        }
        
        // MARK: - Code Folding Methods
        
        func updateFoldableRegions(for text: String) {
            let folder = CodeFolder(language: parent.language)
            foldableRegions = folder.detectFoldableRegions(in: text)
        }
        
        private func getCurrentDocument() -> Document? {
            // Try to get the current document from AppState
            if let _ = NSApp.delegate as? AppDelegate,
               let mainWindow = NSApp.mainWindow,
               let contentView = mainWindow.contentView,
               let _ = contentView.subviews.first(where: { $0 is NSHostingView<AnyView> }) as? NSHostingView<AnyView> {
                // This is a simplified approach - in practice, you might need a different way to access AppState
                // For now, we'll work with the text binding directly
                return nil
            }
            return nil
        }
        
        func toggleFold(for region: FoldableRegion) {
            parent.document.toggleFold(for: region)
            
            // Update the ruler view
            if let textView = NSApp.keyWindow?.firstResponder as? NSTextView,
               let scrollView = textView.enclosingScrollView,
               let rulerView = scrollView.verticalRulerView as? CodeFoldingRulerView {
                rulerView.needsDisplay = true
            }
        }
        
        func isFolded(_ region: FoldableRegion) -> Bool {
            return parent.document.isFolded(region)
        }
        
        // MARK: - Bracket Matching
        
        private func updateBracketHighlighting(in textView: NSTextView) {
            // Get the current theme for bracket highlighting
            let syntaxTheme = parent.appTheme.syntaxTheme()
            
            // Apply bracket highlighting
            BracketMatcher.highlightBrackets(in: textView, theme: syntaxTheme)
        }

        // MARK: - Scroll Handling and Minimap Navigation

        func setupBoundsObserver(for clipView: NSClipView) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleBoundsChange(_:)),
                name: NSView.boundsDidChangeNotification,
                object: clipView // Observe the specific clipView
            )
        }

        @objc func handleBoundsChange(_ notification: Notification) {
            guard let clipView = notification.object as? NSClipView,
                  let textView = clipView.documentView as? NSTextView else {
                return
            }
            // Ensure it's for the correct text view instance this coordinator manages
            guard textView === self.textView else { return }

            postVisibleRectUpdate(for: textView)
        }

        @objc func handleMinimapNavigation(_ notification: Notification) {
            guard let clickYRatio = notification.object as? CGFloat,
                  let textView = self.textView,
                  let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else {
                print("TYPING_DEBUG: MINIMAP_NAV - Guard failed. clickYRatio: \(String(describing: notification.object)), textView: \(String(describing: self.textView))")
                return
            }

            // Document ID check: Ensure this navigation is for the document this coordinator is managing.
            // This check is important if notifications are not instance-specific.
            // Here, we assume that if this coordinator's textView is active, it's the target.
            // A more robust way would be to pass document ID in the notification and check it here.
            // For now, direct handling is okay as CustomTextView instances are distinct.

            let totalContentHeight = layoutManager.usedRect(for: textContainer).height
            guard totalContentHeight > 0 else {
                print("TYPING_DEBUG: MINIMAP_NAV - Total content height is 0.")
                return
            }

            let targetY = totalContentHeight * clickYRatio
            // Ensure targetY is within bounds [0, totalContentHeight - visibleRect.height (or 1 if too small)]
            // For simplicity, we scroll to a point, ensuring it's not beyond the very end.
            let clampedTargetY = min(targetY, max(0, totalContentHeight - textView.visibleRect.height > 0 ? totalContentHeight - textView.visibleRect.height : 1))
            let targetRect = CGRect(x: 0, y: clampedTargetY, width: 1, height: 1)

            print("TYPING_DEBUG: MINIMAP_NAV - Navigating to ratio: \(clickYRatio), targetY: \(targetY), clampedTargetY: \(clampedTargetY), totalHeight: \(totalContentHeight)")
            textView.scrollToVisible(targetRect)

            // Manually trigger visible rect update after scrolling, as bounds change might be async
            DispatchQueue.main.async {
                 self.postVisibleRectUpdate(for: textView)
            }
        }

        func postVisibleRectUpdate(for textView: NSTextView) {
            let visibleRect = textView.visibleRect
            // Ensure document ID is available and correct
            // parent.document.id should be accessible here
            NotificationCenter.default.post(
                name: .customTextViewDidScroll,
                object: nil, // Or pass `textView` if specific sender is needed by observers
                userInfo: ["visibleRect": visibleRect, "documentId": parent.document.id]
            )
            print("TYPING_DEBUG: SCROLL_UPDATE - Posted .customTextViewDidScroll with rect: \(visibleRect), docID: \(parent.document.id)")
        }
    }
}

// Preview for Xcode development
#Preview {
    struct PreviewWrapper: View {
        @State private var text = "Sample text for preview"
        @State private var attributedText = NSAttributedString(string: "Sample text for preview", attributes: [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.labelColor
        ])
        
        var body: some View {
            let document = Document()
            document.language = .swift
            return CustomTextView(
                text: $text, 
                attributedText: $attributedText, 
                appTheme: .system, 
                showLineNumbers: true, 
                language: .swift,
                document: document
            )
            .frame(width: 400, height: 300)
        }
    }
    
    return PreviewWrapper()
}

// Code Folding Ruler View for displaying line numbers and fold controls
class CodeFoldingRulerView: NSRulerView {
    var font: NSFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
    var textColor: NSColor = NSColor.secondaryLabelColor
    var backgroundColor: NSColor = NSColor.controlBackgroundColor
    var language: SyntaxHighlighter.Language = .none
    weak var coordinator: CustomTextView.Coordinator?
    
    override init(scrollView: NSScrollView?, orientation: NSRulerView.Orientation) {
        super.init(scrollView: scrollView, orientation: orientation)
        self.clientView = scrollView?.documentView
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        // Fill background
        backgroundColor.set()
        rect.fill()
        
        guard let textView = self.clientView as? NSTextView,
              let textContainer = textView.textContainer,
              let layoutManager = textView.layoutManager,
              let coordinator = coordinator else { return }
        
        let contentRect = convert(textView.visibleRect, from: textView)
        let textVisibleRect = textView.visibleRect
        
        // Find the character range for the visible text
        let glyphRange = layoutManager.glyphRange(forBoundingRect: textVisibleRect, in: textContainer)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        
        // Get the text
        let text = textView.string as NSString
        
        // Set up line number attributes
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        // Calculate line numbers
        var lineNumber = 0
        
        // Count lines before visible range
        text.enumerateSubstrings(in: NSRange(location: 0, length: characterRange.location),
                                options: [.byLines, .substringNotRequired]) { _, _, _, _ in
            lineNumber += 1
        }
        
        // Create a dictionary to quickly lookup foldable regions by start line
        var regionsByStartLine: [Int: FoldableRegion] = [:]
        for region in coordinator.foldableRegions {
            regionsByStartLine[region.startLine] = region
        }
        
        // Draw line numbers and fold controls for visible range
        text.enumerateSubstrings(in: characterRange,
                                options: [.byLines, .substringNotRequired]) { _, lineRange, _, _ in
            lineNumber += 1
            
            // Get the line rect
            let lineGlyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: lineGlyphRange.location, effectiveRange: nil)
            
            // Calculate y position
            let y = lineRect.minY - textVisibleRect.minY + contentRect.minY
            
            // Draw line number
            let lineNumberString = "\(lineNumber)"
            let size = lineNumberString.size(withAttributes: attributes)
            let lineNumberPoint = NSPoint(x: self.ruleThickness - size.width - 5, y: y)
            
            lineNumberString.draw(at: lineNumberPoint, withAttributes: attributes)
            
            // Draw fold control if this line starts a foldable region
            if let region = regionsByStartLine[lineNumber] {
                self.drawFoldControl(for: region, at: NSPoint(x: 5, y: y), coordinator: coordinator)
            }
        }
    }
    
    private func drawFoldControl(for region: FoldableRegion, at point: NSPoint, coordinator: CustomTextView.Coordinator) {
        let isFolded = coordinator.isFolded(region)
        let controlSize: CGFloat = 12
        let controlRect = NSRect(x: point.x, y: point.y + 2, width: controlSize, height: controlSize)
        
        // Draw background
        NSColor.controlBackgroundColor.set()
        controlRect.fill()
        
        // Draw border
        textColor.withAlphaComponent(0.3).set()
        controlRect.frame()
        
        // Draw plus or minus sign
        let signColor = textColor.withAlphaComponent(0.7)
        let lineWidth: CGFloat = 1.5
        
        // Horizontal line (always present for minus sign, or part of plus)
        let horizontalPath = NSBezierPath()
        horizontalPath.lineWidth = lineWidth
        let centerY = controlRect.midY
        let leftX = controlRect.minX + 3
        let rightX = controlRect.maxX - 3
        
        horizontalPath.move(to: NSPoint(x: leftX, y: centerY))
        horizontalPath.line(to: NSPoint(x: rightX, y: centerY))
        signColor.set()
        horizontalPath.stroke()
        
        // Vertical line (only for folded regions - plus sign)
        if isFolded {
            let verticalPath = NSBezierPath()
            verticalPath.lineWidth = lineWidth
            let centerX = controlRect.midX
            let topY = controlRect.maxY - 3
            let bottomY = controlRect.minY + 3
            
            verticalPath.move(to: NSPoint(x: centerX, y: bottomY))
            verticalPath.line(to: NSPoint(x: centerX, y: topY))
            verticalPath.stroke()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        
        guard let coordinator = coordinator else {
            super.mouseDown(with: event)
            return
        }
        
        // Check if click is on a fold control
        if let region = foldableRegionAt(point: point) {
            coordinator.toggleFold(for: region)
            needsDisplay = true
        } else {
            super.mouseDown(with: event)
        }
    }
    
    private func foldableRegionAt(point: NSPoint) -> FoldableRegion? {
        guard let textView = self.clientView as? NSTextView,
              let textContainer = textView.textContainer,
              let layoutManager = textView.layoutManager,
              let coordinator = coordinator else { return nil }
        
        let contentRect = convert(textView.visibleRect, from: textView)
        let textVisibleRect = textView.visibleRect
        
        // Find the character range for the visible text
        let glyphRange = layoutManager.glyphRange(forBoundingRect: textVisibleRect, in: textContainer)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        
        // Get the text
        let text = textView.string as NSString
        
        // Calculate line numbers
        var lineNumber = 0
        
        // Count lines before visible range
        text.enumerateSubstrings(in: NSRange(location: 0, length: characterRange.location),
                                options: [.byLines, .substringNotRequired]) { _, _, _, _ in
            lineNumber += 1
        }
        
        // Create a dictionary to quickly lookup foldable regions by start line
        var regionsByStartLine: [Int: FoldableRegion] = [:]
        for region in coordinator.foldableRegions {
            regionsByStartLine[region.startLine] = region
        }
        
        // Check each visible line to see if click is on a fold control
        var foundRegion: FoldableRegion?
        text.enumerateSubstrings(in: characterRange,
                                options: [.byLines, .substringNotRequired]) { _, lineRange, _, stop in
            lineNumber += 1
            
            // Get the line rect
            let lineGlyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: lineGlyphRange.location, effectiveRange: nil)
            
            // Calculate y position
            let y = lineRect.minY - textVisibleRect.minY + contentRect.minY
            
            // Check if this line has a foldable region and if click is within the control area
            if let region = regionsByStartLine[lineNumber] {
                let controlSize: CGFloat = 12
                let controlRect = NSRect(x: 5, y: y + 2, width: controlSize, height: controlSize)
                
                if controlRect.contains(point) {
                    foundRegion = region
                    stop.pointee = true
                }
            }
        }
        
        return foundRegion
    }
    
    override var requiredThickness: CGFloat {
        return 60.0  // Wider to accommodate fold controls
    }
}

// Extension to compare NSColor objects
// Placed here to be self-contained within the file for this exercise.
// In a larger project, this might go into a dedicated utility file.
extension NSColor {
    func isApproximatelyEqual(to color: NSColor, tolerance: CGFloat = 0.05) -> Bool {
        guard let srgbColorSpace = NSColorSpace.sRGB else {
            print("TYPING_DEBUG: NSColor.isApproximatelyEqual - Failed to get sRGB color space. Falling back to direct comparison.")
            // Fallback to direct comparison if sRGB space is unavailable
            return self == color 
        }

        // Attempt to convert both colors to the sRGB color space
        guard let c1 = self.usingColorSpace(srgbColorSpace), 
              let c2 = color.usingColorSpace(srgbColorSpace) else {
            print("TYPING_DEBUG: NSColor.isApproximatelyEqual - Failed to convert one or both colors to sRGB. Falling back to direct comparison.")
            // Fallback if conversion fails
            return self == color 
        }

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        // Get RGBA components
        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        // Optional: Log the component values for debugging color comparison issues
        // print("TYPING_DEBUG: ColorComp C1: R\(String(format: "%.2f", r1)) G\(String(format: "%.2f", g1)) B\(String(format: "%.2f", b1)) | C2: R\(String(format: "%.2f", r2)) G\(String(format: "%.2f", g2)) B\(String(format: "%.2f", b2))")

        // Compare RGB components within the given tolerance
        // Alpha is not compared here as background is usually opaque and text visibility depends on RGB contrast.
        return abs(r1 - r2) < tolerance &&
               abs(g1 - g2) < tolerance &&
               abs(b1 - b2) < tolerance
    }
}
