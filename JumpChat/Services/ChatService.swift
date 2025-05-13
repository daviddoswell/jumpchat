import Foundation
import OpenAI

protocol ChatService {
    func sendMessage(_ message: String) async throws -> String
    func streamMessage(_ message: String) async throws -> AsyncStream<String>
}

class OpenAIChatService: ChatService {
    private let client: OpenAI
    private let systemPrompt = """
        You are a helpful AI assistant that provides clear, accurate, and well-structured responses.
        Format your responses using markdown when appropriate for better readability.
        Keep responses concise yet informative.
        """
    
    init(apiKey: String) {
        self.client = OpenAI(apiToken: apiKey)
    }
    
    func sendMessage(_ message: String) async throws -> String {
        let query = ChatQuery(
            messages: [
                .init(role: .system, content: systemPrompt)!,
                .init(role: .user, content: message)!
            ],
            model: Model("gpt-4.1"),
            temperature: 0.7
        )
        
        let result = try await client.chats(query: query)
        return result.choices[0].message.content ?? ""
    }
    
    func streamMessage(_ message: String) async throws -> AsyncStream<String> {
        let query = ChatQuery(
            messages: [
                .init(role: .system, content: systemPrompt)!,
                .init(role: .user, content: message)!
            ],
            model: Model("gpt-4.1"),
            temperature: 0.7,
            stream: true
        )
        
        return AsyncStream { continuation in
            Task {
                do {
                    var fullResponse = ""
                    for try await result in client.chatsStream(query: query) {
                        if let content = result.choices[0].delta.content {
                            fullResponse += content
                            continuation.yield(fullResponse)
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
