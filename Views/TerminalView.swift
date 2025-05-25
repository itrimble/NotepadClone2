import SwiftUI
import AppKit

struct TerminalView: NSViewRepresentable {
    @ObservedObject var terminal: Terminal
    let config: TerminalConfig
    
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
        
        // Start the shell process
        context.coordinator.startShell()
        
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
            textView.textStorage?.setAttributedString(terminal.outputText)
            
            // Scroll to bottom
            textView.scrollToEndOfDocument(nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(terminal: terminal, config: config)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let terminal: Terminal
        let config: TerminalConfig
        private var process: Process?
        private var inputPipe: Pipe?
        private var outputPipe: Pipe?
        private var errorPipe: Pipe?
        private var outputHandle: FileHandle?
        private var errorHandle: FileHandle?
        private var currentCommand = ""
        
        init(terminal: Terminal, config: TerminalConfig) {
            self.terminal = terminal
            self.config = config
            super.init()
        }
        
        deinit {
            stopShell()
        }
        
        func startShell() {
            process = Process()
            inputPipe = Pipe()
            outputPipe = Pipe()
            errorPipe = Pipe()
            
            process?.executableURL = URL(fileURLWithPath: config.shell)
            process?.arguments = ["-i"] // Interactive shell
            process?.standardInput = inputPipe
            process?.standardOutput = outputPipe
            process?.standardError = errorPipe
            process?.currentDirectoryURL = URL(fileURLWithPath: terminal.currentDirectory)
            
            // Set up environment
            var environment = ProcessInfo.processInfo.environment
            environment["TERM"] = "xterm-256color"
            environment["LANG"] = "en_US.UTF-8"
            process?.environment = environment
            
            // Set up output handling
            outputHandle = outputPipe?.fileHandleForReading
            errorHandle = errorPipe?.fileHandleForReading
            
            outputHandle?.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                self?.handleOutput(data, isError: false)
            }
            
            errorHandle?.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                self?.handleOutput(data, isError: true)
            }
            
            do {
                try process?.run()
                terminal.isRunning = true
                
                // Send initial prompt
                appendToTerminal("\(config.shell.components(separatedBy: "/").last ?? "shell")> ", color: config.textColor)
            } catch {
                appendToTerminal("Failed to start shell: \(error.localizedDescription)\n", color: .red)
            }
        }
        
        func stopShell() {
            outputHandle?.readabilityHandler = nil
            errorHandle?.readabilityHandler = nil
            process?.terminate()
            process = nil
            terminal.isRunning = false
        }
        
        private func handleOutput(_ data: Data, isError: Bool) {
            guard !data.isEmpty else { return }
            
            if let string = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async { [weak self] in
                    let color = isError ? NSColor.red : self?.config.textColor ?? .white
                    self?.appendToTerminal(string, color: color)
                }
            }
        }
        
        private func appendToTerminal(_ string: String, color: NSColor) {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: config.font,
                .foregroundColor: color
            ]
            
            let attributedString = NSAttributedString(string: string, attributes: attributes)
            let mutableOutput = NSMutableAttributedString(attributedString: terminal.outputText)
            mutableOutput.append(attributedString)
            
            terminal.outputText = mutableOutput
        }
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                // Handle return key - execute command
                if let textStorage = textView.textStorage {
                    let text = textStorage.string
                    let lines = text.components(separatedBy: .newlines)
                    if let lastLine = lines.last {
                        // Extract command from the last line (after the prompt)
                        if let promptRange = lastLine.range(of: "> ") {
                            currentCommand = String(lastLine[promptRange.upperBound...])
                            executeCommand(currentCommand)
                            
                            // Add newline to terminal
                            appendToTerminal("\n", color: config.textColor)
                        }
                    }
                }
                return true
            }
            return false
        }
        
        private func executeCommand(_ command: String) {
            guard let input = inputPipe?.fileHandleForWriting else { return }
            
            let commandData = (command + "\n").data(using: .utf8) ?? Data()
            
            do {
                try input.write(contentsOf: commandData)
            } catch {
                appendToTerminal("Error executing command: \(error.localizedDescription)\n", color: .red)
            }
            
            currentCommand = ""
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