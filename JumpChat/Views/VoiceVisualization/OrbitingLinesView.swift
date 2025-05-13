import SwiftUI

struct OrbitingLinesView: View {
    let state: VisualizationState
    let audioAmplitude: Float
    
    @State private var transitionProgress: Double = 0
    
    private let lineCount = 4
    private let radius: Double = 90  // Doubled from 45
    private let baseSpeed: Double = 0.5  // Increased base speed
    
    var body: some View {
        TimelineView(.animation) { timelineContext in
            Canvas { context, size in
                let time = timelineContext.date.timeIntervalSince1970
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                
                // Draw each line
                for i in 0..<lineCount {
                    let phase = Double(i) * .pi / 2
                    // Increase speed for listening state
                    let speed = state == .listening ?
                        baseSpeed * (1.5 + Double(audioAmplitude)) : baseSpeed
                    
                    let path = Path { path in
                        for t in stride(from: 0.0, to: 2 * .pi, by: 0.08) {
                            var point3D = orbitPoint(time: time * speed, phase: phase, angle: t)
                            
                            // During transition, gradually flatten the z coordinate
                            if transitionProgress > 0 {
                                point3D.z *= (1 - transitionProgress)
                            }
                            
                            let point2D = project3DTo2D(point3D: point3D, center: center)
                            if t == 0 {
                                path.move(to: point2D)
                            } else {
                                path.addLine(to: point2D)
                            }
                        }
                    }
                    drawGlowingLine(context: context, path: path)
                }
            }
        }
        .onChange(of: state) { oldValue, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                transitionProgress = newValue == .responding ? 1 : 0
            }
        }
    }
    
    private func orbitPoint(time: Double, phase: Double, angle: Double) -> Vector3D {
        let primaryWave = Darwin.sin(angle * 2 + time) * 0.15
        let secondaryWave = Darwin.sin(angle * 1.5 + time * 1.2) * 0.08
        let orbitRadius = radius * (1 + primaryWave + secondaryWave)
        
        let x = orbitRadius * cos(angle) * cos(phase + time * 0.4)
        let y = orbitRadius * sin(angle) * 1.1
        let z = orbitRadius * cos(angle) * sin(phase + time * 0.4)
        
        let rotationAngle = time * (baseSpeed * 0.8)
        let rotatedX = x * cos(rotationAngle) - z * sin(rotationAngle)
        let rotatedZ = x * sin(rotationAngle) + z * cos(rotationAngle)
        
        return Vector3D(x: rotatedX, y: y, z: rotatedZ)
    }
    
    private func project3DTo2D(point3D: Vector3D, center: CGPoint) -> CGPoint {
        let distance: Double = 120
        let scale = distance / (distance - point3D.z * 0.7)
        let x = center.x + point3D.x * scale
        let y = center.y + point3D.y * scale
        return CGPoint(x: x, y: y)
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
        OrbitingLinesView(state: .listening, audioAmplitude: 0.5)
            .frame(width: 300, height: 300)
    }
}
