// Services/DocumentWordCompletionProvider.swift
import Foundation

class DocumentWordCompletionProvider: CompletionProvider {
    func getCompletions(context: CompletionContext) -> [CompletionSuggestion] {
        let text = context.currentText
        let currentWordPrefix = context.currentWord.lowercased()

        // Basic word extraction: split by non-alphanumerics, could be improved
        let words = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
                            .filter { !$0.isEmpty && $0.count > 2 } // Min word length
                            .map { $0.lowercased() }

        let uniqueWords = Set(words)

        return uniqueWords.filter { word in
            word.hasPrefix(currentWordPrefix) && word != currentWordPrefix // Don't suggest the exact word being typed
        }.map { word in
            CompletionSuggestion(displayText: word, insertionText: word, type: .identifier, description: "Word from current document")
        }
    }
}
