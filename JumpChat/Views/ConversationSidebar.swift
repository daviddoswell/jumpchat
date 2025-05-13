import SwiftUI

struct ConversationSidebar: View {
    @Binding var isPresented: Bool
    @Binding var selectedConversation: Conversation?
    let conversations: [Conversation]
    let onNewChat: () -> Void
    let onSelect: (Conversation) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(conversations.sorted(by: { $0.updatedAt > $1.updatedAt })) { conversation in
                    Button(action: {
                        onSelect(conversation)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            isPresented = false
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(conversation.title)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Text(conversation.messages.last?.content ?? "No messages")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Conversations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        onNewChat()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.white)
                    }
                }
            }
            .background(.black)
            .safeAreaInset(edge: .trailing) {
                Divider()
                    .background(Color.gray.opacity(0.3))
            }
        }
        .preferredColorScheme(.dark)
    }
}
