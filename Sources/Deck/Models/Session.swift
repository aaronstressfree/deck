import Foundation

/// A terminal session — the core unit of work in Deck.
/// Each session has its own PTY, agent type, and associated state.
struct Session: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String?               // Manual name, nil = use autoName
    var autoName: String             // System-generated name
    var groupId: UUID?               // Which project this session belongs to (kept as groupId for Codable compat)

    /// Alias for groupId — sessions belong to projects
    var projectId: UUID? {
        get { groupId }
        set { groupId = newValue }
    }
    var agentType: AgentType
    var agentStatus: AgentStatus

    var workingDirectory: String
    var gitBranch: String?
    var isRunning: Bool
    var exitCode: Int?

    var lastActiveAt: Date
    let createdAt: Date

    var scrollbackPath: String?      // Path to saved scrollback data
    var lastConversationSummary: String?  // Brief summary of last session, auto-sent on relaunch
    var intentText: String?          // Pinned intent for this session

    var checkpoints: [Checkpoint]

    // Browser state — each session owns its browser tabs
    var browserTabs: [BrowserTab]
    var activeBrowserTabId: UUID?
    var browserVisible: Bool
    var browserSplitRatio: Double    // 0.0-1.0, portion allocated to terminal

    // Agent-specific options
    var claudeModel: String?         // --model flag for Claude
    var claudeContinue: Bool         // --continue flag for Claude
    var agentSessionId: String?      // Claude/Amp session ID for --resume on relaunch

    /// Display name: manual name or auto-generated name
    var displayName: String {
        name ?? autoName
    }

    init(
        agentType: AgentType,
        workingDirectory: String = FileManager.default.homeDirectoryForCurrentUser.path,
        groupId: UUID? = nil,
        name: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.agentType = agentType
        self.agentStatus = .idle
        self.workingDirectory = workingDirectory
        self.groupId = groupId
        self.isRunning = false
        self.exitCode = nil
        self.lastActiveAt = Date()
        self.createdAt = Date()
        self.scrollbackPath = nil
        self.intentText = nil
        self.checkpoints = []
        self.browserTabs = []
        self.activeBrowserTabId = nil
        self.browserVisible = false
        self.browserSplitRatio = 0.6
        self.claudeModel = nil
        self.claudeContinue = false

        // Generate initial auto-name
        let dirName = URL(fileURLWithPath: workingDirectory).lastPathComponent
        let home = FileManager.default.homeDirectoryForCurrentUser.lastPathComponent
        // Use directory name if meaningful, otherwise "New session"
        if dirName != home && !dirName.isEmpty {
            self.autoName = dirName
        } else {
            self.autoName = "New session"
        }
    }
}
