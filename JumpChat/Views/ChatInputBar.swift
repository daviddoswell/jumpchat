import SwiftUI
import UIKit

struct ChatInputBar: View {
    let keyboardVisible: Bool
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    
    @FocusState private var isInputFocused: Bool
    @State private var showVoiceChat = false
    @StateObject private var permissionsManager = PermissionsManager()
    
    var body: some View {
        VStack(spacing: 16) {
            // Text input field with placeholder
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text("Ask anything")
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.horizontal, 2)
                }
                TextField("", text: $text, axis: .vertical)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .textFieldStyle(.plain)
                    .frame(minHeight: 24)
                    .focused($isInputFocused)
            }
            .padding(.top, 6)
            
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
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(white: 0.17))
        .cornerRadius(keyboardVisible ? 12 : 24, corners: keyboardVisible ? [.topLeft, .topRight] : .allCorners)
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(.container, edges: .bottom)
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

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                              byRoundingCorners: corners,
                              cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
