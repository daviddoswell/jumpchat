import Foundation
import SwiftUI
import ElevenLabsSDK
import AVFoundation

@MainActor
final class SpeechManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var state: VisualizationState = .idle
    @Published private(set) var audioAmplitude: Float = 0.0
    @Published private(set) var isMuted: Bool = false
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
        audioAmplitude = 0.0
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
    
    func toggleMute() {
        isMuted.toggle()
        provideFeedback(intensity: 0.2)
        
        // Reset amplitude when muted
        if isMuted {
            audioAmplitude = 0.0
        }
    }
    
    // Make endVoiceChat nonisolated since it's called from callbacks
    nonisolated func endVoiceChat() {
        Task { @MainActor in
            conversation?.endSession()
            sessionTimer?.invalidate()
            audioLevelTimer?.invalidate()
            audioAmplitude = 0.0
            state = .idle
            isMuted = false
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
                guard let self = self else { return }
                switch mode {
                case .listening:
                    self.state = .listening
                    // Reset amplitude when switching to listening
                    if !self.isMuted {
                        self.audioAmplitude = 0.0
                    }
                    self.provideFeedback(intensity: 0.2)
                case .speaking:
                    self.state = .responding
                    self.provideFeedback(intensity: 0.4)
                @unknown default:
                    self.state = .idle
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
                // When AI is speaking, we want active movement
                if !self.isMuted && self.state == .responding {
                    let targetAmplitude: Float = 0.7
                    let currentAmplitude = self.audioAmplitude
                    let newAmplitude = currentAmplitude + (targetAmplitude - currentAmplitude) * 0.2
                    self.audioAmplitude = newAmplitude + Float.random(in: -0.1...0.1)
                } else {
                    // Immediately go to zero when not speaking
                    self.audioAmplitude = 0.0
                }
            }
        }
    }
    
    private func provideFeedback(intensity: CGFloat) {
        hapticGenerator.prepare()
        hapticGenerator.impactOccurred(intensity: intensity)
    }
}
