//
//  AnthropicService.swift
//  NotepadClone
//
//  Created by [Your Name] on [Date].
//

import Foundation

class AnthropicService: AIService {
    private let apiKey: String
    private let modelName: String
    private let endpointURL: URL
    private let anthropicVersion = "2023-06-01"

    init(apiKey: String, modelName: String = "claude-3-haiku-20240307", customEndpointURL: String? = nil) throws {
        self.apiKey = apiKey
        self.modelName = modelName
        
        if let customURLString = customEndpointURL, !customURLString.isEmpty, let url = URL(string: customURLString) {
            self.endpointURL = url
        } else {
            guard let defaultURL = URL(string: "https://api.anthropic.com/v1/messages") else {
                throw AIServiceError.invalidURL // Should not happen
            }
            self.endpointURL = defaultURL
        }
        
        if apiKey.isEmpty {
            print("Warning: Anthropic API Key is empty.")
        }
    }

    func sendPrompt(_ prompt: String, completion: @escaping (Result<AIResponse, Error>) -> Void) {
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")

        let requestBody: [String: Any] = [
            "model": modelName,
            "max_tokens": 2048, // Or make this configurable
            "messages": [
                ["role": "user", "content": prompt]
            ]
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
                if let data = data, let errorResponse = try? JSONDecoder().decode(AnthropicErrorResponse.self, from: data) {
                    completion(.failure(AIServiceError.apiError(errorResponse.error.message)))
                } else {
                    completion(.failure(AIServiceError.apiError("Anthropic API Error: Status Code \(httpResponse.statusCode)")))
                }
                return
            }

            guard let data = data else {
                completion(.failure(AIServiceError.noData))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(AnthropicMessagesResponse.self, from: data)
                if let firstContent = decodedResponse.content.first, firstContent.type == "text" {
                    completion(.success(BasicAIResponse(content: firstContent.text)))
                } else {
                    completion(.failure(AIServiceError.apiError("No suitable text content found in response.")))
                }
            } catch {
                completion(.failure(AIServiceError.jsonParsingError(error)))
            }
        }
        task.resume()
    }
}

// Codable structs for Anthropic response parsing
struct AnthropicMessagesResponse: Codable {
    struct ContentBlock: Codable {
        let type: String
        let text: String
    }
    // Add other top-level fields like id, type, role, model, stop_reason, stop_sequence, usage if needed
    let content: [ContentBlock]
}

struct AnthropicErrorResponse: Codable {
    struct ErrorDetail: Codable {
        let type: String
        let message: String
    }
    let error: ErrorDetail
}
