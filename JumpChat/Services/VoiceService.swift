import Foundation

protocol VoiceService {
  func synthesizeSpeech(from text: String) async throws -> Data
  func streamSpeech(from text: String) async throws -> AsyncStream<Data>
}

// Placeholder implementation until we have a production-ready voice SDK
class DefaultVoiceService: VoiceService {
  private let apiKey: String
  private let voiceID: String
  
  init(apiKey: String, voiceID: String) {
    self.apiKey = apiKey
    self.voiceID = voiceID
  }
  
  func synthesizeSpeech(from text: String) async throws -> Data {
    // TODO: Implement with production voice API
    throw NSError(domain: "VoiceService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
  }
  
  func streamSpeech(from text: String) async throws -> AsyncStream<Data> {
    // TODO: Implement with production voice API
    throw NSError(domain: "VoiceService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
  }
}
