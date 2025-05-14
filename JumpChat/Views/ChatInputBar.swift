import AVFoundation
import SwiftUI
import UIKit

struct ChatInputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    
    @FocusState private var isInputFocused: Bool
    @StateObject private var permissionsManager = PermissionsManager()
    @State private var showVoiceChat = false
    @State private var shouldShowMicPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Ask anything")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                        .opacity(isInputFocused ? 0.5 : 0.8)
                }
                TextEditor(text: $text)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .focused($isInputFocused)
                    .padding(.horizontal, 4)
                    .tint(.white)
                    .frame(height: max(36, min(textHeight(), 200)))
            }
            .padding(.horizontal, 8)
            
            HStack(spacing: 20) {
                Spacer()
                
                if text.isEmpty {
                    Button {
                        Task {
                            let hasPermission = await permissionsManager.requestMicrophoneAccess()
                            if hasPermission {
                                showVoiceChat = true
                            } else {
                                if AVAudioApplication.shared.recordPermission == .denied {
                                    shouldShowMicPermissionAlert = true
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    Button(action: onSend) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .disabled(isLoading)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.15))
        .clipShape(RoundedCorner(radius: 24, corners: [.topLeft, .topRight]))
        .fullScreenCover(isPresented: $showVoiceChat) {
            VoiceVisualizationView()
        }
        .alert("Microphone Access Denied", isPresented: $shouldShowMicPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("JumpChat needs access to your microphone to enable voice input. Please enable microphone access in Settings.")
        }
        .onTapGesture {
            if !isInputFocused {
                isInputFocused = true
            }
        }
    }
    
    private func textHeight() -> CGFloat {
        let font = UIFont.systemFont(ofSize: 17)
        let width = UIScreen.main.bounds.width - 64
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(
          with: constraintRect,
          options: .usesLineFragmentOrigin,
          attributes: [.font: font],
          context: nil
        )
        return ceil(boundingBox.height) + 20
    }
}

struct ViewOffsetKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

extension View {
  func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(RoundedCorner(radius: radius, corners: corners))
  }
}
