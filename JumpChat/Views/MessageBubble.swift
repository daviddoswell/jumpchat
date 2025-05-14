import SwiftUI
import AVFoundation

struct MessageBubble: View {
    let message: Message
    @State private var showCopyAlert = false
    @State private var showFeedbackAlert = false
    @StateObject private var textManager = ServiceContainer.shared.textManager
    @ObservedObject private var chatManager = ServiceContainer.shared.stateManager

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(ResponseParser.parse(message.content))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(24)
                    .padding(.horizontal, 16)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    StreamingText(text: message.content, isStreaming: message.isStreaming)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                        .textSelection(.enabled)
                    
                    HStack(spacing: 28) {
                        Button(action: {
                            UIPasteboard.general.string = message.content
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
                        
                        // Text-to-speech button
                        Button(action: {
                            if textManager.isPlaying {
                                textManager.stop()
                            } else {
                                Task {
                                    await textManager.synthesizeAndPlay(message.content)
                                }
                            }
                        }) {
                            if textManager.isSynthesizing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(.systemGray)))
                                    .frame(width: 18, height: 18)
                            } else {
                                Image(systemName: textManager.isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                                    .font(.system(size: 18))
                            }
                        }
                        .disabled(textManager.isSynthesizing)
                        
                        // Thumbs up button
                        Button(action: {
                            chatManager.rateMessage(message, rating: .thumbsUp)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showFeedbackAlert = true
                            }
                            // Hide after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showFeedbackAlert = false
                                }
                            }
                        }) {
                            Image(systemName: message.rating == .thumbsUp ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .font(.system(size: 18))
                        }
                        .foregroundColor(message.rating == .thumbsUp ? .blue : Color(.systemGray))
                        
                        // Thumbs down button
                        Button(action: {
                            chatManager.rateMessage(message, rating: .thumbsDown)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showFeedbackAlert = true
                            }
                            // Hide after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showFeedbackAlert = false
                                }
                            }
                        }) {
                            Image(systemName: message.rating == .thumbsDown ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                .font(.system(size: 18))
                        }
                        .foregroundColor(message.rating == .thumbsDown ? .blue : Color(.systemGray))
                        
                        // Regenerate button
                        Button(action: {
                            print("Regenerate tapped for message: \(message.id)")
                            Task {
                                await chatManager.regenerateResponse(for: message)
                            }
                        }) {
                            if chatManager.state == .thinking {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(.systemGray)))
                                    .frame(width: 18, height: 18)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18))
                            }
                        }
                        .disabled(
                            message.isUser || // Can't regenerate user messages
                            message.isStreaming || // Can't regenerate while streaming
                            chatManager.state == .thinking || // Can't regenerate while thinking
                            chatManager.state == .streaming // Can't regenerate while streaming
                        )
                        .foregroundColor(Color(.systemGray))  // Match other buttons' color
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
                        Image(systemName: "xmark")
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
            if showFeedbackAlert {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                        Text("Thank you for your feedback")
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

// Helper class to handle audio player delegate
private class AVPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    @Binding var isPlaying: Bool
    
    init(isPlaying: Binding<Bool>) {
        _isPlaying = isPlaying
        super.init()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
}
