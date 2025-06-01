import Foundation
import AppKit

// Terminal session model
class Terminal: ObservableObject, Identifiable {
    let id = UUID()
    @Published var title: String
    @Published var currentDirectory: String
    @Published var isRunning: Bool = false
    @Published var outputText: NSAttributedString = NSAttributedString()

    // Process management properties
    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private var outputHandle: FileHandle?
    private var errorHandle: FileHandle?
    
    // Store config for use in output handling
    private var currentConfig: TerminalConfig?

    init(title: String = "Terminal", directory: String? = nil) {
        self.title = title
        self.currentDirectory = directory ?? FileManager.default.currentDirectoryPath
    }

    deinit {
        terminateProcess()
    }

    func startProcess(config: TerminalConfig) {
        guard !isRunning else { return }

        self.currentConfig = config // Store for later use by output handlers

        process = Process()
        inputPipe = Pipe()
        outputPipe = Pipe()
        errorPipe = Pipe()

        process?.executableURL = URL(fileURLWithPath: config.shell)
        process?.arguments = ["-i"] // Interactive shell
        process?.standardInput = inputPipe
        process?.standardOutput = outputPipe
        process?.standardError = errorPipe
        process?.currentDirectoryURL = URL(fileURLWithPath: currentDirectory)

        var environment = ProcessInfo.processInfo.environment
        environment["TERM"] = "xterm-256color"
        environment["LANG"] = "en_US.UTF-8"
        // Add PATH or other necessary env vars if needed
        process?.environment = environment

        outputHandle = outputPipe?.fileHandleForReading
        errorHandle = errorPipe?.fileHandleForReading

        outputHandle?.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let string = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.appendToOutputText(string, color: self?.currentConfig?.textColor ?? .white)
                }
            }
        }

        errorHandle?.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let string = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.appendToOutputText(string, color: .red) // Errors in red
                }
            }
        }

        do {
            try process?.run()
            isRunning = true
            // Initial prompt might be sent by shell itself. If not, consider adding it here.
            // For example: appendToOutputText("\(config.shell.components(separatedBy: "/").last ?? "shell")> ", color: config.textColor)
            // However, it's usually better if the shell's own PS1 provides this.
        } catch {
            appendToOutputText("Failed to start shell: \(error.localizedDescription)\n", color: .red)
            isRunning = false
        }
    }

    func terminateProcess() {
        outputHandle?.readabilityHandler = nil // Important to break retain cycles
        errorHandle?.readabilityHandler = nil

        process?.terminate()
        process = nil
        inputPipe = nil // Release pipes
        outputPipe = nil
        errorPipe = nil
        outputHandle = nil
        errorHandle = nil
        isRunning = false
        currentConfig = nil
    }

    func sendInputToProcess(string: String) {
        guard isRunning, let inputPipe = inputPipe else { return }
        if let data = string.data(using: .utf8) {
            do {
                try inputPipe.fileHandleForWriting.write(contentsOf: data)
            } catch {
                 DispatchQueue.main.async {
                     self.appendToOutputText("\nError writing to terminal: \(error.localizedDescription)\n", color: .red)
                 }
            }
        }
    }

    private func appendToOutputText(_ string: String, color: NSColor) {
        guard let config = self.currentConfig else { return } // Need config for font
        let attributes: [NSAttributedString.Key: Any] = [
            .font: config.font,
            .foregroundColor: color
        ]
        let attributedString = NSAttributedString(string: string, attributes: attributes)
        let mutableOutput = NSMutableAttributedString(attributedString: self.outputText)
        mutableOutput.append(attributedString)
        self.outputText = mutableOutput // This will publish the change
    }
}

// Terminal configuration
struct TerminalConfig {
    var shell: String = "/bin/zsh"
    var fontSize: CGFloat = 13
    var fontName: String = "Menlo"
    var backgroundColor: NSColor = NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
    var textColor: NSColor = NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
    var cursorColor: NSColor = NSColor.white
    var selectionColor: NSColor = NSColor.selectedTextBackgroundColor
    var rows: Int = 24
    var columns: Int = 80
    
    var font: NSFont {
        return NSFont(name: fontName, size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }
}

extension TerminalConfig {
    init(theme: AppTheme) {
        self.shell = "/bin/zsh" // Default, consider making this a preference
        self.rows = 24          // Default
        self.columns = 80       // Default

        // Map from AppTheme to TerminalConfig
        // AppTheme provides specific methods for terminal colors.
        self.fontName = theme.editorFontName // Use editor font for consistency or define specific terminal font in AppTheme
        self.fontSize = theme.editorFontSize   // Use editor font size or define specific

        self.backgroundColor = theme.terminalBackgroundColor()
        self.textColor = theme.terminalTextColor()
        self.cursorColor = theme.terminalCursorColor()
        self.selectionColor = theme.terminalSelectionColor()
    }