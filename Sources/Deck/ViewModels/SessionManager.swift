import SwiftUI
import Combine

@MainActor
final class SessionManager: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var groups: [SessionGroup] = []
    @Published var activeSessionId: UUID?
    @Published var sidebarWidth: Double = 240
    @Published var sidebarCollapsed: Bool = false
    @Published var todos: [TodoItem] = []
    @Published var globalInstructions: String = ""

    /// Sessions currently in chat mode (vs raw mode).
    @Published var chatModeSessionIds: Set<UUID> = []

    /// Controllers for each session's terminal
    var terminalControllers: [UUID: TerminalController] = [:]

    /// AI-powered session naming and grouping
    lazy var intelligence = SessionIntelligence(sessionManager: self)

    /// Status polling (agent status, URL detection, context refresh)
    private var statusPoller: StatusPoller?

    /// Path to the URL queue file used by the BROWSER env var handler
    static let urlQueuePath: String = {
        let deckDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".deck")
        try? FileManager.default.createDirectory(at: deckDir, withIntermediateDirectories: true)
        return deckDir.appendingPathComponent("url-queue").path
    }()

    /// Path to the BROWSER handler script
    static let browserScriptPath: String = {
        let deckDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".deck")
        try? FileManager.default.createDirectory(at: deckDir, withIntermediateDirectories: true)
        return deckDir.appendingPathComponent("open-in-deck.sh").path
    }()

    /// Path to the `open` wrapper bin directory
    static let deckBinDir: String = {
        let binDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".deck/bin")
        try? FileManager.default.createDirectory(at: binDir, withIntermediateDirectories: true)
        return binDir.path
    }()

    // MARK: - Lifecycle

    init() {
        loadState()
        BrowserScriptInstaller.install(
            urlQueuePath: Self.urlQueuePath,
            browserScriptPath: Self.browserScriptPath,
            deckBinDir: Self.deckBinDir
        )
        statusPoller = StatusPoller(sessionManager: self)
        statusPoller?.start()
    }

    // Timer cleanup happens when StatusPoller is deallocated

    // MARK: - Chat Mode

    func isChatMode(for sessionId: UUID) -> Bool {
        chatModeSessionIds.contains(sessionId)
    }

    func toggleChatMode(for sessionId: UUID) {
        if chatModeSessionIds.contains(sessionId) {
            chatModeSessionIds.remove(sessionId)
            terminalControllers[sessionId]?.focusTerminal()
        } else {
            chatModeSessionIds.insert(sessionId)
            terminalControllers[sessionId]?.unfocusTerminal()
        }
    }

    // MARK: - Active Session

    var activeSession: Session? {
        sessions.first(where: { $0.id == activeSessionId })
    }

    var activeSessionBinding: Binding<Session>? {
        guard let sessionId = activeSessionId else { return nil }
        return bindingFor(sessionId: sessionId)
    }

    func bindingFor(sessionId: UUID) -> Binding<Session>? {
        guard sessions.contains(where: { $0.id == sessionId }) else { return nil }
        return Binding(
            get: {
                self.sessions.first(where: { $0.id == sessionId }) ?? Session(agentType: .shell)
            },
            set: { newValue in
                if let idx = self.sessions.firstIndex(where: { $0.id == sessionId }) {
                    self.sessions[idx] = newValue
                }
            }
        )
    }

    // MARK: - Session CRUD

    @discardableResult
    func createSession(
        agentType: AgentType,
        workingDirectory: String? = nil,
        groupId: UUID? = nil,
        name: String? = nil
    ) -> Session {
        let cwd = workingDirectory
            ?? activeSession?.workingDirectory
            ?? FileManager.default.homeDirectoryForCurrentUser.path

        let resolvedGroupId = groupId ?? resolveProject(for: cwd).id

        var session = Session(agentType: agentType, workingDirectory: cwd, groupId: resolvedGroupId, name: name)
        session.isRunning = true

        let controller = TerminalController()
        terminalControllers[session.id] = controller
        chatModeSessionIds.insert(session.id)

        sessions.append(session)
        activeSessionId = session.id

        refreshContext()
        saveState()
        intelligence.scheduleNaming(for: session.id)

        return session
    }

    func closeSession(id: UUID) {
        if let session = sessions.first(where: { $0.id == id }) {
            DeckContext.remove(from: session.workingDirectory)
        }

        if activeSessionId == id {
            let remaining = sessions.filter { $0.id != id }
            activeSessionId = remaining.last?.id
        }

        sessions.removeAll(where: { $0.id == id })
        terminalControllers.removeValue(forKey: id)
        chatModeSessionIds.remove(id)
        statusPoller?.clearAutoOpenedURLs(for: id)

        if sessions.isEmpty {
            ChatInputView.cleanupTempImages()
        }

        refreshContext()
        saveState()
    }

    func switchToSession(id: UUID) {
        guard sessions.contains(where: { $0.id == id }) else { return }
        activeSessionId = id
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            sessions[index].lastActiveAt = Date()
        }
        saveStateDebounced()
    }

    func renameSession(id: UUID, name: String?) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        // Empty or nil = clear manual name (revert to AI-generated name)
        sessions[index].name = (name?.isEmpty == true) ? nil : name
        saveState()
        refreshContext()
    }

    func moveSession(id: UUID, toGroup groupId: UUID?) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].groupId = groupId
        saveState()
    }

    /// Reorder sessions within a group by moving from one set of indices to a destination
    func reorderSessions(inGroup groupId: UUID, from source: IndexSet, to destination: Int) {
        // Get the sessions in this group (in their current order within the flat array)
        var groupSessions = sessions.filter { $0.groupId == groupId }
        groupSessions.move(fromOffsets: source, toOffset: destination)

        // Rebuild the flat sessions array preserving non-group session positions
        var result: [Session] = []
        var groupIterator = groupSessions.makeIterator()
        for session in sessions {
            if session.groupId == groupId {
                if let next = groupIterator.next() {
                    result.append(next)
                }
            } else {
                result.append(session)
            }
        }
        sessions = result
        saveStateDebounced()
    }

    func controllerFor(sessionId: UUID) -> TerminalController {
        if let existing = terminalControllers[sessionId] {
            return existing
        }
        let controller = TerminalController()
        terminalControllers[sessionId] = controller
        return controller
    }

    // MARK: - Browser URL Routing (called by StatusPoller)

    func openURLInBrowser(_ rawURL: String, sessionIndex: Int?) {
        guard let i = sessionIndex else { return }

        var url = rawURL
        if !url.hasPrefix("http://") && !url.hasPrefix("https://") && !url.hasPrefix("file://") {
            url = "http://" + url
        }

        let title = URL(string: url)?.host ?? url

        if sessions[i].browserTabs.isEmpty || sessions[i].browserTabs.allSatisfy({ $0.url == "about:blank" }) {
            if let idx = sessions[i].browserTabs.firstIndex(where: { $0.url == "about:blank" }) {
                sessions[i].browserTabs[idx].url = url
                sessions[i].browserTabs[idx].title = title
                sessions[i].activeBrowserTabId = sessions[i].browserTabs[idx].id
            } else {
                let tab = BrowserTab(url: url, title: title)
                sessions[i].browserTabs.append(tab)
                sessions[i].activeBrowserTabId = tab.id
            }
        } else {
            let tab = BrowserTab(url: url, title: title)
            sessions[i].browserTabs.append(tab)
            sessions[i].activeBrowserTabId = tab.id
        }

        sessions[i].browserVisible = true
    }

    // MARK: - Context

    func refreshContext() {
        statusPoller?.markContextDirty()
        DeckContext.refreshAll(sessions: sessions, groups: groups, globalInstructions: globalInstructions)
    }

    // MARK: - Project Resolution

    func resolveProject(for workingDirectory: String) -> SessionGroup {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let projectDir = GitDetector.rootDirectory(for: workingDirectory) ?? workingDirectory

        if projectDir == home {
            return ensureGeneralProject()
        }

        if let existing = groups.first(where: { $0.workingDirectory == projectDir }) {
            return existing
        }

        let name = URL(fileURLWithPath: projectDir).lastPathComponent
        return createGroup(name: name, workingDirectory: projectDir)
    }

    @discardableResult
    func ensureGeneralProject() -> SessionGroup {
        if let general = groups.first(where: { $0.isGeneral }) {
            return general
        }
        return createGroup(name: "General", workingDirectory: nil)
    }

    var activeProject: SessionGroup? {
        guard let session = activeSession else { return nil }
        return groups.first(where: { $0.id == session.groupId })
    }

    // MARK: - Project CRUD

    @discardableResult
    func createGroup(name: String, workingDirectory: String? = nil) -> SessionGroup {
        let group = SessionGroup(name: name, sortOrder: groups.count, workingDirectory: workingDirectory)
        groups.append(group)
        saveState()
        return group
    }

    func renameGroup(id: UUID, name: String) {
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }
        groups[index].name = name
        saveState()
    }

    func updateGroupInstructions(id: UUID, instructions: String) {
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }
        groups[index].instructions = instructions
        saveState()
        refreshContext()
    }

    func updateGroupWorkingDirectory(id: UUID, workingDirectory: String?) {
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }
        groups[index].workingDirectory = workingDirectory
        saveState()
        refreshContext()
    }

    func deleteGroup(id: UUID) {
        if let group = groups.first(where: { $0.id == id }), group.isGeneral { return }
        let generalId = ensureGeneralProject().id
        for i in sessions.indices {
            if sessions[i].groupId == id {
                sessions[i].groupId = generalId
            }
        }
        groups.removeAll(where: { $0.id == id })
        saveState()
    }

    func toggleGroupCollapsed(id: UUID) {
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }
        groups[index].isCollapsed.toggle()
        saveState()
    }

    // MARK: - Helpers

    func sessionsIn(group: SessionGroup?) -> [Session] {
        if let group = group {
            return sessions.filter { $0.groupId == group.id }
        } else {
            return ungroupedSessions()
        }
    }

    func ungroupedSessions() -> [Session] {
        let groupIds = Set(groups.map(\.id))
        return sessions.filter { $0.groupId == nil || !groupIds.contains($0.groupId!) }
    }

    var recentSessions: [Session] {
        Array(sessions.sorted(by: { $0.lastActiveAt > $1.lastActiveAt }).prefix(5))
    }

    // MARK: - Persistence

    func saveStatePublic() { saveState() }

    private var saveDebounceTask: DispatchWorkItem?

    private func saveStateDebounced() {
        saveDebounceTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            Task { @MainActor in self?.saveState() }
        }
        saveDebounceTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
    }

    private func saveState() {
        var state = AppState()
        state.sessions = sessions
        state.groups = groups
        state.activeSessionId = activeSessionId
        state.sidebarWidth = sidebarWidth
        state.sidebarCollapsed = sidebarCollapsed
        state.todos = todos
        state.globalInstructions = globalInstructions
        state.chatModeSessionIds = chatModeSessionIds
        state.save()
    }

    private func loadState() {
        let state = AppState.load()
        sessions = state.sessions
        groups = state.groups
        activeSessionId = state.activeSessionId
        sidebarWidth = state.sidebarWidth
        sidebarCollapsed = state.sidebarCollapsed
        todos = state.todos
        globalInstructions = state.globalInstructions

        if let savedIds = state.chatModeSessionIds {
            chatModeSessionIds = savedIds
        } else {
            chatModeSessionIds = Set(sessions.map(\.id))
        }

        // Reset all sessions — processes died with the old app instance.
        for i in sessions.indices {
            sessions[i].isRunning = false
            sessions[i].agentStatus = .idle
            sessions[i].exitCode = nil

            // Validate saved agentSessionId — clear if conversation no longer exists
            if let sid = sessions[i].agentSessionId, sessions[i].agentType == .claude {
                if !claudeSessionExists(sid, workingDirectory: sessions[i].workingDirectory) {
                    sessions[i].agentSessionId = nil
                }
            }
        }

        migrateToProjectFirst()
    }

    /// Check if a Claude session ID still has a valid conversation on disk.
    private func claudeSessionExists(_ sessionId: String, workingDirectory: String) -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser
        // Claude stores conversations in ~/.claude/projects/<encoded-path>/<sessionId>.jsonl
        let encodedPath = workingDirectory.replacingOccurrences(of: "/", with: "-")
        let projectDir = home.appendingPathComponent(".claude/projects/\(encodedPath)")
        let conversationFile = projectDir.appendingPathComponent("\(sessionId).jsonl")
        return FileManager.default.fileExists(atPath: conversationFile.path)
    }

    private func migrateToProjectFirst() {
        ensureGeneralProject()
        for i in sessions.indices {
            let hasValidProject = sessions[i].groupId != nil
                && groups.contains(where: { $0.id == sessions[i].groupId })
            if !hasValidProject {
                let project = resolveProject(for: sessions[i].workingDirectory)
                sessions[i].groupId = project.id
            }
        }
        for i in groups.indices {
            if groups[i].workingDirectory == nil && !groups[i].isGeneral {
                if let session = sessions.first(where: { $0.groupId == groups[i].id }) {
                    groups[i].workingDirectory = GitDetector.rootDirectory(for: session.workingDirectory)
                        ?? session.workingDirectory
                }
            }
        }
        saveState()
    }
}
