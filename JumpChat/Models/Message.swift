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
        
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        isUser = try container.decode(Bool.self, forKey: .isUser)

        if container.contains(.timestamp) {
            do {
                timestamp = try container.decode(Date.self, forKey: .timestamp)
            } catch {
                timestamp = Date()
            }
        } else {
            timestamp = Date()
        }
        
        isStreaming = try container.decodeIfPresent(Bool.self, forKey: .isStreaming) ?? false
        rating = try container.decodeIfPresent(MessageRating.self, forKey: .rating)
    }
}
