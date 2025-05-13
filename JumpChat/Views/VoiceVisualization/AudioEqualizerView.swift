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
                        // Start at left edge at center line
                        path.move(to: CGPoint(x: 0, y: center.y))
                        
                        // Calculate dynamic wave points
                        let pointCount = 32
                        let baseAmplitude = Double(audioAmplitude) * size.height * 0.3
                        
                        var wavePoints: [CGPoint] = []
                        for i in 0...pointCount {
                            let x = size.width * Double(i) / Double(pointCount)
                            let progress = Double(i) / Double(pointCount)
                            
                            // Create wave oscillation that peaks in the middle
                            let intensity = sin(progress * .pi)
                            let oscillation = sin(time * 12 + progress * 8)
                            
                            // Calculate y position: oscillates around center line
                            let y = center.y + (baseAmplitude * intensity * oscillation)
                            wavePoints.append(CGPoint(x: x, y: y))
                        }
                        
                        // Draw smooth curve through points
                        for (index, point) in wavePoints.enumerated() {
                            if index == 0 {
                                path.move(to: point)
                            } else {
                                path.addLine(to: point)
                            }
                        }
                    }
                    
                    // Calculate fade based on step
                    let baseOpacity = 1.0 - (Double(fadeStep) * 0.15)
                    let finalOpacity = baseOpacity * baseOpacity
                    
                    // Draw with enhanced glow effect
                    drawGlowingLine(
                        context: context,
                        path: path,
                        opacity: finalOpacity,
                        fadeOffset: fadeOffset
                    )
                }
            }
        }
        .frame(height: 100)
    }
    
    private func drawGlowingLine(context: GraphicsContext, path: Path, opacity: Double, fadeOffset: Double) {
        // Enhanced glow effect with fade offset influencing the blur radius
        
        // Super soft outer glow with very low opacity
        var extremeOuterContext = context
        extremeOuterContext.addFilter(.blur(radius: 25 + fadeOffset))
        extremeOuterContext.stroke(
            path,
            with: .color(.white.opacity(0.01 * opacity)),
            lineWidth: 35
        )
        
        // Soft outer glow
        var outerContext = context
        outerContext.addFilter(.blur(radius: 20 + (fadeOffset * 0.8)))
        outerContext.stroke(
            path,
            with: .color(.white.opacity(0.02 * opacity)),
            lineWidth: 28
        )
        
        // Middle glow
        var middleContext = context
        middleContext.addFilter(.blur(radius: 15 + (fadeOffset * 0.6)))
        middleContext.stroke(
            path,
            with: .color(.white.opacity(0.04 * opacity)),
            lineWidth: 20
        )
        
        // Inner glow
        var innerContext = context
        innerContext.addFilter(.blur(radius: 10 + (fadeOffset * 0.4)))
        innerContext.stroke(
            path,
            with: .color(.white.opacity(0.06 * opacity)),
            lineWidth: 12
        )
        
        // Very subtle core
        var coreContext = context
        coreContext.addFilter(.blur(radius: 3 + (fadeOffset * 0.2)))
        coreContext.stroke(
            path,
            with: .color(.white.opacity(0.08 * opacity)),
            lineWidth: 2
        )
    }
}

extension CGPoint {
    func midPoint(to point: CGPoint) -> CGPoint {
        return CGPoint(x: (self.x + point.x) / 2, y: (self.y + point.y) / 2)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AudioEqualizerView(audioAmplitude: 0.5)
    }
}
