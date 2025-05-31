import SwiftUI

struct StatusBar: View {
    @EnvironmentObject var appState: AppState // Add this line
    let characterCount: Int
    let wordCount: Int
    let lineNumber: Int
    let columnNumber: Int
    let selectedRange: NSRange?
    let encoding: String.Encoding
    // Removed: let currentProvider: AIProviderType
    
    // Click action handlers
    var onLineColumnClick: (() -> Void)?
    var onEncodingClick: (() -> Void)?
    
    // Add a UUID to force refresh when counts change
    @State private var refreshID = UUID()
    
    // Computed properties for formatting
    var formattedPosition: String {
        "Ln \(max(1, lineNumber)), Col \(max(1, columnNumber))"
    }
    
    var formattedSelection: String {
        guard let range = selectedRange, range.length > 0 else { return "" }
        return "Sel: \(range.length)"
    }
    
    var formattedEncoding: String {
        switch encoding {
        case .utf8:
            return "UTF-8"
        case .utf16:
            return "UTF-16"
        case .ascii:
            return "ASCII"
        case .isoLatin1:
            return "ISO Latin-1"
        case .macOSRoman:
            return "Mac OS Roman"
        case .windowsCP1252:
            return "Windows-1252"
        case .utf32:
            return "UTF-32"
        default:
            return "UTF-8"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Character and word count
            Text("Characters: \(characterCount)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Words: \(wordCount)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
                .frame(height: 12)
            
            // Line:Column position (clickable)
            Button(action: {
                onLineColumnClick?()
            }) {
                Text(formattedPosition)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            
            // Selection info (if any)
            if !formattedSelection.isEmpty {
                Divider()
                    .frame(height: 12)
                
                Text(formattedSelection)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Column Mode Indicator
            if appState.isColumnModeActive {
                Text("COL")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Divider()
                    .frame(height: 12)
            }

            // AI Status (Now using appState)
            // Consider if a Divider is needed here based on COL indicator's presence
            Text("AI: \(appState.aiManager.settings.currentProvider.displayName)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider() // Keep a divider before Encoding for consistent spacing
                .frame(height: 12)

            // Encoding (clickable)
            Button(action: {
                onEncodingClick?()
            }) {
                Text(formattedEncoding)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.regularMaterial)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .top
        )
        // Set a unique ID to ensure refreshes
        .id("statusbar_\(characterCount)_\(wordCount)_\(refreshID)")
        // Listen for document changes to update the status bar
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: .documentTextDidChange,
                object: nil,
                queue: .main
            ) { [self] _ in
                // Force refresh by updating the ID
                self.refreshID = UUID()
            }
            
            NotificationCenter.default.addObserver(
                forName: .documentStateDidChange,
                object: nil,
                queue: .main
            ) { [self] _ in
                // Force refresh by updating the ID
                self.refreshID = UUID()
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

// Preview
#Preview {
    VStack(spacing: 0) {
        StatusBar(
            characterCount: 123,
            wordCount: 25,
            lineNumber: 5,
            columnNumber: 15,
            selectedRange: nil,
            encoding: .utf8
            // currentProvider removed
        )
        .environmentObject(AppState()) // Add environmentObject
        .frame(width: 600)
        
        StatusBar(
            characterCount: 5432,
            wordCount: 876,
            lineNumber: 142,
            columnNumber: 37,
            selectedRange: NSRange(location: 100, length: 25),
            encoding: .utf16
            // currentProvider removed
        )
        .environmentObject(AppState()) // Add environmentObject
        .frame(width: 600)
    }
}
