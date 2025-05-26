import SwiftUI
import AppKit

struct CustomTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var attributedText: NSAttributedString
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appState: AppState // Access AppState for AIManager
    let appTheme: AppTheme
    let showLineNumbers: Bool
    let language: SyntaxHighlighter.Language
    let document: Document  // Pass the document directly
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder
        
        textView.isRichText = true
        textView.usesFontPanel = false
        textView.allowsUndo = true
        textView.delegate = context.coordinator
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = NSSize(width: 10, height: 10)
        
        textView.isEditable = true
        textView.isSelectable = true
        textView.importsGraphics = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        
        textView.insertionPointColor = appTheme.editorTextColor()
        textView.isFieldEditor = false
        textView.usesInspectorBar = false
        textView.drawsBackground = true
        textView.backgroundColor = appTheme.editorBackgroundColor()
        
        if showLineNumbers {
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
            let lineNumberView = CodeFoldingRulerView(scrollView: scrollView, orientation: .verticalRuler)
            lineNumberView.clientView = textView
            lineNumberView.ruleThickness = 60.0
            lineNumberView.backgroundColor = NSColor(appTheme.tabBarBackgroundColor())
            lineNumberView.textColor = appTheme.editorTextColor()
            lineNumberView.language = language
            lineNumberView.coordinator = context.coordinator
            scrollView.verticalRulerView = lineNumberView
        } else {
            scrollView.hasVerticalRuler = false
            scrollView.rulersVisible = false
        }
        
        context.coordinator.updateTheme(textView)
        let defaultAttributes = context.coordinator.defaultAttributes()
        // Ensure initial text is set if attributedText is empty but text is not
        if attributedText.length == 0 && !text.isEmpty {
             textView.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: defaultAttributes))
        } else {
             textView.textStorage?.setAttributedString(attributedText)
        }
        
        if let textContainer = textView.textContainer {
            textContainer.widthTracksTextView = true
            textContainer.containerSize = CGSize(width: max(100, scrollView.frame.width), height: CGFloat.greatestFiniteMagnitude)
        }
        
        textView.needsLayout = true
        scrollView.needsLayout = true
        textView.typingAttributes = defaultAttributes
        
        DispatchQueue.main.async {
            if let window = textView.window {
                _ = window.makeFirstResponder(textView)
            }
        }
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        context.coordinator.updateTheme(textView)
        
        if showLineNumbers {
            nsView.hasVerticalRuler = true
            nsView.rulersVisible = true
            if let codeRulerView = nsView.verticalRulerView as? CodeFoldingRulerView {
                codeRulerView.backgroundColor = NSColor(appTheme.tabBarBackgroundColor())
                codeRulerView.textColor = appTheme.editorTextColor()
                codeRulerView.language = language
                codeRulerView.needsDisplay = true // Ensure ruler redraws on theme change
            }
        } else {
            nsView.hasVerticalRuler = false
            nsView.rulersVisible = false
        }
        
        if let textStorage = textView.textStorage {
            // Check if the bound attributedText is different from the textView's current attributedText
            // This prevents re-applying the same text which can cause cursor position loss or unwanted scrolling
            if !textStorage.isEqual(to: attributedText) {
                let selectedRange = textView.selectedRange()
                textStorage.beginEditing()
                textStorage.setAttributedString(attributedText)
                textStorage.endEditing()
                
                let maxLength = textStorage.length
                if selectedRange.location <= maxLength {
                    let validLength = min(selectedRange.length, maxLength - selectedRange.location)
                    let safeRange = NSRange(location: selectedRange.location, length: max(0, validLength))
                    textView.setSelectedRange(safeRange)
                }
            }
        }
        
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.insertionPointColor = appTheme.editorTextColor()
        
        if let window = textView.window, window.isVisible, window.isKeyWindow, !context.coordinator.isBeingRemoved {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                if let stillValidWindow = textView.window, stillValidWindow.isVisible && stillValidWindow.isKeyWindow, stillValidWindow.firstResponder != textView {
                    stillValidWindow.makeFirstResponder(textView)
                    textView.updateInsertionPointStateAndRestartTimer(true)
                }
            }
        }
    }
    
    static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
        coordinator.isBeingRemoved = true
        if let textView = nsView.documentView as? NSTextView {
            textView.delegate = nil
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, appState: appState)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CustomTextView
        var appState: AppState
        private var isUpdating = false // Prevents re-entrant calls during programmatic text changes
        private var lastText = "" // Used to compare if text actually changed
        var isBeingRemoved = false // Flag to manage dismantling
        @Published var selectedRange: NSRange = NSRange(location: 0, length: 0)
        var foldableRegions: [FoldableRegion] = []
        
        init(_ parent: CustomTextView, appState: AppState) {
            self.parent = parent
            self.appState = appState
            super.init()
            NotificationCenter.default.addObserver(self, selector: #selector(handleJumpToLine(_:)), name: .jumpToLine, object: nil)
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        func defaultAttributes() -> [NSAttributedString.Key: Any] {
            let theme = parent.appTheme
            return [
                .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
                .foregroundColor: theme.editorTextColor()
            ]
        }
        
        func updateTheme(_ textView: NSTextView) {
            let theme = parent.appTheme
            textView.backgroundColor = theme.editorBackgroundColor()
            var attrs = textView.typingAttributes
            attrs[.foregroundColor] = theme.editorTextColor()
            attrs[.font] = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
            textView.typingAttributes = attrs
            
            if let textStorage = textView.textStorage, textStorage.length > 0 {
                 isUpdating = true // Prevent textDidChange from re-triggering updates
                 textStorage.beginEditing()
                 textStorage.addAttribute(.foregroundColor, value: theme.editorTextColor(), range: NSRange(location: 0, length: textStorage.length))
                 // Ensure font is also updated if not already set correctly
                 if textStorage.attribute(.font, at: 0, effectiveRange: nil) == nil || 
                    (textStorage.attribute(.font, at: 0, effectiveRange: nil) as? NSFont)?.fontName != NSFont.monospacedSystemFont(ofSize: 14, weight: .regular).fontName {
                     textStorage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular), range: NSRange(location:0, length: textStorage.length))
                 }
                 textStorage.endEditing()
                 isUpdating = false
            }
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView, !isUpdating, !isBeingRemoved else { return }
            
            let currentText = textView.string
            // Check if the actual string content has changed.
            // This helps avoid loops if only attributes were changed by syntax highlighter.
            if currentText != parent.text { // Compare with the source of truth plain text
                lastText = currentText // Update lastText only when actual content changes
                
                isUpdating = true // Prevents re-entrant calls from programmatic changes to attributedText
                parent.text = currentText // Update plain text binding
                if let textStorage = textView.textStorage {
                    parent.attributedText = NSAttributedString(attributedString: textStorage) // Update attributedText binding
                }
                isUpdating = false
            }
            
            // These should always run if textDidChange is called legitimately
            updateFoldableRegions(for: currentText)
            if let scrollView = textView.enclosingScrollView, let rulerView = scrollView.verticalRulerView {
                rulerView.needsDisplay = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.updateBracketHighlighting(in: textView)
            }
        }
        
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            guard !isUpdating && !isBeingRemoved else { return false }
            if let replacement = replacementString, replacement == "\n" {
                if SmartIndenter.handleNewlineIndentation(in: textView, language: parent.language) {
                    return false
                }
            }
            return true
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView, !isUpdating else { return }
            let newRange = textView.selectedRange()
            if selectedRange != newRange {
                selectedRange = newRange
                updateBracketHighlighting(in: textView)
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(postSelectionChange), object: nil)
                perform(#selector(postSelectionChange), with: nil, afterDelay: 0.1)
            }
        }
        
        @objc private func postSelectionChange() {
            NotificationCenter.default.post(name: .textViewSelectionDidChange, object: nil, userInfo: ["selectedRange": selectedRange])
        }
        
        @objc private func handleJumpToLine(_ notification: Notification) {
            guard let lineNumber = notification.userInfo?["lineNumber"] as? Int,
                  let textView = NSApp.keyWindow?.firstResponder as? NSTextView else { return }
            let text = textView.string
            let lines = text.components(separatedBy: .newlines)
            guard lineNumber > 0 && lineNumber <= lines.count else { return }
            let lineIndex = lineNumber - 1
            var charPosition = 0
            for i in 0..<lineIndex { charPosition += lines[i].count + 1 }
            let lineLength = lines[lineIndex].count
            let lineRange = NSRange(location: charPosition, length: lineLength)
            textView.scrollRangeToVisible(lineRange)
            textView.setSelectedRange(lineRange)
            textView.window?.makeFirstResponder(textView)
        }
        
        func updateFoldableRegions(for text: String) {
            let folder = CodeFolder(language: parent.language)
            foldableRegions = folder.detectFoldableRegions(in: text)
        }
        
        func toggleFold(for region: FoldableRegion) {
            parent.document.toggleFold(for: region)
            if let textView = NSApp.keyWindow?.firstResponder as? NSTextView,
               let scrollView = textView.enclosingScrollView,
               let rulerView = scrollView.verticalRulerView as? CodeFoldingRulerView {
                rulerView.needsDisplay = true
            }
        }
        
        func isFolded(_ region: FoldableRegion) -> Bool {
            return parent.document.isFolded(region)
        }
        
        private func updateBracketHighlighting(in textView: NSTextView) {
            let syntaxTheme = parent.appTheme.syntaxTheme()
            BracketMatcher.highlightBrackets(in: textView, theme: syntaxTheme)
        }

        // MARK: - Context Menu
        func textView(_ textView: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
            let defaultMenu = menu 
            let selectedRange = textView.selectedRange()
            let hasSelection = selectedRange.length > 0

            let aiMenuItem = NSMenuItem(title: "Ask AI...", action: nil, keyEquivalent: "")
            let aiSubmenu = NSMenu()

            let summarizeItem = NSMenuItem(title: "Summarize Selection", action: #selector(summarizeSelection(_:)), keyEquivalent: "")
            summarizeItem.target = self
            summarizeItem.representedObject = textView 
            summarizeItem.isEnabled = hasSelection
            aiSubmenu.addItem(summarizeItem)

            let explainItem = NSMenuItem(title: "Explain Selection", action: #selector(explainSelection(_:)), keyEquivalent: "")
            explainItem.target = self
            explainItem.representedObject = textView
            explainItem.isEnabled = hasSelection
            aiSubmenu.addItem(explainItem)
            
            let translateItem = NSMenuItem(title: "Translate Selection (to English)", action: #selector(translateSelection(_:)), keyEquivalent: "")
            translateItem.target = self
            translateItem.representedObject = textView
            translateItem.isEnabled = hasSelection
            aiSubmenu.addItem(translateItem)

            aiMenuItem.submenu = aiSubmenu
            
            var insertAtIndex = 0
            if defaultMenu.items.count > 0 {
                if let pasteItemIndex = defaultMenu.indexOfItem(withTarget: nil, andAction: #selector(NSText.paste(_:))) {
                    insertAtIndex = pasteItemIndex + 1 // After Paste
                } else if let selectAllIndex = defaultMenu.indexOfItem(withTarget: nil, andAction: #selector(NSText.selectAll(_:))) {
                    insertAtIndex = selectAllIndex + 1 // After Select All
                } else {
                    insertAtIndex = min(defaultMenu.items.count, 5) // Fallback position
                }
                
                // Ensure separator is only added if not already present at this specific location
                if insertAtIndex > 0 && !defaultMenu.item(at: insertAtIndex - 1)!.isSeparatorItem {
                     defaultMenu.insertItem(NSMenuItem.separator(), at: insertAtIndex)
                     insertAtIndex += 1 
                } else if insertAtIndex == 0 && defaultMenu.items.count > 0 { // If inserting at very top, add separator after
                    // This case might not be hit if pasteItemIndex or selectAllIndex are usually found
                }
            }
            
            defaultMenu.insertItem(aiMenuItem, at: insertAtIndex)

            return defaultMenu
        }

        @objc func summarizeSelection(_ sender: NSMenuItem) {
            guard let textView = sender.representedObject as? NSTextView,
                  textView.selectedRange().length > 0 else { return }
            let selectedText = (textView.string as NSString).substring(with: textView.selectedRange())
            let prompt = "Summarize the following text:\n\n\(selectedText)"
            submitToAIFromContextMenu(prompt: prompt)
        }

        @objc func explainSelection(_ sender: NSMenuItem) {
            guard let textView = sender.representedObject as? NSTextView,
                  textView.selectedRange().length > 0 else { return }
            let selectedText = (textView.string as NSString).substring(with: textView.selectedRange())
            let prompt = "Explain the following text/code:\n\n\(selectedText)"
            submitToAIFromContextMenu(prompt: prompt)
        }
        
        @objc func translateSelection(_ sender: NSMenuItem) {
            guard let textView = sender.representedObject as? NSTextView,
                  textView.selectedRange().length > 0 else { return }
            let selectedText = (textView.string as NSString).substring(with: textView.selectedRange())
            let prompt = "Translate the following text to English:\n\n\(selectedText)"
            submitToAIFromContextMenu(prompt: prompt)
        }
        
        private func submitToAIFromContextMenu(prompt: String) {
            DispatchQueue.main.async {
                self.appState.showAIAssistantPanel = true
            }
            
            guard let aiManager = appState.aiManager else {
                print("Error: AIManager not available from AppState in CustomTextView.Coordinator")
                DispatchQueue.main.async {
                     if let manager = self.appState.aiManager { // Check again inside async block
                        manager.latestResponseContent = "Error: AIManager not available for context menu."
                        manager.isProcessing = false
                    }
                }
                return
            }
            
            // AIManager's submitPrompt will update its @Published properties
            aiManager.submitPrompt(prompt: prompt) { result in
                // Logging for debugging
                switch result {
                case .success(let response):
                    print("AI Context Menu: Prompt successful. Response: \(response.content.prefix(100))...")
                case .failure(let error):
                    print("AI Context Menu: Prompt failed. Error: \(error.localizedDescription)")
                }
            }
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
        @StateObject private var appState = AppState() 
        
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
            .environmentObject(appState) 
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
        backgroundColor.set()
        rect.fill()
        
        guard let textView = self.clientView as? NSTextView,
              let textContainer = textView.textContainer,
              let layoutManager = textView.layoutManager,
              let coordinator = coordinator else { return }
        
        let contentRect = convert(textView.visibleRect, from: textView)
        let textVisibleRect = textView.visibleRect
        
        let glyphRange = layoutManager.glyphRange(forBoundingRect: textVisibleRect, in: textContainer)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        
        let text = textView.string as NSString
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        var lineNumber = 0
        text.enumerateSubstrings(in: NSRange(location: 0, length: characterRange.location),
                                options: [.byLines, .substringNotRequired]) { _, _, _, _ in
            lineNumber += 1
        }
        
        var regionsByStartLine: [Int: FoldableRegion] = [:]
        for region in coordinator.foldableRegions {
            regionsByStartLine[region.startLine] = region
        }
        
        text.enumerateSubstrings(in: characterRange,
                                options: [.byLines, .substringNotRequired]) { _, lineRange, _, _ in
            lineNumber += 1
            let lineGlyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: lineGlyphRange.location, effectiveRange: nil)
            let y = lineRect.minY - textVisibleRect.minY + contentRect.minY
            let lineNumberString = "\(lineNumber)"
            let size = lineNumberString.size(withAttributes: attributes)
            let lineNumberPoint = NSPoint(x: self.ruleThickness - size.width - 5, y: y)
            lineNumberString.draw(at: lineNumberPoint, withAttributes: attributes)
            
            if let region = regionsByStartLine[lineNumber] {
                self.drawFoldControl(for: region, at: NSPoint(x: 5, y: y), coordinator: coordinator)
            }
        }
    }
    
    private func drawFoldControl(for region: FoldableRegion, at point: NSPoint, coordinator: CustomTextView.Coordinator) {
        let isFolded = coordinator.isFolded(region)
        let controlSize: CGFloat = 12
        let controlRect = NSRect(x: point.x, y: point.y + 2, width: controlSize, height: controlSize)
        
        NSColor.controlBackgroundColor.set()
        controlRect.fill()
        
        textColor.withAlphaComponent(0.3).set()
        controlRect.frame()
        
        let signColor = textColor.withAlphaComponent(0.7)
        let lineWidth: CGFloat = 1.5
        
        let horizontalPath = NSBezierPath()
        horizontalPath.lineWidth = lineWidth
        let centerY = controlRect.midY
        let leftX = controlRect.minX + 3
        let rightX = controlRect.maxX - 3
        horizontalPath.move(to: NSPoint(x: leftX, y: centerY))
        horizontalPath.line(to: NSPoint(x: rightX, y: centerY))
        signColor.set()
        horizontalPath.stroke()
        
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
        let glyphRange = layoutManager.glyphRange(forBoundingRect: textVisibleRect, in: textContainer)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        let text = textView.string as NSString
        var lineNumber = 0
        text.enumerateSubstrings(in: NSRange(location: 0, length: characterRange.location),
                                options: [.byLines, .substringNotRequired]) { _, _, _, _ in
            lineNumber += 1
        }
        
        var regionsByStartLine: [Int: FoldableRegion] = [:]
        for region in coordinator.foldableRegions {
            regionsByStartLine[region.startLine] = region
        }
        
        var foundRegion: FoldableRegion?
        text.enumerateSubstrings(in: characterRange,
                                options: [.byLines, .substringNotRequired]) { _, lineRange, _, stop in
            lineNumber += 1
            let lineGlyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: lineGlyphRange.location, effectiveRange: nil)
            let y = lineRect.minY - textVisibleRect.minY + contentRect.minY
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
        return 60.0
    }
}
