import Foundation

/// A project that organizes sessions (chats) in the sidebar.
/// Each project maps to a codebase (git repo root) and shares context/instructions.
struct SessionGroup: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var isCollapsed: Bool
    var sortOrder: Int
    var instructions: String       // Custom instructions for all sessions in this project
    var workingDirectory: String?  // Git root or project directory (nil = General project)

    init(name: String, sortOrder: Int = 0, workingDirectory: String? = nil) {
        self.id = UUID()
        self.name = name
        self.isCollapsed = false
        self.sortOrder = sortOrder
        self.instructions = ""
        self.workingDirectory = workingDirectory
    }

    /// Whether this is the General (fallback) project
    var isGeneral: Bool { workingDirectory == nil && name == "General" }
}

/// Type alias so the codebase can use the clearer name while maintaining Codable compatibility
typealias Project = SessionGroup
