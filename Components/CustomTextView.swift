import SwiftUI
import AppKit

struct CustomTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var attributedText: NSAttributedString
    
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
        
        // Set default text attributes
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.labelColor  // Use dynamic color for light/dark mode
        ]
        textView.typingAttributes = defaultAttributes
        
        // Set background color
        textView.backgroundColor = NSColor.textBackgroundColor
        
        // Set up the text view with initial content
        if attributedText.length > 0 {
            // Ensure proper text color on initial load
            let mutableString = NSMutableAttributedString(attributedString: attributedText)
            let range = NSRange(location: 0, length: mutableString.length)
            mutableString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: range)
            textView.textStorage?.setAttributedString(mutableString)
        } else {
            // Set empty string with default attributes
            textView.textStorage?.setAttributedString(NSAttributedString(string: "", attributes: defaultAttributes))
        }
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        
        // Update background color for theme changes
        textView.backgroundColor = NSColor.textBackgroundColor
        
        // Only update if the attributed text has actually changed
        if textView.textStorage?.isEqual(to: attributedText) == false {
            // Store the current selection
            let selectedRange = textView.selectedRange()
            
            // Create a mutable copy and ensure proper text color
            let mutableString = NSMutableAttributedString(attributedString: attributedText)
            let fullRange = NSRange(location: 0, length: mutableString.length)
            
            // Safely apply default text color to any text that doesn't have a color
            mutableString.enumerateAttribute(.foregroundColor, in: fullRange) { (value, range, _) in
                if value == nil {
                    // Validate range before applying attribute
                    let safeRange = NSIntersectionRange(range, fullRange)
                    if safeRange.length > 0 {
                        mutableString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: safeRange)
                    }
                }
            }
            
            // Update text storage
            textView.textStorage?.setAttributedString(mutableString)
            
            // Restore the selection if the text length allows
            if selectedRange.location >= 0 && selectedRange.location <= textView.string.count {
                let maxLength = textView.string.count
                let validLength = min(selectedRange.length, maxLength - selectedRange.location)
                let safeRange = NSRange(location: selectedRange.location, length: max(0, validLength))
                textView.setSelectedRange(safeRange)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CustomTextView
        
        init(_ parent: CustomTextView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Update on the main thread to prevent potential race conditions
            DispatchQueue.main.async {
                // Ensure proper text color for new text
                let mutableString = NSMutableAttributedString(attributedString: textView.attributedString())
                let range = NSRange(location: 0, length: mutableString.length)
                
                // Apply default text color to any text that doesn't have a color
                mutableString.enumerateAttribute(.foregroundColor, in: range) { (value, range, _) in
                    if value == nil {
                        mutableString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: range)
                    }
                }
                
                self.parent.attributedText = mutableString
                self.parent.text = textView.string
            }
        }
        
        // Handle font changes from the font panel
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            return true
        }
        
        // Ensure proper typing attributes
        func textView(_ textView: NSTextView, willChangeSelectionFrom oldSelectedCharRange: NSRange, to newSelectedCharRange: NSRange) -> NSRange {
            // Maintain proper typing attributes including text color
            if let attrs = textView.typingAttributes[.foregroundColor] {
                if attrs as! NSColor != NSColor.labelColor {
                    var newAttrs = textView.typingAttributes
                    newAttrs[.foregroundColor] = NSColor.labelColor
                    textView.typingAttributes = newAttrs
                }
            }
            return newSelectedCharRange
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
