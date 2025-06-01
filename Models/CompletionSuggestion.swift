// Models/CompletionSuggestion.swift
import Foundation

enum SuggestionType: String, CaseIterable {
    case keyword
    case identifier
    case snippet // For future use
}

struct CompletionSuggestion: Identifiable, Hashable {
    let id = UUID()
    var displayText: String
    var insertionText: String
    var type: SuggestionType
    var description: String? = nil // e.g., "A keyword for defining a function"

    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CompletionSuggestion, rhs: CompletionSuggestion) -> Bool {
        lhs.id == rhs.id
    }
}
