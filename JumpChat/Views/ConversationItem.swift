
import SwiftUI

struct ConversationItem: View {
    let conversation: Conversation
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @State private var longPressHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(conversation.title)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    longPressHaptic.impactOccurred()
                    onLongPress()
                }
        )
        .background(isSelected ? Color.gray.opacity(0.2) : Color.clear)
        .onAppear {
            longPressHaptic.prepare()
        }
    }
}
