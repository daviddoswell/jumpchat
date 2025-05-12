import Foundation
import SwiftUI

@MainActor
class ChatStateManager: ObservableObject {
    @Published private(set) var currentConversation: Conversation
    @Published private(set) var state: ChatState = .idle
    
    private let chatService: ChatService
    
    init(chatService: ChatService) {
        self.chatService = chatService
        self.currentConversation = Conversation()
    }
    
    func sendMessage(_ text: String) async {
        guard !text.isEmpty else { return }
        
        state = .thinking
        let userMessage = Message(content: text, isUser: true)
        currentConversation.messages.append(userMessage)
        
        do {
            // Create a placeholder for the streaming response
            let responseId = UUID()
            currentConversation.messages.append(Message(id: responseId, content: "", isUser: false, isStreaming: true))
            
            // Start streaming
            state = .streaming
            for try await chunk in try await chatService.streamMessage(userMessage.content) {
                if let index = currentConversation.messages.firstIndex(where: { $0.id == responseId }) {
                    currentConversation.messages[index].content += chunk
                }
            }
            
            // Mark streaming as complete
            if let index = currentConversation.messages.firstIndex(where: { $0.id == responseId }) {
                currentConversation.messages[index].isStreaming = false
            }
            
            state = .idle
        } catch {
            state = .error(error.localizedDescription)
            currentConversation.messages.append(Message(content: "Error: \(error.localizedDescription)", isUser: false))
        }
    }
}
