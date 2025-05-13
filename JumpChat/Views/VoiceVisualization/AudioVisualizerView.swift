import SwiftUI

struct AudioVisualizerView: View {
    @Binding var audioAmplitude: Float
    
    // Multiple wave phases for layered effect
    @State private var phase1: CGFloat = 0
    @State private var phase2: CGFloat = .pi / 3
    @State private var phase3: CGFloat = .pi / 1.5
    
    private let gradientColors = [
        Color(red: 0.4, green: 0.2, blue: 0.8, opacity: 1.0),   // Deep purple
        Color(red: 0.6, green: 0.3, blue: 1.0, opacity: 1.0),   // Bright purple
        Color(red: 0.2, green: 0.6, blue: 1.0, opacity: 1.0),   // Bright blue
        Color(red: 0.4, green: 0.2, blue: 0.8, opacity: 1.0)    // Deep purple
    ]
    
    var body: some View {
        WaveCanvas(
            audioAmplitude: audioAmplitude,
            phase1: phase1,
            phase2: phase2,
            phase3: phase3,
            gradientColors: gradientColors
        )
        .onAppear {
            // Animate wave phases
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase1 = .pi * 2
            }
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                phase2 = .pi * 2
            }
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                phase3 = .pi * 2
            }
        }
    }
}

private struct WaveCanvas: View {
    let audioAmplitude: Float
    let phase1: CGFloat
    let phase2: CGFloat
    let phase3: CGFloat
    let gradientColors: [Color]
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            Canvas { context, size in
                drawWaves(context: context, size: size)
            }
        }
        .background(Color.black) // Make sure we can see the waves
    }
    
    private func drawWaves(context: GraphicsContext, size: CGSize) {
        let phases = [phase1, phase2, phase3]
        
        for layerIndex in 0...2 {
            let opacity = 1.0 - Double(layerIndex) * 0.2  // Increased base opacity
            let amplitude = CGFloat(audioAmplitude) * (100 - CGFloat(layerIndex) * 20)  // Increased amplitude
            let phase = phases[layerIndex]
            
            var path = Path()
            let points = getWavePoints(size: size, amplitude: amplitude, phase: phase)
            path.addLines(points)
            
            var contextCopy = context
            contextCopy.opacity = opacity
            contextCopy.addFilter(.blur(radius: 10))  // Reduced blur for more visibility
            
            let gradient = Gradient(colors: gradientColors)
            contextCopy.stroke(
                path,
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: 0, y: size.height/2),
                    endPoint: CGPoint(x: size.width, y: size.height/2)
                ),
                lineWidth: 4  // Increased line width
            )
        }
    }
    
    private func getWavePoints(size: CGSize, amplitude: CGFloat, phase: CGFloat) -> [CGPoint] {
        var points: [CGPoint] = []
        let midHeight = size.height / 2
        
        for x in stride(from: 0, through: size.width, by: 1) {
            let relativeX = x / size.width
            let normalizedX = relativeX * .pi * 4
            
            let sine1 = sin(normalizedX + phase)
            let sine2 = sin(normalizedX * 2 + phase) * 0.5
            let sine3 = sin(normalizedX * 0.5 + phase) * 0.3
            let combinedSine = (sine1 + sine2 + sine3) / 1.8
            
            let edgeFactor = sin(relativeX * .pi)
            let y = midHeight + combinedSine * amplitude * edgeFactor
            
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AudioVisualizerView(audioAmplitude: .constant(0.8))  // Increased test amplitude
            .frame(height: 200)  // Increased preview height
    }
}
