//
//  OpenAIService.swift
//  NotepadClone
//
//  Created by [Your Name] on [Date].
//

import Foundation

class OpenAIService: AIService {
    private let apiKey: String
    private let modelName: String
    private let endpointURL: URL

    init(apiKey: String, modelName: String = "gpt-3.5-turbo", customEndpointURL: String? = nil) throws {
        self.apiKey = apiKey
        self.modelName = modelName

        if let customURLString = customEndpointURL, !customURLString.isEmpty, let url = URL(string: customURLString) {
            self.endpointURL = url
        } else {
            guard let defaultURL = URL(string: "https://api.openai.com/v1/chat/completions") else {
                throw AIServiceError.invalidURL // Should not happen with a hardcoded valid URL
            }
            self.endpointURL = defaultURL
        }
        
        if apiKey.isEmpty {
            // In a real app, you might throw an error or handle this more gracefully
            print("Warning: OpenAI API Key is empty.")
        }
    }

    func sendPrompt(_ prompt: String, completion: @escaping (Result<AIResponse, Error>) -> Void) {
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let requestBody: [String: Any] = [
            "model": modelName,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "stream": false // Non-streaming for simplicity
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(AIServiceError.jsonParsingError(error)))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(AIServiceError.networkError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AIServiceError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to parse error message from OpenAI if available
                if let data = data, let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                    completion(.failure(AIServiceError.apiError(errorResponse.error.message)))
                } else {
                    completion(.failure(AIServiceError.apiError("OpenAI API Error: Status Code \(httpResponse.statusCode)")))
                }
                return
            }

            guard let data = data else {
                completion(.failure(AIServiceError.noData))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(OpenAIChatCompletionResponse.self, from: data)
                if let firstChoice = decodedResponse.choices.first {
                    completion(.success(BasicAIResponse(content: firstChoice.message.content)))
                } else {
                    completion(.failure(AIServiceError.apiError("No response choices found.")))
                }
            } catch {
                completion(.failure(AIServiceError.jsonParsingError(error)))
            }
        }
        task.resume()
    }
}

// Codable structs for OpenAI response parsing
struct OpenAIChatCompletionResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
        let finish_reason: String?
    }
    let id: String?
    let object: String?
    let created: Int?
    let model: String
    let choices: [Choice]
    // Add usage statistics if needed: struct Usage: Codable { let prompt_tokens, completion_tokens, total_tokens: Int }
}

struct OpenAIErrorResponse: Codable {
    struct OpenAIError: Codable {
        let message: String
        let type: String?
        let param: String?
        let code: String?
    }
    let error: OpenAIError
}
