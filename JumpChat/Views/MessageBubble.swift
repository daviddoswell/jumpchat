import SwiftUI

struct MessageBubble: View {
    let message: String
    let isUser: Bool
    @State private var showCopyAlert = false
    
    var body: some View {
        HStack {
            if isUser {
                Spacer()
                Text(ResponseParser.parse(message))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(24)
                    .padding(.horizontal, 16)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    StreamingText(text: message, isStreaming: !isUser)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                        .textSelection(.enabled)
                    
                    HStack(spacing: 28) {
                        Button(action: {
                            UIPasteboard.general.string = message
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showCopyAlert = true
                            }
                            
                            // Hide after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showCopyAlert = false
                                }
                            }
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 18))
                        }
                        Button(action: {}) {
                            Image(systemName: "speaker.wave.2")
                                .font(.system(size: 18))
                        }
                        Button(action: {}) {
                            Image(systemName: "hand.thumbsup")
                                .font(.system(size: 18))
                        }
                        Button(action: {}) {
                            Image(systemName: "hand.thumbsdown")
                                .font(.system(size: 18))
                        }
                        Button(action: {}) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 18))
                        }
                    }
                    .foregroundColor(Color(.systemGray))
                    .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            }
        }
        .overlay {
            if showCopyAlert {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Message copied")
                            .font(.system(size: 15))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(white: 0.2))
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}
