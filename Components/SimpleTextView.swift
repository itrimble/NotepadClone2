import SwiftUI
import AppKit

// Minimal text view to diagnose typing issues
struct SimpleTextView: NSViewRepresentable {
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        // Minimal configuration
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.string = text
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        if textView.string != text && !context.coordinator.isUpdating {
            context.coordinator.isUpdating = true
            textView.string = text
            context.coordinator.isUpdating = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SimpleTextView
        var isUpdating = false
        
        init(_ parent: SimpleTextView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView,
                  !isUpdating else { return }
            
            isUpdating = true
            parent.text = textView.string
            isUpdating = false
        }
    }
}