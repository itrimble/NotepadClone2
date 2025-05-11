import SwiftUI
import AppKit

class FindPanelManager: ObservableObject {
    @Published var searchText = ""
    @Published var replaceText = ""
    @Published var showFindPanel = false
    @Published var showReplacePanel = false
    @Published var caseSensitive = false
    @Published var useRegex = false
    
    weak var appState: AppState?
    
    init(appState: AppState? = nil) {
        self.appState = appState
    }
    
    func performFind() {
        guard !searchText.isEmpty else { return }
        NSApp.sendAction(#selector(NSTextView.performFindPanelAction(_:)),
                         to: nil,
                         from: FindPanelAction.showFindPanel.sender)
    }
    
    func findNext() {
        NSApp.sendAction(#selector(NSTextView.performFindPanelAction(_:)),
                         to: nil,
                         from: FindPanelAction.findNext.sender)
    }
    
    func findPrevious() {
        NSApp.sendAction(#selector(NSTextView.performFindPanelAction(_:)),
                         to: nil,
                         from: FindPanelAction.findPrevious.sender)
    }
    
    func performReplace() {
        NSApp.sendAction(#selector(NSTextView.performFindPanelAction(_:)),
                         to: nil,
                         from: FindPanelAction.replace.sender)
    }
    
    func performReplaceAll() {
        NSApp.sendAction(#selector(NSTextView.performFindPanelAction(_:)),
                         to: nil,
                         from: FindPanelAction.replaceAll.sender)
    }
}

enum FindPanelAction {
    case showFindPanel
    case findNext
    case findPrevious
    case replace
    case replaceAll
    
    var sender: FindPanelActionSender {
        switch self {
        case .showFindPanel:
            return FindPanelActionSender(actionTag: NSTextFinder.Action.showFindInterface.rawValue)
        case .findNext:
            return FindPanelActionSender(actionTag: NSTextFinder.Action.nextMatch.rawValue)
        case .findPrevious:
            return FindPanelActionSender(actionTag: NSTextFinder.Action.previousMatch.rawValue)
        case .replace:
            return FindPanelActionSender(actionTag: NSTextFinder.Action.replace.rawValue)
        case .replaceAll:
            return FindPanelActionSender(actionTag: NSTextFinder.Action.replaceAll.rawValue)
        }
    }
}

// SwiftUI Find Panel View
struct FindPanel: View {
    @ObservedObject var findManager: FindPanelManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Find field
            HStack {
                Text("Find:")
                    .frame(width: 60, alignment: .trailing)
                TextField("Search text", text: $findManager.searchText)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Replace field (if showing replace)
            if findManager.showReplacePanel {
                HStack {
                    Text("Replace:")
                        .frame(width: 60, alignment: .trailing)
                    TextField("Replace with", text: $findManager.replaceText)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            // Options
            HStack {
                Toggle("Case Sensitive", isOn: $findManager.caseSensitive)
                Toggle("Regular Expression", isOn: $findManager.useRegex)
            }
            
            // Buttons
            HStack {
                Button("Previous") {
                    findManager.findPrevious()
                }
                .disabled(findManager.searchText.isEmpty)
                
                Button("Next") {
                    findManager.findNext()
                }
                .disabled(findManager.searchText.isEmpty)
                
                if findManager.showReplacePanel {
                    Button("Replace") {
                        findManager.performReplace()
                    }
                    .disabled(findManager.searchText.isEmpty)
                    
                    Button("Replace All") {
                        findManager.performReplaceAll()
                    }
                    .disabled(findManager.searchText.isEmpty)
                }
                
                Button("Done") {
                    findManager.showFindPanel = false
                    findManager.showReplacePanel = false
                }
            }
        }
        .padding()
        .frame(width: 400)
    }
}

// Custom Find Panel Window
struct FindPanelWindow: View {
    @ObservedObject var findManager: FindPanelManager
    
    var body: some View {
        FindPanel(findManager: findManager)
            .frame(width: 400)
    }
}
