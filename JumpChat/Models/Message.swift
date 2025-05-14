import Foundation

enum MessageRating: Int, Codable {
    case thumbsUp = 1
    case thumbsDown = -1
}

struct Message: Identifiable, Codable {
    let id: UUID
    var content: String
    let isUser: Bool
    let timestamp: Date
    var isStreaming: Bool
    var rating: MessageRating?
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case isUser
        case timestamp
        case isStreaming
        case rating
    }
    
    init(
        id: UUID = UUID(),
        content: String,
        isUser: Bool,
        timestamp: Date = Date(),
        isStreaming: Bool = false,
        rating: MessageRating? = nil
    ) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        self.rating = rating
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let idForLogging = try? container.decodeIfPresent(UUID.self, forKey: .id)?.uuidString ?? "UNKNOWN ID"
        print("Message Decoder: Attempting to decode message with potential ID \(idForLogging)")

        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        isUser = try container.decode(Bool.self, forKey: .isUser)

        if container.contains(.timestamp) {
            print("Message Decoder (ID: \(id.uuidString)): Timestamp key IS present.")
            do {
                timestamp = try container.decode(Date.self, forKey: .timestamp)
                print("Message Decoder (ID: \(id.uuidString)): Timestamp decoded successfully: \(timestamp)")
            } catch let error {
                print("Message Decoder (ID: \(id.uuidString)): Timestamp key was present, but failed to decode. Error: \(error.localizedDescription). Defaulting to current date.")
                timestamp = Date()
            }
        } else {
            print("Message Decoder (ID: \(id.uuidString)): Timestamp key was NOT found. Defaulting to current date.")
            timestamp = Date()
        }
        
        isStreaming = try container.decodeIfPresent(Bool.self, forKey: .isStreaming) ?? false
        rating = try container.decodeIfPresent(MessageRating.self, forKey: .rating)
        
        print("Message Decoder: Successfully finished decoding message ID \(id.uuidString)")
    }
}
