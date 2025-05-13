


import SwiftUI

struct AudioEqualizerView: View {
    let audioAmplitude: Float
    
    var body: some View {
        TimelineView(.animation) { timelineContext in
            Canvas { context, size in
              _ = timelineContext.date.timeIntervalSince1970
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                
                // Single line with pinned ends
                let path = Path { path in
                    // Start at left edge
                    path.move(to: CGPoint(x: 0, y: center.y))
                    
                    // Add curve based on audio magnitude
                    let amplitude = Double(audioAmplitude) * size.height * 0.3
                    let midPointY = center.y - amplitude
                    let controlPoint = CGPoint(x: size.width/2, y: midPointY)
                    
                    // End at right edge with smooth curve through middle
                    path.addCurve(
                        to: CGPoint(x: size.width, y: center.y),
                        control1: controlPoint,
                        control2: controlPoint
                    )
                }
                
                // Use same glow effect as orbiting lines for consistency
                drawGlowingLine(context: context, path: path)
            }
        }
    }
    
    private func drawGlowingLine(context: GraphicsContext, path: Path) {
        // Super soft outer glow
        var outerContext = context
        outerContext.addFilter(.blur(radius: 12))
        outerContext.stroke(
            path,
            with: .color(.white.opacity(0.06)),
            lineWidth: 18
        )
        
        // Soft middle glow
        var middleContext = context
        middleContext.addFilter(.blur(radius: 8))
        middleContext.stroke(
            path,
            with: .color(.white.opacity(0.1)),
            lineWidth: 12
        )
        
        // Inner glow
        var innerContext = context
        innerContext.addFilter(.blur(radius: 4))
        innerContext.stroke(
            path,
            with: .color(.white.opacity(0.2)),
            lineWidth: 8
        )
        
        // Core glow
        var coreContext = context
        coreContext.addFilter(.blur(radius: 2))
        coreContext.stroke(
            path,
            with: .color(.white.opacity(0.4)),
            lineWidth: 3
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AudioEqualizerView(audioAmplitude: 0.5)
            .frame(height: 100)
    }
}


