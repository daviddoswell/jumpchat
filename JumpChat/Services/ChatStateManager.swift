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
        
        Task {
            // Just load conversations, don't restore last active
            await loadConversations()
        }
    }
    
    private func restoreState() async {
        do {
            // First load all conversations
            conversations = try storageService.loadAllConversations()
            
            // Then restore last active conversation
            if let lastActiveId = try storageService.loadLastActiveConversation(),
               let lastConversation = try storageService.loadConversation(id: lastActiveId) {
                currentConversation = lastConversation
            }
        } catch {
            print("Failed to restore state: \(error)")
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
            // Create a placeholder for streaming UI
            let responseId = UUID()
            var completeResponse = ""
            currentConversation.messages.append(Message(id: responseId, content: "", isUser: false, isStreaming: true))
            
            // Start streaming
            state = .streaming
            var isFirstToken = true
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            
            // Accumulate complete response while streaming
            for try await chunk in try await chatService.streamMessage(userMessage.content) {
                if let index = currentConversation.messages.firstIndex(where: { $0.id == responseId }) {
                    if isFirstToken {
                        feedbackGenerator.impactOccurred()
                        isFirstToken = false
                    }
                    completeResponse += chunk
                    currentConversation.messages[index].content = completeResponse
                }
            }
            
            // Replace streaming message with final complete message
            if let index = currentConversation.messages.firstIndex(where: { $0.id == responseId }) {
                currentConversation.messages[index] = Message(
                    id: responseId,
                    content: completeResponse,
                    isUser: false,
                    isStreaming: false
                )
                
                // Save only after we have the complete message
                try storageService.saveConversation(currentConversation)
                
                // Update conversations list
                if let listIndex = conversations.firstIndex(where: { $0.id == currentConversation.id }) {
                    conversations[listIndex] = currentConversation
                } else {
                    conversations.append(currentConversation)
                }
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
        
        // Save as last active
        do {
            try storageService.saveLastActiveConversation(id: conversation.id)
        } catch {
            print("Failed to save last active conversation: \(error)")
        }
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
