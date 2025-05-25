import Foundation
import AppKit
import Combine

class TerminalManager: ObservableObject {
    @Published var terminals: [Terminal] = []
    @Published var activeTerminalId: UUID?
    @Published var showTerminal: Bool = false
    @Published var terminalPosition: TerminalPosition = .bottom
    @Published var terminalHeight: CGFloat = 200
    
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
        // This will be implemented when we create the actual terminal view
        print("Running command: \(command) in terminal: \(terminal.title)")
    }
    
    func changeDirectory(_ path: String, in terminal: Terminal) {
        terminal.currentDirectory = path
        runCommand("cd \"\(path)\"", in: terminal)
    }
}