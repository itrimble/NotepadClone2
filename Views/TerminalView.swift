import SwiftUI
import AppKit

struct TerminalView: NSViewRepresentable {
    @ObservedObject var terminal: Terminal
    let config: TerminalConfig
    @Binding var needsFocus: Bool // New binding
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        let textView = TerminalTextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = true
        textView.importsGraphics = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.allowsUndo = false
        
        // Configure appearance
        textView.backgroundColor = config.backgroundColor
        textView.textColor = config.textColor
        textView.insertionPointColor = config.cursorColor
        textView.selectedTextAttributes = [
            .backgroundColor: config.selectionColor
        ]
        textView.font = config.font
        textView.typingAttributes = [
            .font: config.font,
            .foregroundColor: config.textColor
        ]
        
        scrollView.documentView = textView
        scrollView.backgroundColor = config.backgroundColor
        
        // Start the shell process using the model's method
        context.coordinator.terminal.startProcess(config: config)
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // Update appearance if config changed
        textView.backgroundColor = config.backgroundColor
        textView.textColor = config.textColor
        textView.insertionPointColor = config.cursorColor
        textView.font = config.font
        
        // Update output text
        if textView.textStorage?.attributedString != terminal.outputText {
            let currentSelectedRange = textView.selectedRange()
            textView.textStorage?.setAttributedString(terminal.outputText)
            // Try to restore selection, or scroll to end if selection is at end
            if currentSelectedRange.location + currentSelectedRange.length == textView.string.count {
                 textView.scrollToEndOfDocument(nil)
            } else {
                // This might be problematic if output replaces current input line,
                // but for now, preserve selection if not at end.
                 textView.setSelectedRange(currentSelectedRange)
            }
        }

        if needsFocus {
            DispatchQueue.main.async { // DispatchQueue.main.async to avoid issues during view update cycle
                if textView.window?.firstResponder != textView {
                    textView.window?.makeFirstResponder(textView)
                }
                self.needsFocus = false // Reset the flag
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(terminal: terminal, config: config)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let terminal: Terminal // This is @ObservedObject var terminal from TerminalView
        let config: TerminalConfig // Keep config for direct use if any, or it can be fetched from terminal model too.
        // Remove old process management properties: process, inputPipe, outputPipe, errorPipe, outputHandle, errorHandle
        private var currentCommandInputBuffer: String = "" // Buffer for current line input

        init(terminal: Terminal, config: TerminalConfig) {
            self.terminal = terminal
            self.config = config // Store config if needed for view-specific things not covered by model
            super.init()

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleSendTextToTerminal(_:)),
                name: .sendTextToTerminal,
                object: nil
            )
        }
        
        deinit {
            terminal.terminateProcess() // Tell the model to terminate its process
            NotificationCenter.default.removeObserver(self, name: .sendTextToTerminal, object: nil)
        }

       // Removed startShell(), stopShell(), handleOutput(_:isError:), appendToTerminal()
       // Output is now handled by the Terminal model itself.

        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            // This delegate method is called when the user types.
            // We want to capture the input, send it to the shell process,
            // but prevent the NSTextView from actually changing its text directly from user typing,
            // as all visible text should come from terminal.outputText.
            
            // This method manages user input.
            // All output from the shell is handled by the Terminal model and updates outputText.
            
            let currentTextViewContent = textView.string // Current content of the NSTextView
            let outputTextFromModel = terminal.outputText.string // Content from the model

            // We only want to process typing that occurs at the very end of the text view,
            // effectively where the user's input prompt would be.
            // Also, ensure that the text view is "in sync" or slightly ahead (due to local echo) of the model.
            // This check helps prevent processing input if the view is not yet updated with latest model output.
            guard affectedCharRange.location >= outputTextFromModel.count || affectedCharRange.location >= (currentTextViewContent.count - currentCommandInputBuffer.count) else {
                 // User is trying to edit text that is already "finalized" from the shell output. Disallow.
                // print("TerminalView: Attempt to edit non-input area. Range: \(affectedCharRange), OutputLength: \(outputTextFromModel.count)")
                return false
            }

            if let repString = replacementString {
                if repString == "\n" { // Enter key
                    // Append newline to buffer before sending, as shell expects it.
                    let commandToSend = currentCommandInputBuffer + "\n"
                    terminal.sendInputToProcess(string: commandToSend)

                    // Append the command (and newline) to the local text view for immediate echo.
                    // The model will eventually receive this from the shell too.
                    let locallyEchoedCommand = NSAttributedString(string: currentCommandInputBuffer + "\n", attributes: textView.typingAttributes)
                    textView.textStorage?.insert(locallyEchoedCommand, at: affectedCharRange.location)

                    currentCommandInputBuffer = "" // Clear buffer

                    // Move cursor to end after insert (NSTextView might do this, but good to be sure)
                    textView.setSelectedRange(NSMakeRange(affectedCharRange.location + locallyEchoedCommand.length, 0))
                    textView.scrollToEndOfDocument(nil)
                    return false // We handled it.
                } else {
                    // Any other typed character
                    currentCommandInputBuffer += repString

                    // Allow NSTextView to display the typed character for local echo.
                    // This text will be part of the "current input line" visually.
                    // When the shell echoes, updateNSView will reconcile.
                    // We need to insert it manually if we are managing the "input line" separately.
                    // For simplicity, let's assume the text view's typingAttributes are correct.
                    let typedAttrString = NSAttributedString(string: repString, attributes: textView.typingAttributes)
                    textView.textStorage?.replaceCharacters(in: affectedCharRange, with: typedAttrString)
                    currentCommandInputBuffer += repString // Buffer it

                    // Move cursor
                    textView.setSelectedRange(NSMakeRange(affectedCharRange.location + typedAttrString.length, 0))
                    return false // We handled it.
                }
            } else { // replacementString is nil (e.g., backspace)
                if affectedCharRange.length == 1 && !currentCommandInputBuffer.isEmpty {
                    // Standard backspace on the current input line
                    currentCommandInputBuffer.removeLast()
                    // Let NSTextView handle the visual change for backspace
                    textView.textStorage?.replaceCharacters(in: affectedCharRange, with: "")
                    return false // We handled it.
                } else if affectedCharRange.length == 1 && currentCommandInputBuffer.isEmpty {
                    // Backspace when buffer is empty - send ^H (ASCII backspace) or ^? (ASCII DEL)
                    // Most shells treat ^? (DEL) as backspace. ^H is Ctrl+H.
                    terminal.sendInputToProcess(string: "\u{7F}") // DEL character
                    return false // Prevent NSTextView from deleting into displayed output
                }
            }
            
            // Fallback for unhandled cases (should ideally not be reached if logic above is complete)
            return false // Generally, prevent direct modification unless explicitly handled
        }
        
       // textView(_:doCommandBy:) is removed as per prompt's new shouldChangeTextIn logic.

        @objc private func handleSendTextToTerminal(_ notification: Notification) {
            // This often leads to a custom NSTextStorage or more complex management.
            // The current model of replacing entire outputText in updateNSView is simple but might flicker or lose typed input.
            // A more robust solution would be for `appendToTerminal` to be on the Coordinator,
            // which updates the NSTextView's TextStorage directly, and the model's `outputText`
            // is just for persistence or if the view is recreated.
            // For this refactor, let's assume `updateNSView` is smart enough or happens fast enough.
        }
        
       // textView(_:doCommandBy:) is removed as per prompt's new shouldChangeTextIn logic.

        @objc private func handleSendTextToTerminal(_ notification: Notification) {
            guard let userInfo = notification.userInfo,
                  let targetTerminalId = userInfo["terminalId"] as? UUID,
                  targetTerminalId == self.terminal.id,
                  let textToSend = userInfo["text"] as? String else {
                return
            }
            // Text sent from external sources (e.g., TerminalManager.sendTextToActiveTerminal)
            // This text should be sent to the process.
            // The process will echo it back if that's its behavior.
            terminal.sendInputToProcess(string: textToSend)

            // Optional: local echo of programmatically sent text for immediate feedback.
            // This again interacts with how outputText is managed.
            // (self.terminal as Terminal).appendToOutputText(textToSend, color: self.config.textColor) // If Terminal exposes this and if it's made public
        }
    }
}

// Custom NSTextView subclass for terminal behavior
class TerminalTextView: NSTextView {
    override func keyDown(with event: NSEvent) {
        // Handle special keys like arrow keys, etc.
        super.keyDown(with: event)
    }
}