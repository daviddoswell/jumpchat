import Foundation
import SwiftUI
import ElevenLabsSDK
import AVFoundation

@MainActor
final class SpeechManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var state: VisualizationState = .idle
    @Published private(set) var audioAmplitude: Float = 0.0
    @Published var error: String?
    
    // MARK: - Private Properties
    private var conversation: ElevenLabsSDK.Conversation?
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .soft)
    
    // MARK: - Session Constants
    private static let sessionDuration: TimeInterval = 300 // 5 minutes max
    private var sessionTimer: Timer?
    private var audioLevelTimer: Timer?
    
    // MARK: - Public Methods
    func startVoiceChat() async throws {
        state = .listening
        provideFeedback(intensity: 0.3)
        
        let config = ElevenLabsSDK.SessionConfig(agentId: Config.elevenLabsAgentId)
        let callbacks = createCallbacks()
        
        do {
            conversation = try await ElevenLabsSDK.Conversation.startSession(
                config: config,
                callbacks: callbacks
            )
            startAudioLevelMonitoring()
        } catch {
            self.error = error.localizedDescription
            state = .idle
        }
    }
    
    // Make endVoiceChat nonisolated since it's called from callbacks
    nonisolated func endVoiceChat() {
        Task { @MainActor in
            conversation?.endSession()
            sessionTimer?.invalidate()
            audioLevelTimer?.invalidate()
            state = .idle
            provideFeedback(intensity: 0.6)
        }
    }
    
    // MARK: - Private Methods
    private func createCallbacks() -> ElevenLabsSDK.Callbacks {
        var callbacks = ElevenLabsSDK.Callbacks()
        
        callbacks.onConnect = { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.startSessionTimer()
            }
        }
        
        callbacks.onDisconnect = { [weak self] in
            self?.endVoiceChat()
        }
        
        callbacks.onError = { [weak self] error, info in
            Task { @MainActor [weak self] in
                self?.error = info as? String ?? "Unknown error occurred"
                self?.endVoiceChat()
            }
        }
        
        callbacks.onModeChange = { [weak self] mode in
            Task { @MainActor [weak self] in
                switch mode {
                case .listening:
                    self?.state = .listening
                    self?.provideFeedback(intensity: 0.2)
                case .speaking:
                    self?.state = .responding
                    self?.provideFeedback(intensity: 0.4)
                @unknown default:
                    self?.state = .idle
                }
            }
        }
        
        return callbacks
    }
    
    private func startSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(
            withTimeInterval: Self.sessionDuration,
            repeats: false
        ) { [weak self] _ in
            self?.endVoiceChat()
        }
    }
    
    private func startAudioLevelMonitoring() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                // Simulate smooth audio level changes
                let targetAmplitude: Float = self.state == .responding ? 0.7 : 0.3
                let currentAmplitude = self.audioAmplitude
                let newAmplitude = currentAmplitude + (targetAmplitude - currentAmplitude) * 0.2
                self.audioAmplitude = newAmplitude + Float.random(in: -0.1...0.1)
            }
        }
    }
    
    private func provideFeedback(intensity: CGFloat) {
        hapticGenerator.prepare()
        hapticGenerator.impactOccurred(intensity: intensity)
    }
}
