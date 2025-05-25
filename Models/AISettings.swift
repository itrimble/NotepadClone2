//
//  AISettings.swift
//  NotepadClone
//
//  Created by [Your Name] on [Date].
//

import Foundation
import Combine

class AISettings: ObservableObject {
    @Published var ollamaEndpointURL: String {
        didSet {
            // Automatically save when the property changes
            saveOllamaEndpointURL(url: ollamaEndpointURL)
        }
    }

    @Published var openAIAPIKey: String = "" {
        didSet { saveOpenAIAPIKey(key: openAIAPIKey) }
    }
    @Published var anthropicAPIKey: String = "" {
        didSet { saveAnthropicAPIKey(key: anthropicAPIKey) }
    }

    // Model Names (could also be @AppStorage if preferred for direct SwiftUI binding in Prefs)
    @Published var openAIModelName: String = "gpt-3.5-turbo" {
        didSet { UserDefaults.standard.set(openAIModelName, forKey: openAIModelNameKey) }
    }
    @Published var anthropicModelName: String = "claude-3-haiku-20240307" {
        didSet { UserDefaults.standard.set(anthropicModelName, forKey: anthropicModelNameKey) }
    }
    // Add Ollama model name if it needs to be configurable here too
    @Published var ollamaModelName: String = "llama2" { // Default from OllamaService
        didSet { UserDefaults.standard.set(ollamaModelName, forKey: ollamaModelNameKey) }
    }

    @Published var preferredAIProvider: AIProviderType = .ollama {
        didSet { UserDefaults.standard.set(preferredAIProvider.rawValue, forKey: preferredAIProviderKey) }
    }


    private let ollamaEndpointURLKey = "ollamaEndpointURL"
    private let defaultOllamaEndpointURL = "http://localhost:11434"
    
    private let openAIAPIKeyKey = "openAIAPIKey"
    private let anthropicAPIKeyKey = "anthropicAPIKey"
    private let openAIModelNameKey = "openAIModelName"
    private let anthropicModelNameKey = "anthropicModelNameKey"
    private let ollamaModelNameKey = "ollamaModelNameKey"
    private let preferredAIProviderKey = "preferredAIProviderKey"


    init() {
        self.ollamaEndpointURL = "" // Initialize with empty, then load
        self.ollamaEndpointURL = loadOllamaEndpointURL()
        self.openAIAPIKey = loadOpenAIAPIKey()
        self.anthropicAPIKey = loadAnthropicAPIKey()
        
        self.openAIModelName = UserDefaults.standard.string(forKey: openAIModelNameKey) ?? "gpt-3.5-turbo"
        self.anthropicModelName = UserDefaults.standard.string(forKey: anthropicModelNameKey) ?? "claude-3-haiku-20240307"
        self.ollamaModelName = UserDefaults.standard.string(forKey: ollamaModelNameKey) ?? "llama2"
        
        if let savedProviderRawValue = UserDefaults.standard.string(forKey: preferredAIProviderKey),
           let savedProvider = AIProviderType(rawValue: savedProviderRawValue) {
            self.preferredAIProvider = savedProvider
        } else {
            self.preferredAIProvider = .ollama // Default
        }
    }

    func saveOllamaEndpointURL(url: String) {
        UserDefaults.standard.set(url, forKey: ollamaEndpointURLKey)
        // print("AISettings: Saved Ollama Endpoint URL - \(url)") // Reduce console noise
    }

    func loadOllamaEndpointURL() -> String {
        let savedURL = UserDefaults.standard.string(forKey: ollamaEndpointURLKey) ?? defaultOllamaEndpointURL
        // print("AISettings: Loaded Ollama Endpoint URL - \(savedURL)")
        return savedURL
    }
    
    func saveOpenAIAPIKey(key: String) {
        UserDefaults.standard.set(key, forKey: openAIAPIKeyKey)
        // print("AISettings: Saved OpenAI API Key.")
    }

    func loadOpenAIAPIKey() -> String {
        // print("AISettings: Loaded OpenAI API Key.")
        return UserDefaults.standard.string(forKey: openAIAPIKeyKey) ?? ""
    }

    func saveAnthropicAPIKey(key: String) {
        UserDefaults.standard.set(key, forKey: anthropicAPIKeyKey)
        // print("AISettings: Saved Anthropic API Key.")
    }

    func loadAnthropicAPIKey() -> String {
        // print("AISettings: Loaded Anthropic API Key.")
        return UserDefaults.standard.string(forKey: anthropicAPIKeyKey) ?? ""
    }

    // Convenience method to reset to default
    func resetOllamaEndpointURLToDefault() {
        self.ollamaEndpointURL = defaultOllamaEndpointURL
    }
    
    // Add reset methods for API keys if needed, e.g., for UI buttons
    func resetOpenAIAPIKey() {
        self.openAIAPIKey = ""
    }

    func resetAnthropicAPIKey() {
        self.anthropicAPIKey = ""
    }
    
    // Reset model names
    func resetOpenAIModelNameToDefault() {
        self.openAIModelName = "gpt-3.5-turbo"
    }
    
    func resetAnthropicModelNameToDefault() {
        self.anthropicModelName = "claude-3-haiku-20240307"
    }
    
    func resetOllamaModelNameToDefault() {
        self.ollamaModelName = "llama2"
    }

    func resetPreferredAIProviderToDefault() {
        self.preferredAIProvider = .ollama
    }
}
