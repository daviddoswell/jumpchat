import Foundation

struct Conversation: Identifiable, Codable, Equatable {
  let id: UUID
  var title: String
  var messages: [Message]
  let createdAt: Date
  var updatedAt: Date
  
  init(
    id: UUID = UUID(),
    title: String = "New Chat",
    messages: [Message] = [],
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.title = title
    self.messages = messages
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
  
  static func == (lhs: Conversation, rhs: Conversation) -> Bool {
    lhs.id == rhs.id
  }
}
