@MainActor
class ServiceContainer {
    static let shared: ServiceContainer = {
        let container = ServiceContainer()
        return container
    }()
    
    let chatService: ChatService
    let storageService: StorageService
    
    lazy var stateManager: ChatStateManager = {
        ChatStateManager(chatService: self.chatService, storageService: self.storageService)
    }()
    
    private init() {
        self.chatService = OpenAIChatService(apiKey: Config.openAIKey)
        self.storageService = try! LocalStorageService()
    }
}
