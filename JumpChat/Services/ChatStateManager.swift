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
    
    private func generateConversationTitle(_ text: String) -> String {
        // Remove more question starters and filler words
        let starters = [
            "Can you", "Could you", "Please", "Help me",
            "I need", "How to", "What is", "How do I",
            "I want to", "Tell me about", "Explain",
            "Give me", "Show me"
        ].joined(separator: "|")
        
        let cleaned = text
            .replacingOccurrences(of: "^(\(starters)) ", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        // For very short messages, use them directly
        if cleaned.count <= 40 {
            return cleaned
        }
        
        // Look for natural breaks (end of first sentence or question)
        if let endIndex = cleaned.firstIndex(where: { ".!?".contains($0) }) {
            let sentence = String(cleaned[..<endIndex]).trimmingCharacters(in: .whitespaces)
            if sentence.count <= 50 {
                return sentence
            }
        }
        
        // If still too long, take first meaningful phrase
        let words = cleaned.split(separator: " ")
        let title = words.prefix(6).joined(separator: " ")
        return title.count < 40 ? title + "..." : title
    }
    
    func sendMessage(_ text: String) async {
        guard !text.isEmpty else { return }
        
        state = .thinking
        let userMessage = Message(content: text, isUser: true)
        currentConversation.messages.append(userMessage)
        
        // Update conversation title if it's the first message
        if currentConversation.messages.count == 1 {
            currentConversation.title = generateConversationTitle(text)
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
