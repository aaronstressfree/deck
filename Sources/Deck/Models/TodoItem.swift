import Foundation

/// A to-do item that can be associated with a session.
struct TodoItem: Identifiable, Codable, Hashable {
    let id: UUID
    var text: String
    var isCompleted: Bool
    var sessionId: UUID?  // Optional link to a session
    let createdAt: Date

    init(text: String, sessionId: UUID? = nil) {
        self.id = UUID()
        self.text = text
        self.isCompleted = false
        self.sessionId = sessionId
        self.createdAt = Date()
    }
}
