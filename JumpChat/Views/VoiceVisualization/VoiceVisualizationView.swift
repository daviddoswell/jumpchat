import SwiftUI

struct VoiceVisualizationView: View {
    @StateObject private var speechManager = SpeechManager()
    @Environment(\.dismiss) private var dismiss
    
    // Animation states
    @State private var gradientRotation: Double = 0
    @State private var blurRadius: CGFloat = 40
    
    private let gradientColors = [
        Color(red: 0.95, green: 0.95, blue: 1.0),  // Soft white
        Color(red: 0.8, green: 0.9, blue: 1.0),    // Light blue
        Color(red: 0.4, green: 0.6, blue: 0.9),    // Medium blue
        Color(red: 0.2, green: 0.4, blue: 0.8)     // Deep blue
    ]
    
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
                        // Listening circle
                        Circle()
                            .fill(
                                AngularGradient(
                                    colors: gradientColors,
                                    center: .center,
                                    angle: .degrees(gradientRotation)
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: blurRadius)
                            .overlay {
                                Circle()
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                                    .blur(radius: 3)
                                    .frame(width: 100, height: 100)
                            }
                            .scaleEffect(1 + CGFloat(speechManager.audioAmplitude) * 0.1)
                            .opacity(speechManager.state == .responding ? 0 : 1)
                    } else {
                        // Wave visualization
                        AudioVisualizerView(audioAmplitude: .constant(speechManager.audioAmplitude))
                            .frame(height: 60)
                            .opacity(speechManager.state == .responding ? 1 : 0)
                    }
                }
                .animation(.smooth, value: speechManager.state)
                
                Spacer()
                
                // Bottom buttons
                HStack(spacing: 60) {
                    Button {
                        Task {
                            try await speechManager.startVoiceChat()
                        }
                    } label: {
                        Circle()
                            .fill(Color(white: 0.2))
                            .frame(width: 60, height: 60)
                            .overlay {
                                Image(systemName: "mic.fill")
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
        .onChange(of: speechManager.state) { oldValue, newValue in
            if newValue == .listening {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    gradientRotation = 360
                }
                
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    blurRadius = 50
                }
            }
        }
        .alert("Error", isPresented: .constant(speechManager.error != nil)) {
            Button("OK") {
                speechManager.error = nil
            }
        } message: {
            Text(speechManager.error ?? "")
        }
    }
}

#Preview {
    VoiceVisualizationView()
}
