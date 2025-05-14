import Foundation
import ElevenLabsSDK

struct ElevenLabsVoice: Codable {
    let voice_id: String
    let name: String
}

struct ElevenLabsVoicesResponse: Codable {
    let voices: [ElevenLabsVoice]
}

class ElevenLabsVoiceService: VoiceService {
    private let apiKey: String
    private let voiceID: String
    private let baseURL = "https://api.elevenlabs.io/v2"
    
    init(apiKey: String = Config.elevenLabsApiKey, voiceID: String = Config.elevenLabsVoiceId) {
        self.apiKey = apiKey
        self.voiceID = voiceID
        print("Debug - Using API Key prefix: \(apiKey.prefix(15))...")
        print("Debug - Using Voice ID: \(voiceID)")
        
        Task {
            await listVoices()
        }
    }
    
    private func listVoices() async {
        print("Debug - Fetching available voices...")
        var request = URLRequest(url: URL(string: "\(baseURL)/voices")!)
        request.addValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Debug - Invalid response type")
                return
            }
            
            print("Debug - Voices API Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                if let voicesResponse = try? JSONDecoder().decode(ElevenLabsVoicesResponse.self, from: data) {
                    print("Debug - Available Voices:")
                    for voice in voicesResponse.voices {
                        print("Voice ID: \(voice.voice_id), Name: \(voice.name)")
                    }
                } else {
                    print("Debug - Failed to decode voices response")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Debug - Raw Response: \(responseString)")
                    }
                }
            } else {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("Debug - Error Response: \(errorString)")
                }
            }
        } catch {
            print("Debug - Failed to list voices: \(error)")
        }
    }
    
    func synthesizeSpeech(from text: String) async throws -> Data {
        print("Debug - Starting speech synthesis...")
        var request = URLRequest(url: URL(string: "\(baseURL)/text-to-speech/\(voiceID)")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        let requestBody = [
            "text": text,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75
            ]
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("Debug - TTS Request URL: \(request.url?.absoluteString ?? "")")
        print("Debug - TTS Voice ID: \(voiceID)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ElevenLabsVoiceService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("Debug - TTS Status Code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Debug - TTS Error Response: \(responseString)")
            }
            
            throw NSError(domain: "ElevenLabsVoiceService",
                         code: httpResponse.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to synthesize speech. Check debug logs."])
        }
        
        print("Debug - Successfully received audio data: \(data.count) bytes")
        return data
    }
    
    func streamSpeech(from text: String) async throws -> AsyncStream<Data> {
        print("Debug - Starting speech streaming...")
        var request = URLRequest(url: URL(string: "\(baseURL)/text-to-speech/\(voiceID)/stream")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        struct TTSRequest: Codable {
            let text: String
            let model_id: String
            let voice_settings: VoiceSettings
        }
        
        struct VoiceSettings: Codable {
            let stability: Double
            let similarity_boost: Double
        }
        
        let ttsRequest = TTSRequest(
            text: text,
            model_id: "eleven_monolingual_v1",
            voice_settings: VoiceSettings(
                stability: 0.5,
                similarity_boost: 0.75
            )
        )
        
        request.httpBody = try JSONEncoder().encode(ttsRequest)
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ElevenLabsVoiceService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode != 200 {
            throw NSError(domain: "ElevenLabsVoiceService",
                         code: httpResponse.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: "Stream failed with status: \(httpResponse.statusCode)"])
        }
        
        return AsyncStream { continuation in
            Task {
                for try await byte in bytes {
                    continuation.yield(Data([byte]))
                }
                continuation.finish()
            }
        }
    }
}
