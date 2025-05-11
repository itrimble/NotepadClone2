import SwiftUI
import AppKit

struct CustomTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var attributedText: NSAttributedString
    @Environment(\.colorScheme) var colorScheme
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        // Configure text view for proper text handling
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.usesFontPanel = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = NSSize(width: 10, height: 10)
        
        // Set up initial theme
        context.coordinator.updateTheme(textView)
        
        // Set up the text view with initial content
        if attributedText.length > 0 {
            textView.textStorage?.setAttributedString(attributedText)
        } else {
            let defaultAttributes = context.coordinator.defaultAttributes()
            textView.textStorage?.setAttributedString(NSAttributedString(string: "", attributes: defaultAttributes))
        }
        
        // Ensure text view becomes first responder at the right time
        DispatchQueue.main.async {
            // Only try to make first responder if the window exists and is visible
            if let window = textView.window, window.isVisible {
                window.makeFirstResponder(textView)
            }
        }
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        
        // Always update theme when view updates
        context.coordinator.updateTheme(textView)
        
        // Only update text if it has actually changed
        if let textStorage = textView.textStorage,
           textStorage.length != attributedText.length ||
           textStorage.string != attributedText.string {
            
            // Store the current selection
            let selectedRange = textView.selectedRange()
            
            // Update text storage
            textStorage.beginEditing()
            textStorage.setAttributedString(attributedText)
            textStorage.endEditing()
            
            // Restore selection safely
            let maxLength = textStorage.length
            if selectedRange.location >= 0 && selectedRange.location <= maxLength {
                let validLength = min(selectedRange.length, maxLength - selectedRange.location)
                let safeRange = NSRange(location: selectedRange.location, length: max(0, validLength))
                textView.setSelectedRange(safeRange)
            }
        }
        
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
        
        init(_ parent: CustomTextView) {
            self.parent = parent
            super.init()
        }
        
        func defaultAttributes() -> [NSAttributedString.Key: Any] {
            return [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.labelColor
            ]
        }
        
        func updateTheme(_ textView: NSTextView) {
            // Update background color
            textView.backgroundColor = NSColor.textBackgroundColor
            
            // Update typing attributes
            var attrs = textView.typingAttributes
            attrs[.foregroundColor] = NSColor.labelColor
            attrs[.backgroundColor] = NSColor.textBackgroundColor
            textView.typingAttributes = attrs
            
            // Update existing text colors if needed
            textView.textStorage?.addAttribute(.foregroundColor,
                                               value: NSColor.labelColor,
                                               range: NSRange(location: 0, length: textView.textStorage?.length ?? 0))
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView,
                  !isUpdating,
                  !isBeingRemoved else { return }
            
            // Use a flag with auto-reset to prevent circular updates
            isUpdating = true
            
            // Schedule the flag reset for next run loop iteration
            DispatchQueue.main.async { [weak self] in
                self?.isUpdating = false
            }
            
            let currentText = textView.string
            
            // Only update if text actually changed
            if currentText != lastText {
                lastText = currentText
                
                // Critical: Update text binding immediately but only once
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    // Only update if still different
                    if self.parent.text != currentText {
                        self.parent.text = currentText
                    }
                    
                    // Update attributed text
                    if let textStorage = textView.textStorage {
                        let attributedString = textStorage.copy() as! NSAttributedString
                        if !attributedString.isEqual(to: self.parent.attributedText) {
                            self.parent.attributedText = attributedString
                        }
                    }
                }
            }
        }
        
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            // Prevent changes during updates or when being removed
            return !isUpdating && !isBeingRemoved
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
            CustomTextView(text: $text, attributedText: $attributedText)
                .frame(width: 400, height: 300)
        }
    }
    
    return PreviewWrapper()
}
