// Protocols/CompletionProvider.swift
import Foundation

protocol CompletionProvider {
    func getCompletions(context: CompletionContext) -> [CompletionSuggestion]
}
