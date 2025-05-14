import SwiftUI

struct ContentView: View {
    @ObservedObject private var chatManager = ServiceContainer.shared.stateManager
    @StateObject private var keyboardManager = KeyboardManager()
    @State private var messageText = ""
    @State private var showingSidebar = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .leading) {
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(chatManager.currentConversation.messages) { message in
                                        MessageBubble(
                                            message: message.content,
                                            isUser: message.isUser
                                        )
                                        .id(message.id) // Ensure each message has an ID for scrolling
                                    }
                                    if chatManager.state == .thinking {
                                        ThinkingBubble()
                                            .id("thinking")
                                            .transition(.opacity)
                                    }
                                }
                                .padding(.vertical, 8)
                                // Add bottom padding that matches input height exactly
                                .padding(.bottom, 80)
                            }
                            .onChange(of: chatManager.currentConversation.messages.count) { _, _ in
                                // Scroll to last message with animation
                                if let lastMessageId = chatManager.currentConversation.messages.last?.id {
                                    withAnimation {
                                        proxy.scrollTo(lastMessageId, anchor: .bottom)
                                    }
                                }
                            }
                            // Scroll to bottom on appear
                            .onAppear {
                                if let lastMessageId = chatManager.currentConversation.messages.last?.id {
                                    proxy.scrollTo(lastMessageId, anchor: .bottom)
                                }
                            }
                        }
                        .clipShape(Rectangle()) // Prevent content from showing behind input
                        .safeAreaInset(edge: .bottom) {
                            // This creates a reserved space that the scroll view won't scroll into
                            Color.clear.frame(height: chatManager.currentConversation.messages.isEmpty ? 250 : 180)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            keyboardManager.hideKeyboard()
                            if showingSidebar {
                                showingSidebar = false
                            }
                        }
                        
                        // Input section
                        VStack(spacing: 8) {
                            // Only show suggestions if there are no messages
                            if chatManager.currentConversation.messages.isEmpty {
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
                            }
                            
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
                        .offset(y: keyboardManager.inputOffset)
                    }
                }
                
                // Sidebar overlay when visible
                if showingSidebar {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                showingSidebar = false
                            }
                        }
                        .transition(.opacity)
                }
                
                // Sliding sidebar
                ConversationSidebar(
                    isPresented: $showingSidebar,
                    selectedConversation: Binding(
                        get: { chatManager.currentConversation },
                        set: { newConversation in
                            if let conversation = newConversation {
                                chatManager.loadConversation(conversation)
                            }
                        }
                    ),
                    conversations: chatManager.conversations.sorted(by: { $0.updatedAt > $1.updatedAt }),
                    onNewChat: startNewChat,
                    onSelect: { conversation in
                        chatManager.loadConversation(conversation)
                    },
                    onDelete: { conversation in
                        chatManager.deleteConversation(conversation)
                    }
                )
                .slideTransition(isPresented: showingSidebar)
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
        .onAppear {
            // Show keyboard immediately
            UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder),
                                         to: nil,
                                         from: nil,
                                         for: nil)
        }
    }
    
    private func startNewChat() {
        chatManager.startNewConversation()
        messageText = ""
    }
}

#Preview {
    ContentView()
}
