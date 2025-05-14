import SwiftUI

struct ConversationGroup: Identifiable {
    let id = UUID()
    let title: String
    let conversations: [Conversation]
}

struct ConversationSidebar: View {
    @Binding var isPresented: Bool
    @Binding var selectedConversation: Conversation?
    let conversations: [Conversation]
    let onNewChat: () -> Void
    let onSelect: (Conversation) -> Void
    let onDelete: (Conversation) -> Void
    
    @State private var searchText = ""
    @State private var conversationToDelete: Conversation?
    
    private var groupedConversations: [ConversationGroup] {
        let filteredConversations = conversations.filter { conversation in
            if searchText.isEmpty { return true }
            
            let titleMatch = conversation.title.localizedCaseInsensitiveContains(searchText)
            let messageMatch = conversation.messages.contains { message in
                message.content.localizedCaseInsensitiveContains(searchText)
            }
            
            return titleMatch || messageMatch
        }
        
        let sorted = filteredConversations.sorted(by: { $0.updatedAt > $1.updatedAt })
        var groups: [String: [Conversation]] = [:]
        
        for conversation in sorted {
            let title = conversation.updatedAt.timeAgoDisplay()
            groups[title, default: []].append(conversation)
        }
        
        return groups.map { ConversationGroup(title: $0.key, conversations: $0.value) }
            .sorted { $0.conversations[0].updatedAt > $1.conversations[0].updatedAt }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
            titleBar
            Divider()
                .background(Color(white: 0.2))
            conversationList
        }
        .background(.black)
        .confirmationDialog(
            "",
            isPresented: Binding(
                get: { conversationToDelete != nil },
                set: { if !$0 { conversationToDelete = nil } }
            ),
            actions: {
                if let conversation = conversationToDelete {
                    Button(role: .destructive) {
                        onDelete(conversation)
                        conversationToDelete = nil
                    } label: {
                        Text("Delete")
                    }
                    
                    Button(role: .cancel) {
                        conversationToDelete = nil
                    } label: {
                        Text("Cancel")
                    }
                }
            }
        )
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray.opacity(0.7))
            TextField("Search", text: $searchText)
                .foregroundColor(.white)
                .accentColor(.gray)
                .font(.system(size: 17))
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(white: 0.12))
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    private var titleBar: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                isPresented = false
            }
        }) {
            HStack {
                Text("Jump Chat")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
    
    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                ForEach(groupedConversations) { group in
                    ConversationGroupView(
                        group: group,
                        onSelect: { conversation in
                            onSelect(conversation)
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                isPresented = false
                            }
                        },
                        onLongPress: { conversation in
                            conversationToDelete = conversation
                        },
                        selectedToDelete: conversationToDelete
                    )
                }
            }
        }
        .background(.black)
    }
}
