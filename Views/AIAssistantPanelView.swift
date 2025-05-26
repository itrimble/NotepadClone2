//
//  AIAssistantPanelView.swift
//  NotepadClone
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct AIAssistantPanelView: View {
    @EnvironmentObject var aiManager: AIManager
    @State private var promptText: String = ""
    // isLoading and responseText will now be driven by aiManager's @Published properties

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI Assistant")
                .font(.headline)
                .padding(.bottom, 4)

            // Prompt Input Area
            Text("Enter your prompt:")
                .font(.subheadline)
            TextEditor(text: $promptText)
                .frame(height: 100)
                .border(Color.gray.opacity(0.5), width: 1)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            // Submit Button & Progress Indicator
            HStack {
                Button(action: {
                    guard !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    
                    // No need to set isLoading or responseText here directly,
                    // as these will be updated by AIManager's @Published properties.
                    
                    aiManager.submitPrompt(prompt: promptText) { result in
                        // The completion handler in AIManager updates its @Published properties.
                        // This view will react to those changes.
                        // We can log here or perform UI actions specific to this panel's submission event.
                        if case .failure(let error) = result {
                            print("AIAssistantPanelView: Submit failed from panel: \(error.localizedDescription)")
                        }
                    }
                }) {
                    Text("Submit Prompt")
                }
                .disabled(aiManager.isProcessing || promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if aiManager.isProcessing {
                    ProgressView()
                        .padding(.leading, 10)
                }
                Spacer() // Pushes button and indicator to the left
            }

            // Response Area
            Text("Response:")
                .font(.subheadline)
            ScrollView {
                TextEditor(text: .constant(aiManager.latestResponseContent)) // Bind to AIManager's property
                    .frame(minHeight: 100, idealHeight: 150) // Allow expansion
                    .border(Color.gray.opacity(0.5), width: 1)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .foregroundColor(aiManager.isProcessing ? .gray : .primary) // Use AIManager's processing state
            }
            
            Spacer() // Pushes content to the top
        }
        .padding()
        .frame(minHeight: 300, maxHeight: .infinity) // Give panel a decent default size
    }
}

struct AIAssistantPanelView_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock AISettings and AIManager for preview
        let mockAISettings = AISettings()
        let mockAIManager = AIManager(aiSettings: mockAISettings)
        
        // Example of how to provide default values for preview if needed
        // mockAIManager.lastResponse = BasicAIResponse(content: "This is a sample response for preview.")
        
        AIAssistantPanelView()
            .environmentObject(mockAIManager)
            .frame(width: 350) // Typical sidebar width
    }
}
