
import SwiftUI

struct ConversationGroupView: View {
    let group: ConversationGroup
    let onSelect: (Conversation) -> Void
    let onLongPress: (Conversation) -> Void
    let selectedToDelete: Conversation?
    
    var body: some View {
        Section {
            ForEach(group.conversations) { conversation in
                ConversationItem(
                    conversation: conversation,
                    isSelected: selectedToDelete == conversation,
                    onTap: { onSelect(conversation) },
                    onLongPress: { onLongPress(conversation) }
                )
            }
        } header: {
            Text(group.title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .padding(.top, 12)
        }
    }
}
