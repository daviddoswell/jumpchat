import Foundation

protocol StorageService {
    func saveConversation(_ conversation: Conversation) throws
    func loadConversation(id: UUID) throws -> Conversation?
    func loadAllConversations() throws -> [Conversation]
    func deleteConversation(id: UUID) throws
    func saveLastActiveConversation(id: UUID) throws
    func loadLastActiveConversation() throws -> UUID?
}

class LocalStorageService: StorageService {
    private let fileManager = FileManager.default
    private let conversationsDirectory: URL
    private let metadataURL: URL
    
    init() throws {
        let documentsDirectory = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        conversationsDirectory = documentsDirectory.appendingPathComponent("Conversations", isDirectory: true)
        metadataURL = documentsDirectory.appendingPathComponent("metadata.json")
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
    
    func saveLastActiveConversation(id: UUID) throws {
        let metadata = ["lastActiveConversation": id.uuidString]
        let data = try JSONEncoder().encode(metadata)
        try data.write(to: metadataURL)
    }
    
    func loadLastActiveConversation() throws -> UUID? {
        guard fileManager.fileExists(atPath: metadataURL.path),
              let data = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder().decode([String: String].self, from: data),
              let idString = metadata["lastActiveConversation"] else {
            return nil
        }
        return UUID(uuidString: idString)
    }
}
