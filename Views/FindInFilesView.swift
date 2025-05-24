import SwiftUI
import AppKit

struct FindInFilesView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var findInFilesManager = FindInFilesManager()
    
    @State private var searchText = ""
    @State private var searchPath = ""
    @State private var caseSensitive = false
    @State private var useRegex = false
    @State private var fileExtensions = ""
    @State private var excludePatterns = ""
    @State private var selectedResult: SearchResult?
    
    var body: some View {
        VStack(spacing: 0) {
            // Search controls
            searchControlsView
                .padding()
                .background(Color(appState.appTheme.tabBarBackgroundColor()))
            
            Divider()
            
            // Results area
            if findInFilesManager.isSearching {
                searchingView
            } else if findInFilesManager.searchResults.isEmpty {
                emptyStateView
            } else {
                resultsListView
            }
        }
        .frame(minWidth: 400, idealWidth: 600, minHeight: 300, idealHeight: 500)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Search Controls
    
    private var searchControlsView: some View {
        VStack(spacing: 12) {
            // Search text field
            HStack {
                Text("Find:")
                    .frame(width: 60, alignment: .trailing)
                TextField("Search text", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        performSearch()
                    }
            }
            
            // Search path
            HStack {
                Text("In:")
                    .frame(width: 60, alignment: .trailing)
                TextField("Directory path", text: $searchPath)
                    .textFieldStyle(.roundedBorder)
                Button("Browse...") {
                    selectDirectory()
                }
            }
            
            // Options row 1
            HStack {
                Text("Options:")
                    .frame(width: 60, alignment: .trailing)
                Toggle("Case Sensitive", isOn: $caseSensitive)
                Toggle("Regular Expression", isOn: $useRegex)
                    .padding(.leading, 20)
                Spacer()
            }
            
            // Options row 2
            HStack {
                Text("Filter:")
                    .frame(width: 60, alignment: .trailing)
                TextField("File extensions (e.g., swift,txt)", text: $fileExtensions)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)
                Text("Exclude:")
                TextField("Patterns to exclude", text: $excludePatterns)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)
            }
            
            // Action buttons
            HStack {
                Button("Search") {
                    performSearch()
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(searchText.isEmpty || searchPath.isEmpty || findInFilesManager.isSearching)
                
                if findInFilesManager.isSearching {
                    Button("Cancel") {
                        findInFilesManager.cancelSearch()
                    }
                } else {
                    Button("Clear") {
                        clearSearch()
                    }
                    .disabled(findInFilesManager.searchResults.isEmpty)
                }
                
                Spacer()
                
                if !findInFilesManager.searchResults.isEmpty {
                    Text("\(findInFilesManager.searchResults.count) results")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
    }
    
    // MARK: - Results Views
    
    private var searchingView: some View {
        VStack(spacing: 16) {
            ProgressView(value: findInFilesManager.searchProgress)
                .progressViewStyle(.linear)
                .frame(width: 300)
            
            Text("Searching...")
                .font(.headline)
            
            Text(findInFilesManager.currentSearchPath)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No results")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Enter search criteria and click Search")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var resultsListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(findInFilesManager.searchResults) { result in
                    ResultItemView(result: result, searchText: searchText)
                        .onTapGesture {
                            openResult(result)
                        }
                        .background(selectedResult?.id == result.id ? 
                                  Color.accentColor.opacity(0.2) : Color.clear)
                    
                    Divider()
                        .padding(.leading, 20)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func performSearch() {
        guard !searchText.isEmpty, !searchPath.isEmpty else { return }
        
        let searchURL = URL(fileURLWithPath: searchPath.expandingTildeInPath)
        
        var options = SearchOptions()
        options.caseSensitive = caseSensitive
        options.useRegex = useRegex
        
        if !fileExtensions.isEmpty {
            options.fileExtensions = fileExtensions
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        
        if !excludePatterns.isEmpty {
            options.excludePatterns = excludePatterns
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        
        Task {
            await findInFilesManager.performAsyncSearch(for: searchText, in: searchURL, options: options)
        }
    }
    
    private func clearSearch() {
        findInFilesManager.clearResults()
        selectedResult = nil
    }
    
    private func selectDirectory() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = false
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            searchPath = url.path
        }
    }
    
    private func openResult(_ result: SearchResult) {
        selectedResult = result
        
        // Open file in editor
        appState.openDocument(at: result.file)
        
        // Jump to line after a short delay to ensure document is loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            jumpToLine(result.lineNumber)
        }
    }
    
    private func jumpToLine(_ lineNumber: Int) {
        // Send notification to jump to specific line
        NotificationCenter.default.post(
            name: .jumpToLine,
            object: nil,
            userInfo: ["lineNumber": lineNumber]
        )
    }
}

// MARK: - Result Item View

struct ResultItemView: View {
    let result: SearchResult
    let searchText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // File path and line number
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text(result.displayPath)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(":\(result.lineNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            // Context lines
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(result.contextLines.enumerated()), id: \.offset) { index, line in
                    HStack(spacing: 8) {
                        // Line indicator
                        if line.hasPrefix(">") {
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: 3)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 3)
                        }
                        
                        // Line content with highlighting
                        if line.hasPrefix(">") {
                            highlightedText(line.dropFirst(2), searchText: searchText)
                                .font(.system(.caption, design: .monospaced))
                        } else {
                            Text(line)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .contentShape(Rectangle())
        .onHover { isHovering in
            if isHovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
    
    private func highlightedText(_ text: String, searchText: String) -> some View {
        let attributedString = NSMutableAttributedString(string: String(text))
        
        // Find and highlight search text
        let searchRange = NSRange(location: 0, length: attributedString.length)
        let regex = try? NSRegularExpression(
            pattern: NSRegularExpression.escapedPattern(for: searchText),
            options: .caseInsensitive
        )
        
        if let matches = regex?.matches(in: String(text), options: [], range: searchRange) {
            for match in matches {
                attributedString.addAttribute(
                    .backgroundColor,
                    value: NSColor.systemYellow.withAlphaComponent(0.5),
                    range: match.range
                )
                attributedString.addAttribute(
                    .foregroundColor,
                    value: NSColor.labelColor,
                    range: match.range
                )
            }
        }
        
        // Convert to SwiftUI Text
        return Text(AttributedString(attributedString))
    }
}

// String extension for tilde expansion
extension String {
    var expandingTildeInPath: String {
        return (self as NSString).expandingTildeInPath
    }
}

// Preview
#Preview {
    FindInFilesView()
        .environmentObject(AppState())
        .frame(width: 600, height: 500)
}