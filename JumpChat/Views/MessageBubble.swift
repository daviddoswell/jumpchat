import SwiftUI

struct MessageBubble: View {
    let message: String
    let isUser: Bool
    
    private var containsMarkdown: Bool {
        message.contains("*") ||
        message.contains("#") ||
        message.contains("`") ||
        message.contains("- ") ||
        message.contains("1. ") ||
        message.contains("|") ||
        message.contains("\n")
    }
    
    private var attributedText: AttributedString {
        if containsMarkdown {
            do {
                return try AttributedString(markdown: message)
            } catch {
                return AttributedString(message)
            }
        }
        return AttributedString(message)
    }
    
    var body: some View {
        HStack {
            if isUser {
                Spacer()
                Text(attributedText)
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
    }
}
