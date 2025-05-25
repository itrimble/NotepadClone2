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
        print("🔧 CustomTextView.makeNSView - Creating text view")
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        print("🔧 CustomTextView.makeNSView - ScrollView: \(scrollView), TextView: \(textView)")
        
        // Configure scroll view
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder
        
        // Configure text view for proper text handling
        textView.isRichText = true
        textView.usesFontPanel = false  // Disable font panel to prevent color picker
        textView.allowsUndo = true
        textView.delegate = context.coordinator  // Set delegate after other properties
        print("🔧 CustomTextView.makeNSView - Delegate set: \(textView.delegate != nil)")
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = NSSize(width: 10, height: 10)
        
        // CRITICAL: Make text view editable and visible
        textView.isEditable = true
        textView.isSelectable = true
        print("🔧 CustomTextView.makeNSView - isEditable: \(textView.isEditable), isSelectable: \(textView.isSelectable)")
        textView.importsGraphics = false
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
            lineNumberView.textColor = appTheme.editorTextColor().withAlphaComponent(0.5)
            lineNumberView.language = language
            lineNumberView.coordinator = context.coordinator
            scrollView.verticalRulerView = lineNumberView
        } else {
            scrollView.hasVerticalRuler = false
            scrollView.rulersVisible = false
        }
        
        // Set up initial theme
        context.coordinator.updateTheme(textView)
        
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
        
        // Make text view the first responder when window is ready
        DispatchQueue.main.async {
            if let window = textView.window {
                let success = window.makeFirstResponder(textView)
                print("🔧 CustomTextView.makeNSView - First responder attempt: \(success), window: \(window), current first responder: \(window.firstResponder)")
            } else {
                print("❌ CustomTextView.makeNSView - No window available for first responder")
            }
        }
        
        print("✅ CustomTextView.makeNSView - Complete, returning scrollView")
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        print("🔄 CustomTextView.updateNSView - Called, textView: \(textView)")
        
        // Always update theme when view updates
        context.coordinator.updateTheme(textView)
        
        // Update line numbers visibility
        if showLineNumbers {
            nsView.hasVerticalRuler = true
            nsView.rulersVisible = true
            if let codeRulerView = nsView.verticalRulerView as? CodeFoldingRulerView {
                codeRulerView.backgroundColor = NSColor(appTheme.tabBarBackgroundColor())
                codeRulerView.textColor = appTheme.editorTextColor().withAlphaComponent(0.5)
                codeRulerView.language = language
                codeRulerView.needsDisplay = true
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
        
        // CRITICAL FIX: Safe responder management
        if let window = textView.window,
           window.isVisible,
           window.isKeyWindow,
           !context.coordinator.isBeingRemoved {
            
            // Only make first responder after a delay to avoid conflicts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                if let stillValidWindow = textView.window,
                   stillValidWindow.isVisible && stillValidWindow.isKeyWindow,
                   stillValidWindow.firstResponder != textView {
                    stillValidWindow.makeFirstResponder(textView)
                    // Force cursor to blink
                    textView.updateInsertionPointStateAndRestartTimer(true)
                }
            }
        }
    }
    
    static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
        // CRITICAL FIX: Simplify responder handling
        coordinator.isBeingRemoved = true
        
        // Clean up delegate
        if let textView = nsView.documentView as? NSTextView {
            textView.delegate = nil
            
            // Let AppKit handle responder transitions naturally
            // DO NOT call resignFirstResponder() directly
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CustomTextView
        private var isUpdating = false
        private var lastText = ""
        var isBeingRemoved = false // Track if view is being dismantled
        @Published var selectedRange: NSRange = NSRange(location: 0, length: 0)
        var foldableRegions: [FoldableRegion] = []
        
        init(_ parent: CustomTextView) {
            self.parent = parent
            super.init()
            print("🔧 Coordinator.init - Created coordinator")
            
            // Observe jump to line notifications
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleJumpToLine(_:)),
                name: .jumpToLine,
                object: nil
            )
        }
        
        deinit {
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
            
            // Update background color
            textView.backgroundColor = theme.editorBackgroundColor()
            
            // Update typing attributes
            var attrs = textView.typingAttributes
            attrs[.foregroundColor] = theme.editorTextColor()
            attrs[.backgroundColor] = theme.editorBackgroundColor()
            attrs[.font] = NSFont.systemFont(ofSize: 14)
            textView.typingAttributes = attrs
            
            // Update existing text colors if needed
            if let textStorage = textView.textStorage {
                let range = NSRange(location: 0, length: textStorage.length)
                textStorage.addAttribute(.foregroundColor, value: theme.editorTextColor(), range: range)
                // Also ensure font is set
                if textStorage.length > 0 && textStorage.attribute(.font, at: 0, effectiveRange: nil) == nil {
                    textStorage.addAttribute(.font, value: NSFont.systemFont(ofSize: 14), range: range)
                }
            }
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                print("❌ textDidChange - Not a valid NSTextView")
                return
            }
            guard !isUpdating else {
                print("⚠️ textDidChange - Blocked: isUpdating = true")
                return
            }
            guard !isBeingRemoved else {
                print("⚠️ textDidChange - Blocked: isBeingRemoved = true")
                return
            }
            print("✏️ textDidChange - Text changed to: \(textView.string.prefix(50))...")
            
            let currentText = textView.string
            
            // Only update if text actually changed
            if currentText != lastText {
                lastText = currentText
                
                // Set flag to prevent circular updates
                isUpdating = true
                defer { isUpdating = false }
                
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
                }
                
                // Update attributed text synchronously
                if let textStorage = textView.textStorage {
                    let attributedString = textStorage.copy() as! NSAttributedString
                    if !attributedString.isEqual(to: parent.attributedText) {
                        parent.attributedText = attributedString
                    }
                }
                
                // Update bracket highlighting after a short delay to allow syntax highlighting to complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    self?.updateBracketHighlighting(in: textView)
                }
            }
        }
        
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            print("🎹 shouldChangeTextIn - Range: \(affectedCharRange), Replacement: '\(replacementString ?? "nil")', Length: \(replacementString?.count ?? 0)")
            
            // Log current state
            print("   📊 Current state - isUpdating: \(isUpdating), isBeingRemoved: \(isBeingRemoved)")
            print("   📊 TextView state - isEditable: \(textView.isEditable), window: \(textView.window != nil)")
            print("   📊 First responder: \(textView.window?.firstResponder == textView)")
            
            // Prevent changes during updates or when being removed
            guard !isUpdating && !isBeingRemoved else {
                print("   ❌ shouldChangeTextIn - BLOCKED: isUpdating=\(isUpdating), isBeingRemoved=\(isBeingRemoved)")
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
            
            print("   ✅ shouldChangeTextIn - ALLOWING text change")
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
            guard let lineNumber = notification.userInfo?["lineNumber"] as? Int,
                  let textView = NSApp.keyWindow?.firstResponder as? NSTextView else { return }
            
            let text = textView.string
            let lines = text.components(separatedBy: .newlines)
            
            guard lineNumber > 0 && lineNumber <= lines.count else { return }
            
            // Calculate character position for the line
            let lineIndex = lineNumber - 1
            var charPosition = 0
            
            for i in 0..<lineIndex {
                charPosition += lines[i].count + 1 // +1 for newline
            }
            
            // Create range for the line
            let lineLength = lines[lineIndex].count
            let lineRange = NSRange(location: charPosition, length: lineLength)
            
            // Scroll to and select the line
            textView.scrollRangeToVisible(lineRange)
            textView.setSelectedRange(lineRange)
            
            // Make sure text view is first responder
            textView.window?.makeFirstResponder(textView)
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
