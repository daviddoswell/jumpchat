import SwiftUI
import OpenAISwift

struct ContentView: View {
    @StateObject private var chatManager: ChatStateManager = ServiceContainer.shared.stateManager
    @StateObject private var keyboardManager = KeyboardManager()
    @State private var messageText = ""
    @State private var showingSidebar = false
    @State private var conversations: [Conversation] = []
    
    private let storageService: StorageService = try! LocalStorageService()
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // Chat area with tap to dismiss
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(chatManager.currentConversation.messages) { message in
                                    MessageBubble(
                                        message: message.content,
                                        isUser: message.isUser
                                    )
                                }
                                if chatManager.state == .thinking {
                                    ThinkingBubble()
                                        .id("thinking")
                                        .transition(.opacity)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.bottom, keyboardManager.isVisible ? keyboardManager.keyboardRect.height + 180 : 180)
                        }
                        .onChange(of: chatManager.currentConversation.messages.count) { oldValue, newValue in
                            withAnimation {
                                proxy.scrollTo(chatManager.currentConversation.messages.last?.id, anchor: .bottom)
                            }
                            // Save conversation when messages change
                            try? storageService.saveConversation(chatManager.currentConversation)
                            loadConversations()
                        }
                        .onChange(of: chatManager.state) { oldValue, newValue in
                            if newValue == .thinking {
                                withAnimation {
                                    proxy.scrollTo("thinking", anchor: .bottom)
                                }
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        keyboardManager.hideKeyboard()
                    }
                    
                    // Input section
                    VStack(spacing: 8) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                SuggestionButton(
                                    title: "Portfolio analysis",
                                    subtitle: "review my investments",
                                    action: { messageText = "Can you analyze my current investment portfolio and suggest optimizations?" }
                                )
                                SuggestionButton(
                                    title: "Tax strategies",
                                    subtitle: "minimize tax liability",
                                    action: { messageText = "What tax optimization strategies would you recommend for high-net-worth individuals?" }
                                )
                                SuggestionButton(
                                    title: "Estate planning",
                                    subtitle: "wealth transfer options",
                                    action: { messageText = "Help me understand the best options for transferring wealth to my heirs efficiently" }
                                )
                            }
                            .padding(.horizontal, 12)
                        }
                        .frame(height: 70)
                        
                        ChatInputBar(
                            keyboardVisible: keyboardManager.isVisible,
                            text: $messageText,
                            isLoading: chatManager.state == .thinking || chatManager.state == .streaming,
                            onSend: {
                                let text = messageText
                                messageText = ""
                                Task {
                                    await chatManager.sendMessage(text)
                                }
                            }
                        )
                    }
                    .ignoresSafeArea(.keyboard)
                    .background(Color.black)
                }
            }
            .navigationTitle("Jump Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSidebar = true }) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: startNewChat) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingSidebar) {
            ConversationSidebar(
                isPresented: $showingSidebar,
                selectedConversation: Binding(
                    get: { chatManager.currentConversation },
                    set: { newConversation in
                        if let conversation = newConversation {
                            loadConversation(conversation)
                        }
                    }
                ),
                conversations: conversations,
                onNewChat: startNewChat,
                onSelect: loadConversation
            )
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            loadConversations()
            // Show keyboard immediately
            UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder),
                                         to: nil,
                                         from: nil,
                                         for: nil)
        }
    }
    
    private func loadConversations() {
        if let conversations = try? storageService.loadAllConversations() {
            self.conversations = conversations.sorted(by: { $0.updatedAt > $1.updatedAt })
        }
    }
    
    private func loadConversation(_ conversation: Conversation) {
        chatManager.loadConversation(conversation)
    }
    
    private func startNewChat() {
        chatManager.startNewConversation()
        messageText = ""
    }
}

#Preview {
    ContentView()
}
