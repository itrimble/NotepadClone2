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
        private var outputPipe: Pipe? // For initial pane_id
        private var errorPipe: Pipe? // For initial tmux errors
        private var outputHandle: FileHandle? // For initial pane_id
        private var errorHandle: FileHandle? // For initial tmux errors
        private var currentCommand = ""
        var tmuxSessionName: String?
        var tmuxPaneId: String?
        private var pipePaneProcess: Process? // Added for tmux pipe-pane
        private var pipePaneOutputPipe: Pipe? // Pipe for pipe-pane's stdout
        private var pipePaneErrorPipe: Pipe?  // Pipe for pipe-pane's stderr
        // tmuxCommandRunnerProcess can be a temporary Process instance within executeCommand

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
            inputPipe = Pipe() // Retain for potential future direct interaction or control sequences
            outputPipe = Pipe() // This pipe will capture the initial pane_id
            errorPipe = Pipe()

            self.tmuxSessionName = UUID().uuidString
            guard let sessionName = self.tmuxSessionName else {
                appendToTerminal("Failed to generate tmux session name\n", color: .red)
                return
            }

            process?.executableURL = URL(fileURLWithPath: "/usr/bin/tmux")
            process?.arguments = ["new-session", "-d", "-s", sessionName, "-P", "-F", "#{pane_id}", config.shell]
            // For new-session, standardInput is not the shell's input yet.
            // We capture the output (pane_id) via standardOutput.
            process?.standardInput = nil // Tmux new-session doesn't need stdin for this setup
            process?.standardOutput = outputPipe
            process?.standardError = errorPipe
            process?.currentDirectoryURL = URL(fileURLWithPath: terminal.currentDirectory)
            
            // Set up environment
            var environment = ProcessInfo.processInfo.environment
            environment["TERM"] = "xterm-256color"
            environment["LANG"] = "en_US.UTF-8"
            process?.environment = environment
            
            // Set up output handling
            outputHandle = outputPipe?.fileHandleForReading // For initial pane_id from new-session
            errorHandle = errorPipe?.fileHandleForReading // For errors from new-session
            
            outputHandle?.readabilityHandler = { [weak self] handle in
                guard let self = self else { return }
                let data = handle.availableData
                if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                    let potentialPaneId = output.trimmingCharacters(in: .whitespacesAndNewlines)
                    if self.tmuxPaneId == nil && potentialPaneId.hasPrefix("%") {
                        self.tmuxPaneId = potentialPaneId
                        print("Captured tmux pane ID: \(self.tmuxPaneId ?? "nil")")
                        // Stop listening to this initial pipe
                        self.outputHandle?.readabilityHandler = nil
                        self.outputHandle = nil // Release the handle
                        self.errorHandle?.readabilityHandler = nil // Also stop listening for initial errors
                        self.errorHandle = nil // Release the handle

                        // Start pipe-pane to get shell output
                        self.startPipePane()
                    } else if self.tmuxPaneId == nil {
                        // Unexpected output on the initial pipe
                        DispatchQueue.main.async {
                            self.appendToTerminal("tmux startup output (unexpected): \(output)\n", color: .orange)
                        }
                    }
                }
            }
            
            errorHandle?.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                // This handles errors from the initial `tmux new-session` command
                self?.handleShellOutput(data: data, isError: true)
            }
            
            do {
                try process?.run()
                terminal.isRunning = true // Mark as running, though shell output isn't piped yet
                // Don't send initial prompt here, tmux handles it.
            } catch {
                appendToTerminal("Failed to start tmux session: \(error.localizedDescription)\n", color: .red)
            }
        }
        
        func stopShell() {
            // Terminate pipe-pane process first
            pipePaneOutputPipe = nil // Release pipes
            pipePaneErrorPipe = nil
            pipePaneProcess?.terminate()
            pipePaneProcess = nil

            // Clean up initial process handlers and pipes
            outputHandle?.readabilityHandler = nil
            errorHandle?.readabilityHandler = nil
            outputHandle = nil
            errorHandle = nil
            outputPipe = nil
            errorPipe = nil

            if let sessionName = self.tmuxSessionName {
                let killProcess = Process()
                killProcess.executableURL = URL(fileURLWithPath: "/usr/bin/tmux")
                killProcess.arguments = ["kill-session", "-t", sessionName]
                do {
                    try killProcess.run()
                    killProcess.waitUntilExit()
                    print("tmux session \(sessionName) killed.")
                } catch {
                    print("Error trying to kill tmux session \(sessionName): \(error.localizedDescription)\n")
                }
            }
            process?.terminate() // Terminate the original tmux new-session process
            process = nil
            terminal.isRunning = false
        }

        private func startPipePane() {
            guard let paneId = self.tmuxPaneId else {
                appendToTerminal("Cannot start pipe-pane: tmuxPaneId is nil\n", color: .red)
                return
            }

            pipePaneProcess = Process()
            pipePaneOutputPipe = Pipe()
            pipePaneErrorPipe = Pipe()

            pipePaneProcess?.executableURL = URL(fileURLWithPath: "/usr/bin/tmux")
            pipePaneProcess?.arguments = ["pipe-pane", "-o", "-t", paneId]
            pipePaneProcess?.standardOutput = pipePaneOutputPipe
            pipePaneProcess?.standardError = pipePaneErrorPipe

            pipePaneOutputPipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                self?.handleShellOutput(data: data, isError: false)
            }

            pipePaneErrorPipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                self?.handleShellOutput(data: data, isError: true)
            }

            do {
                try pipePaneProcess?.run()
                print("tmux pipe-pane started for pane ID: \(paneId)")
            } catch {
                appendToTerminal("Failed to start tmux pipe-pane: \(error.localizedDescription)\n", color: .red)
            }
        }
        
        // Renamed from handleOutput / handleTmuxInitialOutput
        private func handleShellOutput(data: Data, isError: Bool) {
            guard !data.isEmpty else { return }
            
            if let string = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let color = isError ? NSColor.red : self.config.textColor
                    self.appendToTerminal(string, color: color)
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
            guard let paneId = self.tmuxPaneId else {
                appendToTerminal("Cannot execute command: tmuxPaneId is nil\n", color: .red)
                return
            }
            
            // It's generally better to create a new Process for each command runner
            // unless you need to maintain a persistent tmux control mode client.
            let tmuxCommandRunnerProcess = Process()
            tmuxCommandRunnerProcess.executableURL = URL(fileURLWithPath: "/usr/bin/tmux")
            // Send the command and a carriage return ("C-m")
            tmuxCommandRunnerProcess.arguments = ["send-keys", "-t", paneId, command, "C-m"]
            
            // Output/error from send-keys itself is usually not critical for the terminal display
            // but can be logged for debugging.
            // let sendKeysOutputPipe = Pipe()
            // let sendKeysErrorPipe = Pipe()
            // tmuxCommandRunnerProcess.standardOutput = sendKeysOutputPipe
            // tmuxCommandRunnerProcess.standardError = sendKeysErrorPipe
            // sendKeysOutputPipe.fileHandleForReading.readabilityHandler = { handle in /* log if needed */ }
            // sendKeysErrorPipe.fileHandleForReading.readabilityHandler = { handle in /* log if needed */ }

            do {
                try tmuxCommandRunnerProcess.run()
                // Do NOT append the command to terminal.outputText here.
                // The shell's echo and the command's actual output will come via pipe-pane.
                print("tmux send-keys executed for command: \(command)")
            } catch {
                appendToTerminal("Error executing command via tmux send-keys: \(error.localizedDescription)\n", color: .red)
            }
            
            // currentCommand is typically used for local line editing state if you were building one.
            // Since tmux handles the line editing, its direct use here might change.
            // For now, we clear it as before.
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