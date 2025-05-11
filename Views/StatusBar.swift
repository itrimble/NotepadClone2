import SwiftUI

struct StatusBar: View {
    let characterCount: Int
    let wordCount: Int
    
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
    }
}
