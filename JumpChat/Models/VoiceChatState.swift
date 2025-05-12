
import Foundation

enum VoiceChatState: Equatable {
  case idle
  case listening
  case processing
  case responding
  case error(String)
}
