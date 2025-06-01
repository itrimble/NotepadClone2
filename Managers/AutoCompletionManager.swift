// Managers/AutoCompletionManager.swift
import Foundation

class AutoCompletionManager {
    private var providers: [CompletionProvider]

    init(providers: [CompletionProvider] = []) {
        self.providers = providers
    }

    func registerProvider(_ provider: CompletionProvider) {
        providers.append(provider)
    }

    func fetchSuggestions(context: CompletionContext) -> [CompletionSuggestion] {
        var allSuggestions: [CompletionSuggestion] = []
        for provider in providers {
            allSuggestions.append(contentsOf: provider.getCompletions(context: context))
        }

        // De-duplicate (preferring first encountered, could be smarter later)
        var uniqueSuggestions: [CompletionSuggestion] = []
        var seenDisplayTexts = Set<String>()
        for suggestion in allSuggestions {
            if !seenDisplayTexts.contains(suggestion.displayText) {
                uniqueSuggestions.append(suggestion)
                seenDisplayTexts.insert(suggestion.displayText)
            }
        }

        // Sort (alphabetically for now)
        return uniqueSuggestions.sorted { $0.displayText.lowercased() < $1.displayText.lowercased() }
    }
}
