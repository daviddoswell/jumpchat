
import Foundation

protocol StorageService {
  func saveConversation(_ conversation: Conversation) throws
  func loadConversation(id: UUID) throws -> Conversation?
  func loadAllConversations() throws -> [Conversation]
  func deleteConversation(id: UUID) throws
}

class LocalStorageService: StorageService {
  private let fileManager = FileManager.default
  private let conversationsDirectory: URL
  
  init() throws {
    let documentsDirectory = try fileManager.url(
      for: .documentDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    conversationsDirectory = documentsDirectory.appendingPathComponent("Conversations", isDirectory: true)
    try createConversationsDirectoryIfNeeded()
  }
  
  private func createConversationsDirectoryIfNeeded() throws {
    guard !fileManager.fileExists(atPath: conversationsDirectory.path) else { return }
    try fileManager.createDirectory(at: conversationsDirectory, withIntermediateDirectories: true)
  }
  
  func saveConversation(_ conversation: Conversation) throws {
    let fileURL = conversationsDirectory.appendingPathComponent("\(conversation.id.uuidString).json")
    let data = try JSONEncoder().encode(conversation)
    try data.write(to: fileURL)
  }
  
  func loadConversation(id: UUID) throws -> Conversation? {
    let fileURL = conversationsDirectory.appendingPathComponent("\(id.uuidString).json")
    guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
    let data = try Data(contentsOf: fileURL)
    return try JSONDecoder().decode(Conversation.self, from: data)
  }
  
  func loadAllConversations() throws -> [Conversation] {
    let fileURLs = try fileManager.contentsOfDirectory(
      at: conversationsDirectory,
      includingPropertiesForKeys: nil,
      options: .skipsHiddenFiles
    )
    
    return try fileURLs.compactMap { fileURL in
      guard fileURL.pathExtension == "json" else { return nil }
      let data = try Data(contentsOf: fileURL)
      return try JSONDecoder().decode(Conversation.self, from: data)
    }
  }
  
  func deleteConversation(id: UUID) throws {
    let fileURL = conversationsDirectory.appendingPathComponent("\(id.uuidString).json")
    try fileManager.removeItem(at: fileURL)
  }
}
