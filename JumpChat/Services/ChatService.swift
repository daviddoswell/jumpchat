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
    
    let (stream, continuation) = AsyncStream<String>.makeStream()
    
    Task {
      do {
        let response = try await client.sendChat(with: messages)
        if let content = response.choices?.first?.message.content {
          // For now, we'll simulate streaming by breaking the response into words
          let words = content.split(separator: " ")
          for word in words {
            continuation.yield(String(word) + " ")
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
          }
        }
      } catch {
        continuation.yield("Error: \(error.localizedDescription)")
      }
      continuation.finish()
    }
    
    return stream
  }
}
