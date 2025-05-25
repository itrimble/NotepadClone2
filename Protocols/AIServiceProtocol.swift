//
//  AIServiceProtocol.swift
//  NotepadClone
//
//  Created by [Your Name] on [Date].
//

import Foundation

protocol AIResponse {
    var content: String { get }
    // Add other common response fields if necessary, e.g., errorInfo, successStatus
}

protocol AIService {
    func sendPrompt(_ prompt: String, completion: @escaping (Result<AIResponse, Error>) -> Void)
}

struct BasicAIResponse: AIResponse {
    var content: String
}

// Custom Error for AI Services
enum AIServiceError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case jsonParsingError(Error)
    case noData
    case apiError(String) // For errors returned by the API itself
}

// Enum for AI Provider Types
enum AIProviderType: String, CaseIterable, Identifiable {
    case ollama = "Ollama"
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .ollama: return "Ollama (Local)"
        case .openAI: return "OpenAI (Cloud)"
        case .anthropic: return "Anthropic Claude (Cloud)"
        }
    }
}
