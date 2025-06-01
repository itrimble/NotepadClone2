// Views/CompletionListView.swift
import SwiftUI

struct CompletionListView: View {
    let suggestions: [CompletionSuggestion]
    @Binding var selectedSuggestionId: UUID?
    let onSuggestionTap: (CompletionSuggestion) -> Void

    var body: some View {
        if !suggestions.isEmpty {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions) { suggestion in
                        CompletionRow(
                            suggestion: suggestion,
                            isSelected: selectedSuggestionId == suggestion.id,
                            onTap: {
                                onSuggestionTap(suggestion)
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 200) // Limit height
            .background(Color(NSColor.windowBackgroundColor)) // Use system background
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray.opacity(0.5), lineWidth: 1))
            .shadow(radius: 5)
            .padding(.top, 2) // Small padding from the cursor line
        } else {
            EmptyView()
        }
    }
}

struct CompletionRow: View {
    let suggestion: CompletionSuggestion
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            Text(suggestion.displayText)
                .font(.system(.body, design: .monospaced)) // Monospaced for code-like suggestions
                .lineLimit(1)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)

            Spacer()

            if let typeString = suggestion.type.rawValue.capitalized.first.map(String.init) {
                 Text(typeString) // Display 'K' for Keyword, 'I' for Identifier
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.trailing, 8)
            }
        }
        .background(isSelected ? Color.accentColor.opacity(0.7) : Color.clear)
        .foregroundColor(isSelected ? Color.white : Color(NSColor.textColor))
        .contentShape(Rectangle()) // Make the whole row tappable
        .onTapGesture {
            onTap()
        }
    }
}

// Preview for development
struct CompletionListView_Previews: PreviewProvider {
    @State static var selectedId: UUID? = mockSuggestions().first?.id

    static func mockSuggestions() -> [CompletionSuggestion] {
        return [
            CompletionSuggestion(displayText: "func", insertionText: "func", type: .keyword, description: "Keyword to define a function."),
            CompletionSuggestion(displayText: "functionCallExample", insertionText: "functionCallExample()", type: .identifier, description: "An example function call."),
            CompletionSuggestion(displayText: "forEachLoop", insertionText: "forEach { item in \n    // code\n}", type: .snippet, description: "A for each loop snippet.")
        ]
    }

    static func mockTap(suggestion: CompletionSuggestion) {
        print("Tapped: \(suggestion.displayText)")
        selectedId = suggestion.id
    }

    static var previews: some View {
        VStack {
            CompletionListView(
                suggestions: mockSuggestions(),
                selectedSuggestionId: $selectedId,
                onSuggestionTap: mockTap
            )
            .padding()

            Text("Selected ID: \(selectedId?.uuidString ?? "None")")
        }
        .frame(width: 300, height: 300)
    }
}
