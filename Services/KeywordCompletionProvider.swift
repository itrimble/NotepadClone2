// Services/KeywordCompletionProvider.swift
import Foundation

class KeywordCompletionProvider: CompletionProvider {
    private let keywordStore: [String: [String]]

    // Sample keywords, expand later
    init(keywordStore: [String: [String]] = [
        "swift": ["func", "var", "let", "class", "struct", "enum", "protocol", "if", "else", "for", "in", "while", "return", "import", "public", "private", "internal", "static", "extension"],
        "python": ["def", "class", "if", "else", "elif", "for", "in", "while", "return", "import", "from", "try", "except", "finally", "with", "as", "lambda", "yield", "pass", "break", "continue"],
        "javascript": ["function", "var", "let", "const", "class", "if", "else", "for", "while", "return", "import", "export", "try", "catch", "finally", "new", "this", "async", "await"],
        "html": ["html", "head", "title", "body", "div", "span", "p", "a", "img", "ul", "ol", "li", "table", "tr", "td", "th", "form", "input", "button", "script", "style", "link", "meta"],
        "css": ["color", "background-color", "font-size", "font-family", "width", "height", "margin", "padding", "border", "display", "position", "left", "right", "top", "bottom"]
    ]) {
        self.keywordStore = keywordStore
    }

    func getCompletions(context: CompletionContext) -> [CompletionSuggestion] {
        guard let keywords = keywordStore[context.languageIdentifier.lowercased()] else {
            return []
        }

        let prefix = context.currentWord.lowercased()
        return keywords.filter { keyword in
            keyword.lowercased().hasPrefix(prefix)
        }.map { keyword in
            CompletionSuggestion(displayText: keyword, insertionText: keyword, type: .keyword, description: "\(context.languageIdentifier.capitalized) keyword")
        }
    }
}
