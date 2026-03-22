import Foundation

/// Persisted application state.
struct AppState: Codable {
    var sessions: [Session]
    var groups: [SessionGroup]
    var activeSessionId: UUID?
    var sidebarWidth: Double
    var sidebarCollapsed: Bool
    var todos: [TodoItem]
    var globalInstructions: String  // Custom instructions for ALL sessions
    var chatModeSessionIds: Set<UUID>?  // nil = old state file, default all to chat mode

    init() {
        self.sessions = []
        self.groups = []
        self.activeSessionId = nil
        self.sidebarWidth = 240
        self.sidebarCollapsed = false
        self.todos = []
        self.globalInstructions = ""
        self.chatModeSessionIds = nil
    }

    /// Storage path for app state
    static var storageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let deckDir = appSupport.appendingPathComponent("Deck", isDirectory: true)
        try? FileManager.default.createDirectory(at: deckDir, withIntermediateDirectories: true)
        return deckDir.appendingPathComponent("state.json")
    }

    /// Load from disk
    static func load() -> AppState {
        guard let data = try? Data(contentsOf: storageURL),
              let state = try? JSONDecoder().decode(AppState.self, from: data) else {
            return AppState()
        }
        return state
    }

    /// Save to disk
    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(self) else { return }
        try? data.write(to: AppState.storageURL)
    }
}
