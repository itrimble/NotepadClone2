//
//  OllamaService.swift
//  NotepadClone
//
//  Created by [Your Name] on [Date].
//

import Foundation

class OllamaService: AIService {
    private let endpointURL: URL
    private let modelName: String // For now, hardcode or make configurable

    init(endpointURLString: String, modelName: String = "llama2") throws {
        guard let url = URL(string: endpointURLString) else {
            throw AIServiceError.invalidURL
        }
        self.endpointURL = url.appendingPathComponent("/api/generate") // Common Ollama endpoint
        self.modelName = modelName
    }

    func sendPrompt(_ prompt: String, completion: @escaping (Result<AIResponse, Error>) -> Void) {
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": modelName,
            "prompt": prompt,
            "stream": false // Non-streaming for now
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

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(AIServiceError.invalidResponse)) // Or a more specific HTTP error
                return
            }

            guard let data = data else {
                completion(.failure(AIServiceError.noData))
                return
            }

            do {
                // Define a struct for the expected Ollama response
                struct OllamaResponseData: Codable {
                    let model: String
                    let created_at: String // Or Date if you configure a decoder
                    let response: String
                    let done: Bool
                    // Add other fields if needed, like context, total_duration, etc.
                }

                let decodedResponse = try JSONDecoder().decode(OllamaResponseData.self, from: data)
                completion(.success(BasicAIResponse(content: decodedResponse.response)))
            } catch {
                completion(.failure(AIServiceError.jsonParsingError(error)))
            }
        }
        task.resume()
    }
}
