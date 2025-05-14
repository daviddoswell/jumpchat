import Foundation
import OpenAI

protocol ChatService {
    func sendMessage(_ message: String) async throws -> String
    func streamMessage(_ message: String) async throws -> AsyncThrowingStream<String, Error>
}

class OpenAIChatService: ChatService {
    private let client: OpenAI
    private let systemPrompt = """
        You are a helpful AI assistant that provides clear, accurate responses.
        Only use markdown formatting when specifically needed:
        - Use bullet points for lists
        - Use numbered lists for steps or sequences
        - Use bold for important terms or concepts
        - Use code blocks for code snippets
        - Use tables for structured data
        Otherwise, provide responses in plain text.
        Keep responses concise yet informative.
        """
    
    init(apiKey: String) {
        self.client = OpenAI(apiToken: apiKey)
    }
    
    func sendMessage(_ message: String) async throws -> String {
        guard NetworkUtils.isConnected() else {
            print("OpenAIChatService: Network unavailable for sendMessage.")
            throw NetworkError.offline
        }

        let query = ChatQuery(
            messages: [
                .init(role: .system, content: systemPrompt)!,
                .init(role: .user, content: message)!
            ],
            model: Model("gpt-4.1"),
            temperature: 0.7
        )
        
        do {
            let result = try await client.chats(query: query)
            return result.choices.first?.message.content ?? ""
        } catch let apiError as APIErrorResponse {
            print("OpenAIChatService: APIErrorResponse - \(apiError.error.message)")
            throw NetworkError.other(apiError.error.message)
        } catch {
            print("OpenAIChatService: sendMessage failed - \(error.localizedDescription)")
            if !NetworkUtils.isConnected() {
                throw NetworkError.offline
            }
            throw error
        }
    }
    
    func streamMessage(_ message: String) async throws -> AsyncThrowingStream<String, Error> {
        guard NetworkUtils.isConnected() else {
            print("OpenAIChatService: Network unavailable for streamMessage.")
            throw NetworkError.offline
        }

        let query = ChatQuery(
            messages: [
                .init(role: .system, content: systemPrompt)!,
                .init(role: .user, content: message)!
            ],
            model: Model("gpt-4.1"), // Ensure this model is appropriate
            temperature: 0.7,
            stream: true
        )
        
        let sourceStream: AsyncThrowingStream<ChatStreamResult, Error> = client.chatsStream(query: query)
        // If there's an issue with `query` that the OpenAI library detects synchronously
        // before returning the stream, and it doesn't throw, then the stream itself
        // would likely yield an error immediately upon iteration, which the Task below handles.

        return AsyncThrowingStream<String, Error> { continuation in
            Task {
                // Re-check network before starting the actual stream processing loop
                guard NetworkUtils.isConnected() else {
                    continuation.finish(throwing: NetworkError.offline)
                    return
                }
                
                do {
                    for try await result in sourceStream {
                        if let content = result.choices.first?.delta.content {
                            continuation.yield(content)
                        }
                    }
                    continuation.finish() // Successful completion
                } catch let apiError as APIErrorResponse {
                    print("OpenAIChatService: streamMessage APIErrorResponse during streaming - \(apiError.error.message)")
                    continuation.finish(throwing: NetworkError.other(apiError.error.message))
                } catch {
                    print("OpenAIChatService: streamMessage failed during streaming - \(error.localizedDescription)")
                    if !NetworkUtils.isConnected() { // Check if network dropped during stream
                        continuation.finish(throwing: NetworkError.offline)
                    } else {
                        continuation.finish(throwing: error)
                    }
                }
            }
        }
    }
}
