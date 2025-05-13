import SwiftUI
import UIKit

struct ChatInputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    
    @State private var showVoiceChat = false
    @StateObject private var permissionsManager = PermissionsManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Single unified input container
            VStack(spacing: 16) {
                // Text input field with placeholder
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        HStack {
                            Spacer()
                            Text("Ask anything")
                                .foregroundColor(.gray.opacity(0.8))
                            Spacer()
                        }
                    }
                    TextField("", text: $text, axis: .vertical)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .textFieldStyle(.plain)
                        .frame(minHeight: 20)
                }
                .padding(.top, 4)
                
                // Bottom controls
                HStack(spacing: 20) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    if text.isEmpty {
                        Button(action: {}) {
                            Image(systemName: "mic")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Button {
                            Task {
                                if await permissionsManager.requestMicrophoneAccess() {
                                    showVoiceChat = true
                                }
                            }
                        } label: {
                            Image(systemName: "waveform")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    } else {
                        Button(action: onSend) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .disabled(isLoading)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(white: 0.17)) // Darker gray like ChatGPT
            .cornerRadius(12)
            .padding(.horizontal, 8)
        }
        .background(Color.black)
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $showVoiceChat) {
            VoiceVisualizationView()
        }
    }
}
