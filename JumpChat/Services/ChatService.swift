import Foundation
import OpenAISwift

protocol ChatService {
  func sendMessage(_ message: String) async throws -> String
  func streamMessage(_ message: String) async throws -> AsyncStream<String>
}

class OpenAIChatService: ChatService {
  private let client: OpenAISwift
  
  init(apiKey: String) {
    self.client = OpenAISwift(config: .makeDefaultOpenAI(apiKey: apiKey))
  }
  
  func sendMessage(_ message: String) async throws -> String {
    let messages = [ChatMessage(role: .user, content: message)]
    let response = try await client.sendChat(with: messages)
    return response.choices?.first?.message.content ?? ""
  }
  
  func streamMessage(_ message: String) async throws -> AsyncStream<String> {
    let messages = [ChatMessage(role: .user, content: message)]
    
    return AsyncStream<String> { continuation in
      Task {
        do {
          let response = try await client.sendChat(with: messages)
          if let content = response.choices?.first?.message.content {
            var currentText = ""
            // Stream word by word
            let words = content.split(separator: " ")
            for word in words {
              currentText += String(word) + " "
              continuation.yield(currentText)
              try await Task.sleep(nanoseconds: 50_000_000) // 0.05 second delay
            }
          }
        } catch {
          continuation.yield("Error: \(error.localizedDescription)")
        }
        continuation.finish()
      }
    }
  }
}
