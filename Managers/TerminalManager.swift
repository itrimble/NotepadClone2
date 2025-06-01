import Foundation
import AppKit
import Combine

class TerminalManager: ObservableObject {
    @Published var terminals: [Terminal] = []
    @Published var activeTerminalId: UUID?
    @Published var showTerminal: Bool = false
    @Published var terminalPosition: TerminalPosition = .bottom
    @Published var terminalHeight: CGFloat = 200
    @Published var terminalWidth: CGFloat = 300 // Added for right-positioned terminal
    
    private var cancellables = Set<AnyCancellable>()
    
    enum TerminalPosition: String, CaseIterable {
        case bottom = "Bottom"
        case right = "Right"
        
        var isHorizontal: Bool {
            switch self {
            case .bottom: return true
            case .right: return false
            }
        }
    }
    
    var activeTerminal: Terminal? {
        terminals.first { $0.id == activeTerminalId }
    }
    
    init() {
        // Create default terminal if needed
        if terminals.isEmpty {
            createNewTerminal()
        }
    }
    
    func createNewTerminal(directory: String? = nil) {
        let terminal = Terminal(title: "Terminal \(terminals.count + 1)", directory: directory)
        terminals.append(terminal)
        activeTerminalId = terminal.id
        showTerminal = true
    }
    
    func closeTerminal(_ terminal: Terminal) {
        terminal.terminate()
        terminals.removeAll { $0.id == terminal.id }
        
        // Select another terminal if the active one was closed
        if activeTerminalId == terminal.id {
            activeTerminalId = terminals.first?.id
        }
        
        // Hide terminal panel if no terminals left
        if terminals.isEmpty {
            showTerminal = false
        }
    }
    
    func toggleTerminal() {
        if terminals.isEmpty {
            createNewTerminal()
        } else {
            showTerminal.toggle()
        }
    }
    
    func runCommand(_ command: String, in terminal: Terminal) {
        let commandWithNewline = command + "\n" // Ensure newline for shell execution
        terminal.sendInputToProcess(string: commandWithNewline)
        // print("Running command: \(command) in terminal: \(terminal.title)") // Keep for debugging if desired
    }
    
    func changeDirectory(_ path: String, in terminal: Terminal) {
        terminal.currentDirectory = path // Update model's perspective
        let cdCommand = "cd \"\(path)\"\n" // Construct cd command
        terminal.sendInputToProcess(string: cdCommand)
    }

    public func sendTextToActiveTerminal(text: String) {
        guard let activeId = activeTerminalId else {
            print("TerminalManager: No active terminal to send text to.")
            return
        }
        // Ensure the active terminal actually exists
        guard terminals.contains(where: { $0.id == activeId }) else {
            print("TerminalManager: Active terminal ID \(activeId) does not exist in the list of terminals.")
            return
        }

        print("TerminalManager: Posting notification to send text to terminal ID \(activeId)")
        NotificationCenter.default.post(
            name: .sendTextToTerminal,
            object: self,
            userInfo: ["terminalId": activeId, "text": text]
        )
    }
}