import Foundation

@MainActor
class ServiceContainer {
    let chatService: ChatService
    let stateManager: ChatStateManager
    
    static let shared = ServiceContainer()
    
    private init() {
        self.chatService = OpenAIChatService(apiKey: Config.openAIKey)
        self.stateManager = ChatStateManager(chatService: chatService)
    }
}
