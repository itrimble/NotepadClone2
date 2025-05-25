import Foundation
import AppKit

// Terminal session model
class Terminal: ObservableObject, Identifiable {
    let id = UUID()
    @Published var title: String
    @Published var currentDirectory: String
    @Published var isRunning: Bool = false
    @Published var outputText: NSAttributedString = NSAttributedString()
    
    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    
    init(title: String = "Terminal", directory: String? = nil) {
        self.title = title
        self.currentDirectory = directory ?? FileManager.default.currentDirectoryPath
    }
    
    deinit {
        terminate()
    }
    
    func terminate() {
        process?.terminate()
        process = nil
        inputPipe = nil
        outputPipe = nil
        errorPipe = nil
        isRunning = false
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