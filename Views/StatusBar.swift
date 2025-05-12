import SwiftUI

struct StatusBar: View {
    let characterCount: Int
    let wordCount: Int
    
    // Add a UUID to force refresh when counts change
    @State private var refreshID = UUID()
    
    var body: some View {
        HStack {
            Text("Characters: \(characterCount)  Words: \(wordCount)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
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
    StatusBar(characterCount: 123, wordCount: 25)
        .frame(width: 400)
}
