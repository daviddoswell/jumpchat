import SwiftUI
import SceneKit

struct OrbitingLinesView: View {
    // MARK: - Properties
    private let scene = SCNScene()
    private let cameraNode = SCNNode()
    private let lineNodes: [SCNNode]
    
    @Binding var state: VisualizationState
    @Binding var audioAmplitude: Float  // 0.0 to 1.0
    
    // MARK: - Animation Properties
    @State private var currentRotationSpeed: Float = 0.5
    @State private var currentPulseScale: Float = 1.0
    @State private var floatOffset: Float = 0.0
    
    // MARK: - Init
    init(state: Binding<VisualizationState>, audioAmplitude: Binding<Float>, numberOfLines: Int = 3) {
        self._state = state
        self._audioAmplitude = audioAmplitude
        
        // Initialize the orbiting lines
        self.lineNodes = (0..<numberOfLines).map { index in
            // Create a curved path
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -0.5, y: 0))
            
            // Add a gentle curve
            path.addCurve(
                to: CGPoint(x: 0.5, y: 0),
                controlPoint1: CGPoint(x: -0.2, y: 0.2),
                controlPoint2: CGPoint(x: 0.2, y: -0.2)
            )
            
            let shape = SCNShape(path: path, extrusionDepth: 0.01)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.white
            material.emission.contents = UIColor(white: 0.3, alpha: 1.0) // Subtle glow
            shape.materials = [material]
            
            let node = SCNNode(geometry: shape)
            // Distribute lines evenly but with slight randomization
            let angleOffset = Float.random(in: -0.1...0.1)
            node.rotation = SCNVector4(0, 1, 0, .pi * 2 * Float(index) / Float(numberOfLines) + angleOffset)
            return node
        }
    }
    
    // MARK: - Body
    var body: some View {
        SceneView(
            scene: scene,
            pointOfView: cameraNode,
            options: [.autoenablesDefaultLighting]
        )
        .onChange(of: state) { oldValue, newValue in
            updateVisualization()
        }
        .onChange(of: audioAmplitude) { oldValue, newValue in
            updateAudioResponse()
        }
        .onAppear {
            setupScene()
        }
    }
    
    // MARK: - Private Methods
    private func setupScene() {
        // Setup camera
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
        scene.rootNode.addChildNode(cameraNode)
        
        // Add ambient light for better visibility
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 500
        scene.rootNode.addChildNode(ambientLight)
        
        // Add lines to scene
        lineNodes.forEach { node in
            scene.rootNode.addChildNode(node)
        }
        
        // Start animations
        startAnimations()
    }
    
    private func startAnimations() {
        startOrbiting()
        startFloating()
        startPulsing()
    }
    
    private func updateVisualization() {
        // Update rotation speed
        lineNodes.forEach { node in
            node.removeAllActions()
        }
        
        // Don't start new animations if responding
        guard state != .responding else {
            prepareForEqualizer()
            return
        }
        
        startAnimations()
    }
    
    private func updateAudioResponse() {
        // Scale base animations by audio amplitude
        let scaleFactor = 1.0 + (audioAmplitude * 0.5)
        
        lineNodes.forEach { node in
            node.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
        }
    }
    
    private func prepareForEqualizer() {
        // Animate lines to horizontal position
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        
        lineNodes.forEach { node in
            node.rotation = SCNVector4(0, 0, 0, 0)
            node.position = SCNVector3(0, 0, 0)
        }
        
        SCNTransaction.commit()
    }
    
    private func startOrbiting() {
        let baseSpeed = state.rotationSpeed
        
        lineNodes.forEach { node in
            // Create a compound rotation
            let orbitDuration = TimeInterval(2.0 + Double.random(in: 0...1))
            let rotateAction = SCNAction.repeatForever(
                SCNAction.group([
                    SCNAction.rotateBy(x: 0, y: CGFloat(baseSpeed), z: 0, duration: orbitDuration),
                    SCNAction.rotateBy(x: CGFloat.random(in: -0.2...0.2), y: 0, z: 0, duration: orbitDuration * 1.5)
                ])
            )
            node.runAction(rotateAction)
        }
    }
    
    private func startFloating() {
        let intensity = state.pulseIntensity
        let floatAction = SCNAction.repeatForever(
            SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.1 * CGFloat(intensity), z: 0, duration: 1.5),
                SCNAction.moveBy(x: 0, y: -0.1 * CGFloat(intensity), z: 0, duration: 1.5)
            ])
        )
        
        lineNodes.forEach { node in
            // Add slight delay to each line for more organic motion
            let delay = Double.random(in: 0...0.5)
            node.runAction(
                SCNAction.sequence([
                    SCNAction.wait(duration: delay),
                    floatAction
                ])
            )
        }
    }
    
    private func startPulsing() {
        let intensity = state.pulseIntensity
        let pulseAction = SCNAction.repeatForever(
            SCNAction.sequence([
                SCNAction.scale(to: 1.1 * CGFloat(intensity), duration: 1.0),
                SCNAction.scale(to: 0.9 * CGFloat(intensity), duration: 1.0)
            ])
        )
        
        lineNodes.forEach { node in
            // Add slight delay to each line
            let delay = Double.random(in: 0...0.3)
            node.runAction(
                SCNAction.sequence([
                    SCNAction.wait(duration: delay),
                    pulseAction
                ])
            )
        }
    }
}

#Preview {
    StateWrapper()
}

// Preview helper
private struct StateWrapper: View {
    @State private var state: VisualizationState = .idle
    @State private var amplitude: Float = 0.0
    
    var body: some View {
        VStack {
            OrbitingLinesView(state: $state, audioAmplitude: $amplitude)
                .frame(width: 300, height: 300)
                .background(Color.black)
            
            Picker("State", selection: $state) {
                Text("Idle").tag(VisualizationState.idle)
                Text("Listening").tag(VisualizationState.listening)
                Text("Processing").tag(VisualizationState.processing)
                Text("Responding").tag(VisualizationState.responding)
            }
            
            Slider(value: $amplitude, in: 0...1)
        }
        .padding()
    }
}
