import Foundation
import SwiftUI
import AVFoundation

@MainActor
final class TextManager: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var isSynthesizing = false
    @Published var error: String?
    
    private var audioPlayer: AVAudioPlayer?
    private let baseURL = "https://api.elevenlabs.io/v1"
    
    private func setupAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
    }

    func synthesizeAndPlay(_ text: String) async {
        guard !isSynthesizing else { return }
        isSynthesizing = true

        do {
            try setupAudioSession()
            
            guard let url = URL(string: "\(baseURL)/text-to-speech/\(Config.elevenLabsVoiceId)/stream") else {
                throw NSError(domain: "TextManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL configuration"])
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
            request.setValue(Config.elevenLabsApiKey.trimmingCharacters(in: .whitespacesAndNewlines),
                           forHTTPHeaderField: "xi-api-key")

            let parameters: [String: Any] = [
                "text": text,
                "model_id": "eleven_multilingual_v2",
                "voice_settings": [
                    "stability": 0.5,
                    "similarity_boost": 0.75
                ]
            ]

            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "TextManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
            }

            if httpResponse.statusCode != 200 {
                let errorMessage = handleAPIError(httpResponse.statusCode, data)
                throw NSError(domain: "TextManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }

            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()
            guard audioPlayer?.play() ?? false else {
                throw NSError(domain: "TextManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to play audio"])
            }
            isPlaying = true

        } catch {
            print("Audio Error: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }

        isSynthesizing = false
    }
    
    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    private func handleAPIError(_ statusCode: Int, _ data: Data) -> String {
        if let errorText = String(data: data, encoding: .utf8) {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = errorJson["detail"] as? [String: Any],
               let message = detail["message"] as? String {
                return message
            }
            
            switch statusCode {
            case 401:
                return "Invalid API key. Please check your configuration."
            case 403:
                return "Access denied. Please verify your API permissions."
            case 429:
                return "Rate limit exceeded. Please try again later."
            case 500...599:
                return "Server error. Please try again later."
            default:
                return "Error: \(errorText)"
            }
        }
        return "Unknown error occurred (Status: \(statusCode))"
    }
}
