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

    /// Sessions currently in chat mode (vs raw mode). Shell sessions default to chat, Claude/Amp to raw.
    @Published var chatModeSessionIds: Set<UUID> = []

    /// Controllers for each session's terminal
    var terminalControllers: [UUID: TerminalController] = [:]

    /// AI-powered session naming and grouping
    lazy var intelligence = SessionIntelligence(sessionManager: self)

    func isChatMode(for sessionId: UUID) -> Bool {
        chatModeSessionIds.contains(sessionId)
    }

    func toggleChatMode(for sessionId: UUID) {
        if chatModeSessionIds.contains(sessionId) {
            chatModeSessionIds.remove(sessionId)
            // Switching to raw mode — focus the terminal
            terminalControllers[sessionId]?.focusTerminal()
        } else {
            chatModeSessionIds.insert(sessionId)
            // Switching to chat mode — unfocus the terminal
            terminalControllers[sessionId]?.unfocusTerminal()
        }
    }

    private var statusTimer: Timer?

    /// Tracks whether tab context needs to be re-written (status change, rename, etc.)
    private var contextDirty = false
    /// Debounce counter to avoid writing context on every status poll tick
    private var contextRefreshCounter = 0

    /// URLs already auto-opened per session, to avoid re-triggering on repeated polls
    private var autoOpenedURLs: [UUID: Set<String>] = [:]

    /// Path to the URL queue file used by the BROWSER env var handler
    static let urlQueuePath: String = {
        let deckDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".deck")
        try? FileManager.default.createDirectory(at: deckDir, withIntermediateDirectories: true)
        return deckDir.appendingPathComponent("url-queue").path
    }()

    /// Path to the BROWSER handler script
    static let browserScriptPath: String = {
        let deckDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".deck")
        try? FileManager.default.createDirectory(at: deckDir, withIntermediateDirectories: true)
        return deckDir.appendingPathComponent("open-in-deck.sh").path
    }()

    /// Path to the `open` wrapper that intercepts URL opens
    static let deckBinDir: String = {
        let binDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".deck/bin")
        try? FileManager.default.createDirectory(at: binDir, withIntermediateDirectories: true)
        return binDir.path
    }()

    init() {
        loadState()
        installBrowserScripts()
        startStatusPolling()
    }

    /// Install scripts that route URLs to Deck's browser pane:
    /// 1. `open-in-deck.sh` — BROWSER env var handler
    /// 2. `~/.deck/bin/open` — wrapper that intercepts `open <url>` and routes to Deck
    private func installBrowserScripts() {
        // BROWSER handler
        let browserScript = """
        #!/bin/bash
        echo "$1" >> "\(Self.urlQueuePath)"
        """
        try? browserScript.write(toFile: Self.browserScriptPath, atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: Self.browserScriptPath
        )

        // Smart `open` wrapper — intercepts URLs, passes everything else to real open
        let openWrapper = """
        #!/bin/bash
        # Deck's open wrapper: routes http/https URLs to Deck's browser pane.
        # Non-URL arguments (files, apps, flags) pass through to /usr/bin/open.

        is_url=false
        url_arg=""

        for arg in "$@"; do
            case "$arg" in
                http://*|https://*)
                    is_url=true
                    url_arg="$arg"
                    ;;
            esac
        done

        if $is_url && [ -n "$url_arg" ]; then
            echo "$url_arg" >> "\(Self.urlQueuePath)"
        else
            /usr/bin/open "$@"
        fi
        """
        let openPath = Self.deckBinDir + "/open"
        try? openWrapper.write(toFile: openPath, atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: openPath
        )
    }

    /// Poll terminal output to detect agent status changes.
    /// 2s interval balances responsiveness with CPU usage at 20+ tabs.
    private func startStatusPolling() {
        statusTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateAgentStatuses()
            }
        }
    }

    /// Counter for staggering expensive URL detection (not needed every tick)
    private var urlDetectionCounter = 0

    private func updateAgentStatuses() {
        // Check URL queue from BROWSER handler script
        checkURLQueue()

        for i in sessions.indices where sessions[i].isRunning {
            guard let controller = terminalControllers[sessions[i].id] else { continue }
            let output = controller.readRecentOutput()

            // Agent status parsing (Claude/Amp only)
            if sessions[i].agentType != .shell {
                if let status = AgentOutputParser.parseStatus(from: output, agentType: sessions[i].agentType) {
                    if sessions[i].agentStatus != status {
                        sessions[i].agentStatus = status
                        contextDirty = true
                    }
                }
            }

            // URL detection uses full buffer — expensive, so only run every 5th tick (~10s)
            // and only for the active session (most likely to have new URLs)
            if urlDetectionCounter == 0 && sessions[i].id == activeSessionId {
                let fullBuffer = controller.readFullVisibleBuffer()
                detectURLsInOutput(sessionIndex: i, output: fullBuffer)
            }
        }

        urlDetectionCounter = (urlDetectionCounter + 1) % 5

        // Flush dirty context every ~10 seconds (every 5 ticks of the 2s timer)
        contextRefreshCounter += 1
        if contextDirty && contextRefreshCounter >= 5 {
            contextDirty = false
            contextRefreshCounter = 0
            // Write context off the main thread
            let sessions = self.sessions
            let groups = self.groups
            let instructions = self.globalInstructions
            Task.detached(priority: .utility) {
                DeckContext.refreshAll(sessions: sessions, groups: groups, globalInstructions: instructions)
            }
        }
    }

    /// Check the URL queue file for URLs routed via the BROWSER env var handler.
    /// Opens them in the active session's browser pane.
    private func checkURLQueue() {
        let path = Self.urlQueuePath
        guard FileManager.default.fileExists(atPath: path) else { return }
        guard let content = try? String(contentsOfFile: path, encoding: .utf8),
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Clear the queue immediately to avoid re-processing
        try? Data().write(to: URL(fileURLWithPath: path))

        let urls = content.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let idx = sessions.firstIndex(where: { $0.id == activeSessionId })
        for url in urls {
            openURLInBrowser(url, sessionIndex: idx)
        }
    }

    /// Detect localhost/dev server URLs in terminal output and auto-open in browser.
    private func detectURLsInOutput(sessionIndex i: Int, output: String) {
        // Match localhost, 127.0.0.1, and 0.0.0.0 URLs with optional protocol prefix and path
        let pattern = #"(?:https?://)?(?:localhost|127\.0\.0\.1|0\.0\.0\.0):\d{2,5}[/\w\-._~:?#\[\]@!$&'()*+,;=%]*"#
        guard let match = output.range(of: pattern, options: .regularExpression) else { return }

        let url = String(output[match])
        let sessionId = sessions[i].id

        // Skip if we've already auto-opened this URL for this session
        if autoOpenedURLs[sessionId]?.contains(url) == true { return }
        autoOpenedURLs[sessionId, default: []].insert(url)

        openURLInBrowser(url, sessionIndex: i)
    }

    /// Open a URL in a session's browser pane, creating or reusing tabs as needed.
    private func openURLInBrowser(_ rawURL: String, sessionIndex: Int?) {
        guard let i = sessionIndex else { return }

        var url = rawURL
        if !url.hasPrefix("http://") && !url.hasPrefix("https://") && !url.hasPrefix("file://") {
            url = "http://" + url
        }

        let title = URL(string: url)?.host ?? url

        if sessions[i].browserTabs.isEmpty || sessions[i].browserTabs.allSatisfy({ $0.url == "about:blank" }) {
            // No real tabs yet — create or reuse the blank tab
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
            // Browser already has tabs — add a new one
            let tab = BrowserTab(url: url, title: title)
            sessions[i].browserTabs.append(tab)
            sessions[i].activeBrowserTabId = tab.id
        }

        sessions[i].browserVisible = true
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
        // Inherit working directory from active session if not specified
        let cwd = workingDirectory
            ?? activeSession?.workingDirectory
            ?? FileManager.default.homeDirectoryForCurrentUser.path

        // Auto-resolve project if none specified
        let resolvedGroupId = groupId ?? resolveProject(for: cwd).id

        var session = Session(agentType: agentType, workingDirectory: cwd, groupId: resolvedGroupId, name: name)
        session.isRunning = true

        let controller = TerminalController()
        terminalControllers[session.id] = controller

        // All sessions default to chat mode
        chatModeSessionIds.insert(session.id)

        sessions.append(session)
        activeSessionId = session.id

        // Write context for ALL sessions — each tab knows about siblings
        refreshContext()

        saveState()

        // Trigger AI naming after a brief delay
        intelligence.scheduleNaming(for: session.id)

        return session
    }

    func closeSession(id: UUID) {
        // Clean up context file
        if let session = sessions.first(where: { $0.id == id }) {
            DeckContext.remove(from: session.workingDirectory)
        }

        // Update active session FIRST, before removing, to avoid stale binding access
        if activeSessionId == id {
            let remaining = sessions.filter { $0.id != id }
            activeSessionId = remaining.last?.id
        }

        sessions.removeAll(where: { $0.id == id })
        terminalControllers.removeValue(forKey: id)
        chatModeSessionIds.remove(id)
        autoOpenedURLs.removeValue(forKey: id)

        // Refresh context for remaining sessions — they need updated sibling info
        refreshContext()

        saveState()
    }

    /// Refresh tab awareness context for all sessions
    func refreshContext() {
        DeckContext.refreshAll(sessions: sessions, groups: groups, globalInstructions: globalInstructions)
    }

    func switchToSession(id: UUID) {
        guard sessions.contains(where: { $0.id == id }) else { return }
        activeSessionId = id

        // Update last active time
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            sessions[index].lastActiveAt = Date()
        }
        saveStateDebounced()
    }

    func renameSession(id: UUID, name: String?) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].name = name
        saveState()
        refreshContext()
    }

    func moveSession(id: UUID, toGroup groupId: UUID?) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].groupId = groupId
        saveState()
    }

    func controllerFor(sessionId: UUID) -> TerminalController {
        if let existing = terminalControllers[sessionId] {
            return existing
        }
        let controller = TerminalController()
        terminalControllers[sessionId] = controller
        return controller
    }

    // MARK: - Project Resolution

    /// Find or create the project for a given working directory.
    /// Uses git root detection — deterministic, no AI calls.
    func resolveProject(for workingDirectory: String) -> SessionGroup {
        let home = FileManager.default.homeDirectoryForCurrentUser.path

        // Detect git root
        let projectDir = GitDetector.rootDirectory(for: workingDirectory) ?? workingDirectory

        // Home directory with no git repo → General project
        if projectDir == home {
            return ensureGeneralProject()
        }

        // Find existing project with matching workingDirectory
        if let existing = groups.first(where: { $0.workingDirectory == projectDir }) {
            return existing
        }

        // Auto-create project named after the directory
        let name = URL(fileURLWithPath: projectDir).lastPathComponent
        return createGroup(name: name, workingDirectory: projectDir)
    }

    /// Ensure the General (fallback) project exists. Returns it.
    @discardableResult
    func ensureGeneralProject() -> SessionGroup {
        if let general = groups.first(where: { $0.isGeneral }) {
            return general
        }
        return createGroup(name: "General", workingDirectory: nil)
    }

    /// The active project (project of the active session)
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

    func deleteGroup(id: UUID) {
        // Can't delete the General project
        if let group = groups.first(where: { $0.id == id }), group.isGeneral { return }

        // Move sessions to General (never orphan them)
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
            return sessions.filter { $0.groupId == nil || !groups.contains(where: { $0.id == $0.id }) }
        }
    }

    func ungroupedSessions() -> [Session] {
        let groupIds = Set(groups.map(\.id))
        return sessions.filter { $0.groupId == nil || !groupIds.contains($0.groupId!) }
    }

    /// Recent sessions for the landing screen
    var recentSessions: [Session] {
        Array(sessions.sorted(by: { $0.lastActiveAt > $1.lastActiveAt }).prefix(5))
    }

    // MARK: - Persistence

    /// Public entry point for SessionIntelligence to persist changes.
    func saveStatePublic() { saveState() }

    private var saveDebounceTask: DispatchWorkItem?

    /// Debounced save — coalesces rapid changes (e.g. fast tab switching) into a single disk write.
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

        // Restore chat mode state. For old state files without this field,
        // default all sessions to chat mode (matching createSession behavior).
        if let savedIds = state.chatModeSessionIds {
            chatModeSessionIds = savedIds
        } else {
            chatModeSessionIds = Set(sessions.map(\.id))
        }

        // Mark all sessions as not running (they were from a previous launch)
        for i in sessions.indices {
            sessions[i].isRunning = false
            sessions[i].agentStatus = .idle
        }

        // Migrate to project-first model
        migrateToProjectFirst()
    }

    /// Ensure every session belongs to a project and every project has a workingDirectory.
    /// Idempotent — safe to run on every launch.
    private func migrateToProjectFirst() {
        // Ensure General project exists
        ensureGeneralProject()

        // Assign orphaned sessions to projects based on their working directory
        for i in sessions.indices {
            let hasValidProject = sessions[i].groupId != nil
                && groups.contains(where: { $0.id == sessions[i].groupId })
            if !hasValidProject {
                let project = resolveProject(for: sessions[i].workingDirectory)
                sessions[i].groupId = project.id
            }
        }

        // Backfill workingDirectory on existing projects that lack one
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
