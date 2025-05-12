
import Foundation

enum VisualizationState {
    case idle           // Default orbiting state
    case listening      // When user is speaking (faster spin, more pulse)
    case processing     // Transition state before AI speaks
    case responding     // When AI is speaking (horizontal equalizer)
    
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
