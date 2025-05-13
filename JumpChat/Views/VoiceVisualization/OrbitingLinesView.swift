import SwiftUI

struct OrbitingLinesView: View {
    let state: VisualizationState
    let audioAmplitude: Float
    
    @State private var transitionProgress: Double = 0
    
    private let lineCount = 4
    private let radius: Double = 40
    private let baseSpeed: Double = 0.5  // Increased base speed
    
    var body: some View {
        TimelineView(.animation) { timelineContext in
            Canvas { context, size in
                let time = timelineContext.date.timeIntervalSince1970
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                
                for i in 0..<lineCount {
                    let phase = Double(i) * .pi * 2 / Double(lineCount)
                    let speedMultiplier = state == .listening ?
                        (1.0 + Double(audioAmplitude) * 0.2) : 1.0
                    let speed = baseSpeed * speedMultiplier
                    
                    // Create multiple paths with different opacities for fade effect
                    for fadeStep in 0..<8 {
                        let fadeOffset = Double(fadeStep) * 0.15 // Spread out the fade steps
                        let path = Path { path in
                            // Increased detail for smoother curves
                            for t in stride(from: 0.0, to: 2 * .pi, by: 0.05) {
                                var point3D = orbitPoint(time: time * speed, phase: phase + fadeOffset, angle: t)
                                
                                if transitionProgress > 0 {
                                    point3D.y *= (1 - transitionProgress)
                                    point3D.z *= pow(1 - transitionProgress, 2)
                                }
                                
                                let point2D = project3DTo2D(point3D: point3D, center: center)
                                if t == 0 {
                                    path.move(to: point2D)
                                } else {
                                    path.addLine(to: point2D)
                                }
                            }
                        }
                        // Fade each subsequent path
                        drawGlowingLine(context: context, path: path, opacity: 1.0 - (Double(fadeStep) * 0.15))
                    }
                }
            }
        }
        .onChange(of: state) { oldValue, newValue in
            withAnimation(.easeInOut(duration: 0.7)) {
                transitionProgress = newValue == .responding ? 1 : 0
            }
        }
        .frame(width: 200, height: 200)
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    
    private func orbitPoint(time: Double, phase: Double, angle: Double) -> Vector3D {
        // Multiple wave frequencies for more organic movement
        let primaryWave = Darwin.sin(angle * 2 + time) * 0.12
        let secondaryWave = Darwin.sin(angle * 1.5 + time * 1.3) * 0.08
        let tertiaryWave = Darwin.sin(angle * 3 + time * 0.7) * 0.05  // Added third wave
        let quaternaryWave = Darwin.cos(angle + time * 1.8) * 0.06    // Added fourth wave
        
        // Combine waves with time-based variation
        let radiusVariation = primaryWave + secondaryWave + tertiaryWave + quaternaryWave
        let orbitRadius = radius * (1 + radiusVariation)
        
        // Add flowing motion in all dimensions
        let xFlow = Darwin.sin(time * 0.5) * 0.3
        let yFlow = Darwin.cos(time * 0.4) * 0.2
        let zFlow = Darwin.sin(time * 0.6) * 0.3
        
        let x = orbitRadius * cos(angle + xFlow) * cos(phase + time * 0.4)
        let y = orbitRadius * sin(angle + yFlow)
        let z = orbitRadius * cos(angle + zFlow) * sin(phase + time * 0.4)
        
        // Add subtle spiraling motion
        let spiral = Darwin.sin(time * 0.3) * 0.2
        let rotationAngle = time * (baseSpeed * 0.6) + spiral
        
        let rotatedX = x * cos(rotationAngle) - z * sin(rotationAngle)
        let rotatedZ = x * sin(rotationAngle) + z * cos(rotationAngle)
        
        return Vector3D(x: rotatedX, y: y, z: rotatedZ)
    }
    
    private func project3DTo2D(point3D: Vector3D, center: CGPoint) -> CGPoint {
        let distance: Double = 150
        let scale = distance / (distance - point3D.z * 0.6)
        let x = center.x + point3D.x * scale
        let y = center.y + point3D.y * scale
        return CGPoint(x: x, y: y)
    }
    
    private func drawGlowingLine(context: GraphicsContext, path: Path, opacity: Double) {
        // Super soft outer glow with very low opacity
        var extremeOuterContext = context
        extremeOuterContext.addFilter(.blur(radius: 25))
        extremeOuterContext.stroke(
            path,
            with: .color(.white.opacity(0.01 * opacity)),
            lineWidth: 35
        )
        
        // Soft outer glow
        var outerContext = context
        outerContext.addFilter(.blur(radius: 20))
        outerContext.stroke(
            path,
            with: .color(.white.opacity(0.02 * opacity)),
            lineWidth: 28
        )
        
        // Middle glow
        var middleContext = context
        middleContext.addFilter(.blur(radius: 15))
        middleContext.stroke(
            path,
            with: .color(.white.opacity(0.04 * opacity)),
            lineWidth: 20
        )
        
        // Inner glow
        var innerContext = context
        innerContext.addFilter(.blur(radius: 10))
        innerContext.stroke(
            path,
            with: .color(.white.opacity(0.06 * opacity)),
            lineWidth: 12
        )
        
        // Very subtle core
        var coreContext = context
        coreContext.addFilter(.blur(radius: 3))
        coreContext.stroke(
            path,
            with: .color(.white.opacity(0.08 * opacity)),
            lineWidth: 2
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        OrbitingLinesView(state: .listening, audioAmplitude: 0.5)
            .frame(width: 200, height: 200)
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
