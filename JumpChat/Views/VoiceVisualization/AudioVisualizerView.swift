
import SwiftUI

struct AudioVisualizerView: View {
    @Binding var audioAmplitude: Float  // 0.0 to 1.0
    
    // Animation state
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            // Create wave path
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midHeight = height / 2
                
                // Start from left edge
                path.move(to: CGPoint(x: 0, y: midHeight))
                
                // Draw wave using sine function
                for x in stride(from: 0, through: width, by: 1) {
                    let relativeX = x / width                    // 0 to 1
                    let normalizedX = relativeX * .pi * 4        // 0 to 4π
                    
                    // Magnitude decreases towards edges
                    let edgeFactor = sin(relativeX * .pi)       // Creates natural dampening at edges
                    
                    // Combine multiple sine waves for more organic movement
                    let sine1 = sin(normalizedX + animationPhase)
                    let sine2 = sin(normalizedX * 2 + animationPhase * 0.5) * 0.5
                    let combinedSine = (sine1 + sine2) / 1.5
                    
                    // Scale by audio amplitude and edge factor
                    let y = midHeight + combinedSine * height * 0.2 * CGFloat(audioAmplitude) * edgeFactor
                    
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(Color.white, lineWidth: 2)
            .animation(.smooth, value: audioAmplitude)
        }
        .onAppear {
            // Start continuous phase animation
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationPhase = .pi * 2
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        StateWrapper()
    }
}

// Preview helper
private struct StateWrapper: View {
    @State private var amplitude: Float = 0.3
    
    var body: some View {
        VStack {
            AudioVisualizerView(audioAmplitude: $amplitude)
                .frame(height: 100)
            
            Slider(value: $amplitude, in: 0...1)
                .padding()
        }
    }
}
