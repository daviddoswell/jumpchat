import SwiftUI
import OpenAISwift

struct ContentView: View {
    @StateObject private var chatManager: ChatStateManager = ServiceContainer.shared.stateManager
    @State private var messageText = ""
    @State private var showPermissions = true
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if chatManager.currentConversation.messages.isEmpty {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Text("Hello")
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(Color.black)
                                            .cornerRadius(24)
                                            .padding(.horizontal, 16)
                                    }
                                    
                                    MessageBubble(
                                        message: "Hey there! How can I help you today?",
                                        isUser: false
                                    )
                                    
                                    Spacer()
                                }
                            }
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
                        .padding(.bottom, 160)
                    }
                    .onChange(of: chatManager.currentConversation.messages.count) { oldValue, newValue in
                        withAnimation {
                            proxy.scrollTo(chatManager.currentConversation.messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: chatManager.state) { oldValue, newValue in
                        if newValue == .thinking {
                            withAnimation {
                                proxy.scrollTo("thinking", anchor: .bottom)
                            }
                        }
                    }
                }
                
                VStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            SuggestionButton(
                                title: "Create a painting",
                                subtitle: "in Renaissance-style",
                                action: { messageText = "Create a Renaissance-style painting" }
                            )
                            SuggestionButton(
                                title: "Write a story",
                                subtitle: "about an adventure",
                                action: { messageText = "Write a story about an adventure" }
                            )
                            SuggestionButton(
                                title: "Help me study",
                                subtitle: "for my exam",
                                action: { messageText = "Help me study for my exam" }
                            )
                        }
                        .padding(.horizontal, 8)
                    }
                    .frame(height: 60)
                    
                    ChatInputBar(
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
                .background(Color.black)
            }
            .navigationTitle("Jump Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {}) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showPermissions) {
            PermissionsView(showPermissions: $showPermissions)
        }
    }
}

#Preview {
    ContentView()
}
