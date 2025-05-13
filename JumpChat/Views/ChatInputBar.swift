import SwiftUI
import UIKit

struct ChatInputBar: View {
    let keyboardVisible: Bool
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    
    @State private var internalFocused: Bool = false
    @FocusState private var isInputFocused: Bool
    @State private var showVoiceChat = false
    @StateObject private var permissionsManager = PermissionsManager()
    
    private func calculateHeight(for text: String) -> CGFloat {
        let lineHeight: CGFloat = 20 // approximate line height
        let maxLines: CGFloat = 10
        let minHeight: CGFloat = 36
        
        let lines = text.components(separatedBy: .newlines).count
        return max(minHeight, min(CGFloat(lines) * lineHeight, maxLines * lineHeight))
    }
    
    private func textHeight() -> CGFloat {
        let font = UIFont.systemFont(ofSize: 17)
        let width = UIScreen.main.bounds.width - 64 // Account for padding
        
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        
        return ceil(boundingBox.height) + 20 // Add some padding
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Ask anything")
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.horizontal, 4)
                        .padding(.top, 8)
                        .opacity(isInputFocused ? 0.5 : 0.8)
                }
                TextEditor(text: $text)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .focused($isInputFocused)
                    .padding(.horizontal, -4)
                    .padding(.vertical, -8)
                    .tint(.white)
                    .frame(height: max(36, min(textHeight(), 200)))
            }
            .padding(.horizontal, 8)
            .onChange(of: isInputFocused) { _, newValue in
                internalFocused = newValue
            }
            .onChange(of: internalFocused) { _, newValue in
                isInputFocused = newValue
            }
            
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
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, keyboardVisible ? 16 : 8)
        .frame(minHeight: 120)
        .background(Color(white: 0.17))
        .clipShape(
            RoundedCorner(
                radius: keyboardVisible ? 12 : 24,
                corners: keyboardVisible ? [.topLeft, .topRight] : .allCorners
            )
        )
        .ignoresSafeArea()
        .frame(maxWidth: .infinity)
        .fullScreenCover(isPresented: $showVoiceChat) {
            VoiceVisualizationView()
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
