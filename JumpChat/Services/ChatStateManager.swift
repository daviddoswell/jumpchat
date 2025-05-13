import Foundation
import SwiftUI

@MainActor
class ChatStateManager: ObservableObject {
    @Published private(set) var currentConversation: Conversation
    @Published private(set) var state: ChatState = .idle
    @Published private(set) var conversations: [Conversation] = []
    
    private let chatService: ChatService
    private let storageService: StorageService
    
    init(chatService: ChatService, storageService: StorageService) {
        self.chatService = chatService
        self.storageService = storageService
        self.currentConversation = Conversation()
        
        // Load conversations on init
        Task {
            await loadConversations()
        }
    }
    
    private func loadConversations() async {
        do {
            conversations = try storageService.loadAllConversations()
        } catch {
            print("Failed to load conversations: \(error)")
            conversations = []
        }
    }
    
    func sendMessage(_ text: String) async {
        guard !text.isEmpty else { return }
        
        state = .thinking
        let userMessage = Message(content: text, isUser: true)
        currentConversation.messages.append(userMessage)
        
        // Update conversation title if it's the first message
        if currentConversation.messages.count == 1 {
            currentConversation.title = text.prefix(50).description
        }
        
        currentConversation.updatedAt = Date()
        
        do {
            // Create a placeholder for the streaming response
            let responseId = UUID()
            currentConversation.messages.append(Message(id: responseId, content: "", isUser: false, isStreaming: true))
            
            // Start streaming
            state = .streaming
            var isFirstToken = true
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            
            for try await chunk in try await chatService.streamMessage(userMessage.content) {
                if let index = currentConversation.messages.firstIndex(where: { $0.id == responseId }) {
                    if isFirstToken {
                        feedbackGenerator.impactOccurred()
                        isFirstToken = false
                    }
                    currentConversation.messages[index].content = chunk // Use = instead of += since we're getting full text each time
                }
            }
            
            // Mark streaming as complete
            if let index = currentConversation.messages.firstIndex(where: { $0.id == responseId }) {
                currentConversation.messages[index].isStreaming = false
            }
            
            // Save conversation after response
            try storageService.saveConversation(currentConversation)
            
            // Update conversations list
            if let index = conversations.firstIndex(where: { $0.id == currentConversation.id }) {
                conversations[index] = currentConversation
            } else {
                conversations.append(currentConversation)
            }
            
            state = .idle
        } catch {
            state = .error(error.localizedDescription)
            currentConversation.messages.append(Message(content: "Error: \(error.localizedDescription)", isUser: false))
        }
    }
    
    func loadConversation(_ conversation: Conversation) {
        self.currentConversation = conversation
        state = .idle
    }
    
    func startNewConversation() {
        self.currentConversation = Conversation()
        state = .idle
    }
    
    func deleteConversation(_ conversation: Conversation) {
        do {
            try storageService.deleteConversation(id: conversation.id)
            conversations.removeAll(where: { $0.id == conversation.id })
            
            // If we deleted the current conversation, start a new one
            if currentConversation.id == conversation.id {
                startNewConversation()
            }
        } catch {
            print("Failed to delete conversation: \(error)")
        }
    }
}
