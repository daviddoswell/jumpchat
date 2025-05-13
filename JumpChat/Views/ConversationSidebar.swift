

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
                        isPresented = false
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(conversation.title)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
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
                        isPresented = false
                    }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}
