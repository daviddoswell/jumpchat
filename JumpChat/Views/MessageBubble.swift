import SwiftUI

struct MessageBubble: View {
    let message: String
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser {
                Spacer()
                Text(message)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(24)
                    .padding(.horizontal, 16)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(message)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                    
                    HStack(spacing: 28) {
                        Button(action: {}) {
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
