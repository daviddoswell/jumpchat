import SwiftUI

struct OrbitingLinesView: View {
    let state: VisualizationState
    let audioAmplitude: Float
    
    @State private var transitionProgress: Double = 0
    
    private let lineCount = 4
    private let radius: Double = 50  // Increased for 250x250 frame
    private let baseSpeed: Double = 0.5
    
    var body: some View {
        TimelineView(.animation) { timelineContext in
            Canvas { context, size in
                let time = timelineContext.date.timeIntervalSince1970
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                
                for i in 0..<lineCount {
                    let phase = Double(i) * .pi * 2 / Double(lineCount)
                    // Only apply audio amplitude if it's above a threshold
                    let speedMultiplier = (state == .listening && audioAmplitude > 0.01) ?
                        (1.0 + Double(audioAmplitude) * 0.2) : 1.0
                    let speed = baseSpeed * speedMultiplier
                    
                    for fadeStep in 0..<8 {
                        let fadeOffset = Double(fadeStep) * 0.15
                        let path = Path { path in
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
        let primaryWave = Darwin.sin(angle * 2 + time) * 0.12
        let secondaryWave = Darwin.sin(angle * 1.5 + time * 1.3) * 0.08
        let tertiaryWave = Darwin.sin(angle * 3 + time * 0.7) * 0.05
        let quaternaryWave = Darwin.cos(angle + time * 1.8) * 0.06
    
        let radiusVariation = primaryWave + secondaryWave + tertiaryWave + quaternaryWave
        let orbitRadius = radius * (1 + radiusVariation)
        
        let xFlow = Darwin.sin(time * 0.5) * 0.3
        let yFlow = Darwin.cos(time * 0.4) * 0.2
        let zFlow = Darwin.sin(time * 0.6) * 0.3
        
        let x = orbitRadius * cos(angle + xFlow) * cos(phase + time * 0.4)
        let y = orbitRadius * sin(angle + yFlow)
        let z = orbitRadius * cos(angle + zFlow) * sin(phase + time * 0.4)
        
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
        var extremeOuterContext = context
        extremeOuterContext.addFilter(.blur(radius: 25))
        extremeOuterContext.stroke(
            path,
            with: .color(.white.opacity(0.01 * opacity)),
            lineWidth: 35
        )
        
        var outerContext = context
        outerContext.addFilter(.blur(radius: 20))
        outerContext.stroke(
            path,
            with: .color(.white.opacity(0.02 * opacity)),
            lineWidth: 28
        )
        
        var middleContext = context
        middleContext.addFilter(.blur(radius: 15))
        middleContext.stroke(
            path,
            with: .color(.white.opacity(0.04 * opacity)),
            lineWidth: 20
        )
        
        var innerContext = context
        innerContext.addFilter(.blur(radius: 10))
        innerContext.stroke(
            path,
            with: .color(.white.opacity(0.06 * opacity)),
            lineWidth: 12
        )
        
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
