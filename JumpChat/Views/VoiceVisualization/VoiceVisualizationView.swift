import SwiftUI

struct VoiceVisualizationView: View {
    @StateObject private var speechManager = SpeechManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack {
                // Top buttons
                HStack {
                    Button(action: {}) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.white)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(.white)
                    }
                }
                .padding()
                
                Spacer()
                
                // Visualization
                ZStack {
                    if speechManager.state != .responding {
                        OrbitingLinesView(
                            state: speechManager.state,
                            audioAmplitude: speechManager.audioAmplitude
                        )
                        .frame(width: 200, height: 200)
                    } else {
                        AudioEqualizerView(
                            audioAmplitude: speechManager.audioAmplitude
                        )
                        .frame(height: 100)
                        .padding(.horizontal)
                    }
                }
                .animation(.smooth, value: speechManager.state)
                
                Spacer()
                
                // Bottom buttons
                HStack(spacing: 60) {
                    Button {
                        speechManager.toggleMute()
                    } label: {
                        Circle()
                            .fill(Color(white: 0.2))
                            .frame(width: 60, height: 60)
                            .overlay {
                                Image(systemName: speechManager.isMuted ? "mic.slash.fill" : "mic.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                    }
                    
                    Button(action: {
                        speechManager.endVoiceChat()
                        dismiss()
                    }) {
                        Circle()
                            .fill(Color(white: 0.2))
                            .frame(width: 60, height: 60)
                            .overlay {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .alert("Error", isPresented: .constant(speechManager.error != nil)) {
            Button("OK") {
                speechManager.error = nil
            }
        } message: {
            Text(speechManager.error ?? "")
        }
        .task {
            // Start voice chat immediately when view appears
            do {
                try await speechManager.startVoiceChat()
            } catch {
                speechManager.error = error.localizedDescription
            }
        }
    }
}

#Preview {
    VoiceVisualizationView()
}
