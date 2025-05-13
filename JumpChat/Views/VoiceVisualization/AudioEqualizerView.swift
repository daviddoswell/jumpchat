import SwiftUI

struct AudioEqualizerView: View {
    let audioAmplitude: Float
    
    var body: some View {
        TimelineView(.animation) { timelineContext in
            Canvas { context, size in
                let time = timelineContext.date.timeIntervalSince1970
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                
                // Create multiple paths with different opacities for fade effect
                for fadeStep in 0..<8 {
                    let fadeOffset = Double(fadeStep) * 0.15
                    let path = Path { path in
                        // Start at left edge
                        path.move(to: CGPoint(x: 0, y: center.y))
                        
                        // Simplified curve calculation for straighter line
                        let baseAmplitude = Double(audioAmplitude) * size.height * 0.2
                        let timeVariation = sin(time * 3) * 0.1 // Subtle movement
                        let amplitude = baseAmplitude * (1 + timeVariation)
                        
                        // Use quadratic curve for smoother, straighter look
                        let midPointY = center.y - amplitude
                        let controlPoint = CGPoint(x: size.width/2, y: midPointY)
                        
                        path.addQuadCurve(
                            to: CGPoint(x: size.width, y: center.y),
                            control: controlPoint
                        )
                    }
                    
                    // Draw with increased base opacity
                    drawGlowingLine(context: context, path: path, opacity: (1.0 - (Double(fadeStep) * 0.12)))
                }
            }
        }
        .frame(height: 100) // Constrain height for better control
    }
    
    private func drawGlowingLine(context: GraphicsContext, path: Path, opacity: Double) {
        // Super soft outer glow
        var extremeOuterContext = context
        extremeOuterContext.addFilter(.blur(radius: 25))
        extremeOuterContext.stroke(
            path,
            with: .color(.white.opacity(0.02 * opacity)),
            lineWidth: 35
        )
        
        // Soft outer glow
        var outerContext = context
        outerContext.addFilter(.blur(radius: 20))
        outerContext.stroke(
            path,
            with: .color(.white.opacity(0.04 * opacity)),
            lineWidth: 28
        )
        
        // Middle glow
        var middleContext = context
        middleContext.addFilter(.blur(radius: 15))
        middleContext.stroke(
            path,
            with: .color(.white.opacity(0.08 * opacity)),
            lineWidth: 20
        )
        
        // Inner glow
        var innerContext = context
        innerContext.addFilter(.blur(radius: 10))
        innerContext.stroke(
            path,
            with: .color(.white.opacity(0.12 * opacity)),
            lineWidth: 12
        )
        
        // Brighter core
        var coreContext = context
        coreContext.addFilter(.blur(radius: 3))
        coreContext.stroke(
            path,
            with: .color(.white.opacity(0.15 * opacity)),
            lineWidth: 2
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AudioEqualizerView(audioAmplitude: 0.5)
    }
}
