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
}
