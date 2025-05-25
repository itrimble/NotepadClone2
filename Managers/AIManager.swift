//
//  AIManager.swift
//  NotepadClone
//
//  Created by [Your Name] on [Date].
//

import Foundation
import Combine

class AIManager: ObservableObject {
    @ObservedObject var aiSettings: AISettings
    
    private var ollamaService: OllamaService?
    private var openAIService: OpenAIService?
    private var anthropicService: AnthropicService?

    @Published var currentProviderType: AIProviderType {
        didSet {
            if oldValue != currentProviderType && aiSettings.preferredAIProvider != currentProviderType {
                 aiSettings.preferredAIProvider = currentProviderType
            }
            print("AIManager: Provider type changed to \(currentProviderType.displayName)")
            // Clear states when provider changes
            isProcessing = false
            latestResponseContent = "" // Clear content when provider changes
            lastError = nil
        }
    }

    // For UI binding
    @Published var isProcessing: Bool = false
    @Published var latestResponseContent: String = ""
    @Published var lastError: Error? // Keep lastError for specific error messages
    
    // Internal tracking of last full response if needed for other purposes
    private var lastFullResponse: AIResponse?
    
    private var cancellables = Set<AnyCancellable>()

    init(aiSettings: AISettings) {
        self.aiSettings = aiSettings
        self.currentProviderType = aiSettings.preferredAIProvider 
        
        setupServices()
        setupBindings()
    }

    private func setupServices() {
        setupOllamaService()
        setupOpenAIService()
        setupAnthropicService()
    }
    
    private func setupBindings() {
        // Subscribe to changes in AISettings that require service re-initialization
        aiSettings.$ollamaEndpointURL
            .dropFirst() // Ignore initial value
            .sink { [weak self] _ in 
                print("AIManager: Ollama endpoint changed. Re-initializing OllamaService.")
                self?.setupOllamaService() 
            }
            .store(in: &cancellables)
            
        aiSettings.$ollamaModelName
            .dropFirst()
            .sink { [weak self] _ in 
                print("AIManager: Ollama model name changed. Re-initializing OllamaService.")
                self?.setupOllamaService() 
            }
            .store(in: &cancellables)

        aiSettings.$openAIAPIKey
            .dropFirst()
            .sink { [weak self] _ in 
                print("AIManager: OpenAI API key changed. Re-initializing OpenAIService.")
                self?.setupOpenAIService() 
            }
            .store(in: &cancellables)
            
        aiSettings.$openAIModelName
            .dropFirst()
            .sink { [weak self] _ in 
                print("AIManager: OpenAI model name changed. Re-initializing OpenAIService.")
                self?.setupOpenAIService() 
            }
            .store(in: &cancellables)

        aiSettings.$anthropicAPIKey
            .dropFirst()
            .sink { [weak self] _ in 
                print("AIManager: Anthropic API key changed. Re-initializing AnthropicService.")
                self?.setupAnthropicService() 
            }
            .store(in: &cancellables)
            
        aiSettings.$anthropicModelName
            .dropFirst()
            .sink { [weak self] _ in 
                print("AIManager: Anthropic model name changed. Re-initializing AnthropicService.")
                self?.setupAnthropicService() 
            }
            .store(in: &cancellables)
            
        // Subscribe to changes in preferredAIProvider from AISettings
        aiSettings.$preferredAIProvider
            .dropFirst() // Ignore initial value if already set
            .receive(on: DispatchQueue.main) // Ensure UI updates on main thread
            .assign(to: \.currentProviderType, on: self)
            .store(in: &cancellables)
    }

    private func setupOllamaService() {
        do {
            print("AIManager: Setting up OllamaService with endpoint: \(aiSettings.ollamaEndpointURL), model: \(aiSettings.ollamaModelName)")
            self.ollamaService = try OllamaService(endpointURLString: aiSettings.ollamaEndpointURL, modelName: aiSettings.ollamaModelName)
            print("AIManager: OllamaService setup successful.")
        } catch {
            self.ollamaService = nil
            print("AIManager: Failed to setup OllamaService. Error: \(error)")
        }
    }

    private func setupOpenAIService() {
        do {
            print("AIManager: Setting up OpenAIService with model: \(aiSettings.openAIModelName)")
            self.openAIService = try OpenAIService(apiKey: aiSettings.openAIAPIKey, modelName: aiSettings.openAIModelName)
            print("AIManager: OpenAIService setup successful.")
        } catch {
            self.openAIService = nil
            print("AIManager: Failed to setup OpenAIService. Error: \(error)")
        }
    }

    private func setupAnthropicService() {
        do {
            print("AIManager: Setting up AnthropicService with model: \(aiSettings.anthropicModelName)")
            self.anthropicService = try AnthropicService(apiKey: aiSettings.anthropicAPIKey, modelName: aiSettings.anthropicModelName)
            print("AIManager: AnthropicService setup successful.")
        } catch {
            self.anthropicService = nil
            print("AIManager: Failed to setup AnthropicService. Error: \(error)")
        }
    }

    func submitPrompt(prompt: String, completion: @escaping (Result<AIResponse, Error>) -> Void) {
        print("AIManager: Submitting prompt using \(currentProviderType.displayName).")
        
        let service: AIService?
        var serviceNameForError = currentProviderType.displayName

        // Re-check and re-initialize service if parameters have changed or service is nil
        switch currentProviderType {
        case .ollama:
            if ollamaService == nil || 
               ollamaService?.endpointURL.absoluteString != aiSettings.ollamaEndpointURL + "/api/generate" || // OllamaService appends /api/generate
               ollamaService?.modelName != aiSettings.ollamaModelName {
                 print("AIManager: OllamaService is not configured correctly or parameters mismatch. Re-initializing.")
                 setupOllamaService()
            }
            service = ollamaService
            serviceNameForError = "Ollama"
        case .openAI:
            if openAIService == nil || 
               openAIService?.apiKey != aiSettings.openAIAPIKey || 
               openAIService?.modelName != aiSettings.openAIModelName {
                 print("AIManager: OpenAIService is not configured correctly or parameters mismatch. Re-initializing.")
                 setupOpenAIService()
            }
            service = openAIService
            serviceNameForError = "OpenAI"
        case .anthropic:
            if anthropicService == nil || 
               anthropicService?.apiKey != aiSettings.anthropicAPIKey || 
               anthropicService?.modelName != aiSettings.anthropicModelName {
                 print("AIManager: AnthropicService is not configured correctly or parameters mismatch. Re-initializing.")
                 setupAnthropicService()
            }
            service = anthropicService
            serviceNameForError = "Anthropic"
        }
        
        guard let activeService = service else {
            let error = AIServiceError.apiError("\(serviceNameForError) service is not configured. Check AI Preferences.")
            DispatchQueue.main.async {
                self.isProcessing = false
                self.latestResponseContent = error.localizedDescription
                self.lastError = error
            }
            completion(.failure(error))
            return
        }

        DispatchQueue.main.async {
            self.isProcessing = true
            self.latestResponseContent = "Processing..." 
            self.lastError = nil
        }

        activeService.sendPrompt(prompt) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isProcessing = false
                switch result {
                case .success(let response):
                    self.lastFullResponse = response
                    self.latestResponseContent = response.content
                    self.lastError = nil
                    print("AIManager: Received success response from \(self.currentProviderType.displayName).")
                case .failure(let error):
                    self.lastFullResponse = nil
                    let errorMessage: String
                    if let aiError = error as? AIServiceError {
                        switch aiError {
                        case .invalidURL: errorMessage = "Error: Invalid API Endpoint URL."
                        case .networkError(let netErr): errorMessage = "Error: Network - \(netErr.localizedDescription)"
                        case .invalidResponse: errorMessage = "Error: Invalid server response."
                        case .jsonParsingError: errorMessage = "Error: Cannot understand server response."
                        case .noData: errorMessage = "Error: No data from server."
                        case .apiError(let msg): errorMessage = "API Error: \(msg)"
                        }
                    } else {
                        errorMessage = "Error: \(error.localizedDescription)"
                    }
                    self.latestResponseContent = errorMessage
                    self.lastError = error 
                    print("AIManager: Received error from \(self.currentProviderType.displayName): \(error)")
                }
                completion(result)
            }
        }
    }
}
