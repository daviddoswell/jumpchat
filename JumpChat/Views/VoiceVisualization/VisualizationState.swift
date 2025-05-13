import Foundation

enum VisualizationState {
    case idle        // Default, no animation
    case listening   // 3D orbiting lines, responding to user voice
    case processing  // Transitioning from orbit to equalizer
    case responding  // Single-line equalizer for AI voice
    
    var rotationSpeed: Float {
        switch self {
        case .idle: return 0.5
        case .listening: return 1.2
        case .processing: return 0.2
        case .responding: return 0.0
        }
    }
    
    var pulseIntensity: Float {
        switch self {
        case .idle: return 1.0
        case .listening: return 1.5
        case .processing: return 0.8
        case .responding: return 0.0
        }
    }
}
