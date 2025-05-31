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

    func getAvailableProviders() -> [AIProviderType] {
        var available: [AIProviderType] = []

        // Check Ollama: For Ollama, we might assume it's available if the service could be initialized.
        // A more robust check could involve a quick ping to the endpoint, but for now,
        // let's assume if ollamaService is non-nil, it's potentially available.
        // Or, simply rely on the user to know if their local Ollama is running.
        // For simplicity in this step, we'll always list Ollama as an option,
        // as it doesn't require an API key. Errors will be handled at runtime if it's not reachable.
        // Considering the current setupServices logic, if ollamaService is non-nil, it means initialization
        // did not throw an error for invalid URL format, which is a basic check.
        if self.ollamaService != nil {
             available.append(.ollama)
        } else {
            // Fallback: always list Ollama as an option, user has to ensure it's running.
            // This might be preferable if initial setup fails due to network but Ollama could be started later.
            available.append(.ollama)
        }


        // Check OpenAI: Requires API key and successful service initialization.
        if openAIService != nil && !aiSettings.openAIAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            available.append(.openAI)
        }

        // Check Anthropic: Requires API key and successful service initialization.
        if anthropicService != nil && !aiSettings.anthropicAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            available.append(.anthropic)
        }

        // To ensure a consistent order and avoid duplicates if logic changes, convert to Set then back to Array.
        // However, the current logic should not produce duplicates.
        // For now, the order of appending determines the order.
        // A more sophisticated approach might sort them or prioritize the user's preferred provider.
        // Example: Sort alphabetically or by a predefined order.
        // For now, the order is: Ollama (if available), OpenAI (if available), Anthropic (if available).

        // Remove duplicates (if any, though current logic shouldn't create them) and maintain a defined order
        var uniqueAvailable: [AIProviderType] = []
        let allPossible: [AIProviderType] = [.ollama, .openAI, .anthropic] // Desired order

        for providerType in allPossible {
            if available.contains(providerType) && !uniqueAvailable.contains(providerType) {
                uniqueAvailable.append(providerType)
            }
        }

        // If for some reason all checks fail but there's a preferred provider set,
        // it might be good to still list it, but this could be confusing if it's truly unavailable.
        // For now, only list if checks pass.

        return uniqueAvailable.isEmpty ? [.ollama] : uniqueAvailable // Ensure at least Ollama is always an option as a fallback
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
