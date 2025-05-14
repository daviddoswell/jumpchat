import SwiftUI
import CoreHaptics

struct ContentView: View {
    @ObservedObject private var chatManager = ServiceContainer.shared.stateManager
    @State private var messageText = ""
    @State private var showingSidebar = false
    @State private var engine: CHHapticEngine?
    @Environment(\.dismiss) private var dismiss
    @FocusState private var inputFocused: Bool
    
    var body: some View {
        NavigationStack {
            ChatContentView(
                messages: chatManager.currentConversation.messages,
                isThinking: chatManager.state == .thinking,
                messageText: $messageText,
                showingSidebar: $showingSidebar,
                isLoading: chatManager.state == .thinking || chatManager.state == .streaming,
                onSend: sendMessage,
                onNewChat: startNewChat,
                onSelectConversation: { conversation in
                    chatManager.loadConversation(conversation)
                },
                onDeleteConversation: { conversation in
                    chatManager.deleteConversation(conversation)
                },
                currentConversation: chatManager.currentConversation,
                conversations: chatManager.conversations.sorted(by: { $0.updatedAt > $1.updatedAt })
            )
            .navigationTitle("Jump Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    sidebarButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    newChatButton
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder),
                                          to: nil,
                                          from: nil,
                                          for: nil)
        }
    }
    
    private var sidebarButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                showingSidebar.toggle()
            }
            prepareHaptics()
            complexHaptic()
        }) {
            Image(systemName: showingSidebar ? "xmark" : "list.dash")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
    }
    
    private var newChatButton: some View {
        Button(action: startNewChat) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
    }
    
    private func sendMessage() {
        let text = messageText
        messageText = ""
        Task {
            await chatManager.sendMessage(text)
        }
    }
    
    private func startNewChat() {
        chatManager.startNewConversation()
        messageText = ""
    }
    
    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
    }
    
    func complexHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = engine else { return }
        
        var events = [CHHapticEvent]()
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.75)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        events.append(event)
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription)")
        }
    }
}

private struct ChatContentView: View {
    let messages: [Message]
    let isThinking: Bool
    @Binding var messageText: String
    @Binding var showingSidebar: Bool
    let isLoading: Bool
    let onSend: () -> Void
    let onNewChat: () -> Void
    let onSelectConversation: (Conversation) -> Void
    let onDeleteConversation: (Conversation) -> Void
    let currentConversation: Conversation
    let conversations: [Conversation]
    
    var body: some View {
        ZStack(alignment: .leading) {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        messagesList
                            .padding(.vertical, 8)
                    }
                    .onAppear {
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: messages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                     to: nil,
                                                     from: nil,
                                                     for: nil)
                    }
                }
                
                VStack(spacing: 0) {
                    if messages.isEmpty {
                        suggestionButtons
                    }
                    
                    ChatInputBar(
                        text: $messageText,
                        isLoading: isLoading,
                        onSend: onSend
                    )
                }
                .background(Color.black)
            }
            
            ConversationSidebar(
                isPresented: $showingSidebar,
                selectedConversation: Binding(
                    get: { currentConversation },
                    set: { newConversation in
                        if let conversation = newConversation {
                            onSelectConversation(conversation)
                        }
                    }
                ),
                conversations: conversations,
                onNewChat: onNewChat,
                onSelect: onSelectConversation,
                onDelete: onDeleteConversation
            )
            .slideTransition(isPresented: showingSidebar)
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private var messagesList: some View {
        LazyVStack(spacing: 12) {
            ForEach(messages) { message in
                MessageBubble(message: message)
                    .id(message.id)
            }
            if isThinking {
                ThinkingBubble()
                    .id("thinking")
                    .transition(.opacity)
            }
        }
    }
    
    private var suggestionButtons: some View {
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
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = messages.last?.id {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}

#Preview {
    ContentView()
}
