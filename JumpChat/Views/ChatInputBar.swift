import SwiftUI
import UIKit

struct ChatInputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    
    @State private var showVoiceChat = false
    
    // Get keyboard width accounting for safe area
    private var keyboardWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Single unified input container
            VStack(spacing: 12) {
                // Text input field on its own line
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text("Ask anything")
                            .foregroundColor(.gray)
                    }
                    TextField("", text: $text)
                        .foregroundColor(.white)
                }
                
                // Controls below
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    if text.isEmpty {
                        Button(action: {}) {
                            Image(systemName: "mic")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        
                        Button {
                            showVoiceChat = true
                        } label: {
                            Image(systemName: "waveform")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                    } else {
                        Button(action: onSend) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                        .disabled(isLoading)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(width: keyboardWidth)
            .background(Color(.systemGray6))
            .cornerRadius(20)
        }
        .background(Color.black)
        .ignoresSafeArea(.keyboard)
        .offset(y: -8)
        .fullScreenCover(isPresented: $showVoiceChat) {
            VoiceVisualizationView()
        }
    }
}
