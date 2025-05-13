import SwiftUI
import OpenAISwift

struct ContentView: View {
    @StateObject private var chatManager: ChatStateManager = ServiceContainer.shared.stateManager
    @StateObject private var keyboardManager = KeyboardManager()
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // Tap gesture to dismiss keyboard
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
                            .padding(.bottom, keyboardManager.isVisible ? geometry.safeAreaInsets.bottom + keyboardManager.keyboardRect.height + 140 : 180)
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
                    .contentShape(Rectangle()) // Make sure entire scroll area is tappable
                    .onTapGesture {
                        keyboardManager.hideKeyboard()
                    }
                    
                    VStack(spacing: 16) {
                        // Suggestions scroll view
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
                            .padding(.horizontal, 12)
                        }
                        .frame(height: 70)
                        .background(Color.black)
                        
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
                    .offset(y: keyboardManager.isVisible ? -keyboardManager.keyboardRect.height + geometry.safeAreaInsets.bottom : 0)
                }
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
            .ignoresSafeArea(.keyboard)
            .onAppear {
                isInputFocused = true
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
