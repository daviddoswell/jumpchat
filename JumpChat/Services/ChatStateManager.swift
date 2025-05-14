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
            await restoreState()
        }
    }
    
    private func restoreState() async {
        do {
            self.conversations = try storageService.loadAllConversations()
            
            if let lastActiveId = try storageService.loadLastActiveConversation(),
               let lastConversation = try storageService.loadConversation(id: lastActiveId) {
                currentConversation = lastConversation
            }
        } catch {
            print("Failed to restore state: \(error)")
            // Consider setting a default state or error state if restoration fails critically
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
        let starters = [
            "Can you", "Could you", "Please", "Help me",
            "I need", "How to", "What is", "How do I",
            "I want to", "Tell me about", "Explain",
            "Give me", "Show me"
        ].joined(separator: "|")
        
        let cleaned = text
            .replacingOccurrences(of: "^(\(starters)) ", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        if cleaned.count <= 40 {
            return cleaned
        }
        
        if let endIndex = cleaned.firstIndex(where: { ".!?".contains($0) }) {
            let sentence = String(cleaned[..<endIndex]).trimmingCharacters(in: .whitespaces)
            if sentence.count <= 50 {
                return sentence
            }
        }
        
        let words = cleaned.split(separator: " ")
        let title = words.prefix(6).joined(separator: " ")
        return title.count < 40 ? title + "..." : title
    }
    
    func sendMessage(_ text: String) async {
        guard !text.isEmpty else { return }

        guard NetworkUtils.isConnected() else {
            state = .error("You appear to be offline. Please check your connection.")
            if case .thinking = state { state = .idle }
            return
        }
        
        state = .thinking
        let userMessage = Message(content: text, isUser: true)
        currentConversation.messages.append(userMessage)
        
        if currentConversation.messages.count == 1 {
            currentConversation.title = generateConversationTitle(text)
        }
        
        currentConversation.updatedAt = Date()
        
        var responseId: UUID? = nil
        
        do {
            let newResponseId = UUID()
            responseId = newResponseId
            var completeResponse = ""
            currentConversation.messages.append(Message(id: newResponseId, content: "", isUser: false, isStreaming: true))
            
            state = .streaming
            var isFirstToken = true
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            
            for try await chunk in try await chatService.streamMessage(userMessage.content) {
                if let index = currentConversation.messages.firstIndex(where: { $0.id == newResponseId }) {
                    if isFirstToken {
                        feedbackGenerator.impactOccurred()
                        isFirstToken = false
                    }
                    completeResponse += chunk
                    currentConversation.messages[index].content = completeResponse
                }
            }
            
            if let index = currentConversation.messages.firstIndex(where: { $0.id == newResponseId }) {
                currentConversation.messages[index] = Message(
                    id: newResponseId,
                    content: completeResponse,
                    isUser: false,
                    isStreaming: false
                )
                try storageService.saveConversation(currentConversation)
                if let listIndex = conversations.firstIndex(where: { $0.id == currentConversation.id }) {
                    conversations[listIndex] = currentConversation
                } else {
                    conversations.append(currentConversation)
                }
            }
            state = .idle
        } catch let error as NetworkError {
            switch error {
            case .offline:
                state = .error("Operation failed: Network connection lost.")
            case .timeout:
                state = .error("Operation timed out. Please try again.")
            case .other(let underlyingErrorMessage):
                state = .error("Network error: \(underlyingErrorMessage)")
            }
            if let placeholderId = responseId, let index = currentConversation.messages.firstIndex(where: { $0.id == placeholderId }) {
                currentConversation.messages.remove(at: index)
            }
        } catch {
            state = .error("An error occurred: \(error.localizedDescription)")
            if let placeholderId = responseId, let index = currentConversation.messages.firstIndex(where: { $0.id == placeholderId }) {
                currentConversation.messages.remove(at: index)
            }
        }
    }
    
    func rateMessage(_ message: Message, rating: MessageRating) {
        if let index = currentConversation.messages.firstIndex(where: { $0.id == message.id }) {
            if currentConversation.messages[index].rating == rating {
                currentConversation.messages[index].rating = nil
            } else {
                currentConversation.messages[index].rating = rating
            }
            
            do {
                try storageService.saveConversation(currentConversation)
                
                if let listIndex = conversations.firstIndex(where: { $0.id == currentConversation.id }) {
                    conversations[listIndex] = currentConversation
                }
            } catch {
                print("Failed to save message rating: \(error)")
            }
        }
    }
    
    func loadConversation(_ conversation: Conversation) {
        withAnimation {
            currentConversation = conversation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.state = .idle
            }
        }
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
            
            if currentConversation.id == conversation.id {
                startNewConversation()
            }
        } catch {
            print("Failed to delete conversation: \(error)")
        }
    }
    
    func regenerateResponse(for message: Message) async {
        print("Starting regeneration for message: \(message.id)")

        guard NetworkUtils.isConnected() else {
            state = .error("Cannot regenerate: You appear to be offline.")
            if case .thinking = state { state = .idle }
            return
        }
        
        guard case .idle = state else {
            print("Can't regenerate - state is not idle: \(state)")
            return
        }
        
        guard let index = currentConversation.messages.firstIndex(where: { $0.id == message.id }) else {
            print("Message not found in conversation")
            return
        }
        
        guard index > 0, currentConversation.messages[index - 1].isUser else {
            print("No user message found before this message")
            return
        }
        
        let userMessageToRegenerate = currentConversation.messages[index - 1]
        let originalAiMessageId = message.id
        
        currentConversation.messages.removeAll(where: { $0.id == originalAiMessageId })
        
        var newResponseId: UUID? = nil
        
        await MainActor.run { state = .thinking }
        
        do {
            let tempResponseId = UUID()
            newResponseId = tempResponseId
            var completeResponse = ""
            
            await MainActor.run {
                currentConversation.messages.append(Message(id: tempResponseId, content: "", isUser: false, isStreaming: true))
            }
            
            await MainActor.run { state = .streaming }
            
            var isFirstToken = true
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            feedbackGenerator.prepare()
            
            for try await chunk in try await chatService.streamMessage(userMessageToRegenerate.content) {
                await MainActor.run {
                    if let streamIndex = currentConversation.messages.firstIndex(where: { $0.id == tempResponseId }) {
                        if isFirstToken {
                            feedbackGenerator.impactOccurred()
                            isFirstToken = false
                        }
                        completeResponse += chunk
                        currentConversation.messages[streamIndex].content = completeResponse
                    }
                }
            }
            
            await MainActor.run {
                if let streamIndex = currentConversation.messages.firstIndex(where: { $0.id == tempResponseId }) {
                    currentConversation.messages[streamIndex] = Message(
                        id: tempResponseId,
                        content: completeResponse,
                        isUser: false,
                        isStreaming: false
                    )
                }
                do {
                    try storageService.saveConversation(currentConversation)
                    if let listIndex = conversations.firstIndex(where: { $0.id == currentConversation.id }) {
                        conversations[listIndex] = currentConversation
                    }
                } catch {
                    print("Failed to save regenerated conversation: \(error)")
                }
                state = .idle
            }
        } catch let error as NetworkError {
            await MainActor.run {
                switch error {
                case .offline:
                    state = .error("Regeneration failed: Network connection lost.")
                case .timeout:
                    state = .error("Regeneration timed out. Please try again.")
                case .other(let underlyingErrorMessage):
                    state = .error("Network error during regeneration: \(underlyingErrorMessage)")
                }
                if let placeholderId = newResponseId, let placeholderIndex = currentConversation.messages.firstIndex(where: { $0.id == placeholderId }) {
                    currentConversation.messages.remove(at: placeholderIndex)
                }
                state = .idle
            }
        } catch {
            await MainActor.run {
                state = .error("An error occurred during regeneration: \(error.localizedDescription)")
                if let placeholderId = newResponseId, let placeholderIndex = currentConversation.messages.firstIndex(where: { $0.id == placeholderId }) {
                    currentConversation.messages.remove(at: placeholderIndex)
                }
                state = .idle
            }
        }
    }
}
