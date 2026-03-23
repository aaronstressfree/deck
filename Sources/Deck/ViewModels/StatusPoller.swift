import Foundation

/// Polls terminal output to detect agent status changes, URLs, and context refresh needs.
/// Extracted from SessionManager for single-responsibility.
@MainActor
final class StatusPoller {
    private var timer: Timer?
    private var urlDetectionCounter = 0
    private var contextRefreshCounter = 0
    private var contextDirty = false
    private var autoOpenedURLs: [UUID: Set<String>] = [:]
    /// Cache last-seen terminal title per session to skip redundant buffer scans
    private var lastSeenTitle: [UUID: String] = [:]

    private weak var sessionManager: SessionManager?

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    deinit {
        timer?.invalidate()
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func markContextDirty() {
        contextDirty = true
    }

    func clearAutoOpenedURLs(for sessionId: UUID) {
        autoOpenedURLs.removeValue(forKey: sessionId)
    }

    // MARK: - Polling tick

    private func tick() {
        guard let sm = sessionManager else { return }

        // Check URL queue from BROWSER handler script
        checkURLQueue(sm: sm)

        // Capture agent session/thread IDs for resume on relaunch
        for i in sm.sessions.indices {
            guard sm.sessions[i].agentSessionId == nil else { continue }
            switch sm.sessions[i].agentType {
            case .claude:
                if let sid = findClaudeSessionId(for: sm.sessions[i].workingDirectory) {
                    sm.sessions[i].agentSessionId = sid
                }
            case .amp:
                if let tid = findAmpThreadId(for: sm.sessions[i].workingDirectory) {
                    sm.sessions[i].agentSessionId = tid
                }
            case .shell:
                break
            }
        }

        // Update agent statuses
        for i in sm.sessions.indices where sm.sessions[i].isRunning {
            guard let controller = sm.terminalControllers[sm.sessions[i].id] else { continue }
            let sessionId = sm.sessions[i].id

            // Agent status parsing (Claude/Amp only)
            if sm.sessions[i].agentType != .shell {
                // Quick check: has the terminal title changed? If not, skip the buffer scan.
                let currentTitle = controller.lastTerminalTitle
                let titleChanged = lastSeenTitle[sessionId] != currentTitle
                lastSeenTitle[sessionId] = currentTitle

                if titleChanged {
                    let output = controller.readRecentOutput()
                    if let status = AgentOutputParser.parseStatus(from: output, agentType: sm.sessions[i].agentType) {
                        if sm.sessions[i].agentStatus != status {
                            sm.sessions[i].agentStatus = status
                            contextDirty = true
                        }
                    }
                }
            }

            // Auto-name from first user prompt — scan buffer once for unnamed sessions
            if sm.sessions[i].name == nil && sm.sessions[i].autoName == "New session" {
                let buffer = controller.readFullVisibleBuffer()
                // Claude Code shows user prompts as "❯ prompt" or "> prompt"
                if let promptMatch = buffer.range(of: #"[❯›>]\s+(.{3,60})"#, options: .regularExpression) {
                    let prompt = String(buffer[promptMatch])
                        .replacingOccurrences(of: #"^[❯›>]\s+"#, with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !prompt.isEmpty && prompt.count >= 3 {
                        // Truncate to first line, max 40 chars
                        let firstLine = prompt.components(separatedBy: .newlines).first ?? prompt
                        let truncated = firstLine.count > 40 ? String(firstLine.prefix(37)) + "..." : firstLine
                        sm.sessions[i].autoName = truncated
                    }
                }
            }

            // URL detection — expensive, only every 5th tick for active session
            if urlDetectionCounter == 0 && sessionId == sm.activeSessionId {
                let fullBuffer = controller.readFullVisibleBuffer()
                detectURLsInOutput(sm: sm, sessionIndex: i, output: fullBuffer)
            }
        }

        urlDetectionCounter = (urlDetectionCounter + 1) % 5

        // Flush dirty context every ~10 seconds
        contextRefreshCounter += 1
        if contextDirty && contextRefreshCounter >= 5 {
            contextDirty = false
            contextRefreshCounter = 0
            let sessions = sm.sessions
            let groups = sm.groups
            let instructions = sm.globalInstructions
            Task.detached(priority: .utility) {
                DeckContext.refreshAll(sessions: sessions, groups: groups, globalInstructions: instructions)
            }
        }
    }

    // MARK: - URL Queue

    private func checkURLQueue(sm: SessionManager) {
        let path = SessionManager.urlQueuePath
        guard FileManager.default.fileExists(atPath: path) else { return }
        guard let content = try? String(contentsOfFile: path, encoding: .utf8),
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        try? Data().write(to: URL(fileURLWithPath: path))

        let urls = content.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let idx = sm.sessions.firstIndex(where: { $0.id == sm.activeSessionId })
        for url in urls {
            sm.openURLInBrowser(url, sessionIndex: idx)
        }
    }

    // MARK: - URL Detection

    private func detectURLsInOutput(sm: SessionManager, sessionIndex i: Int, output: String) {
        let pattern = #"(?:https?://)?(?:localhost|127\.0\.0\.1|0\.0\.0\.0):\d{2,5}[/\w\-._~:?#\[\]@!$&'()*+,;=%]*"#
        guard let match = output.range(of: pattern, options: .regularExpression) else { return }

        let url = String(output[match])
        let sessionId = sm.sessions[i].id

        if autoOpenedURLs[sessionId]?.contains(url) == true { return }
        autoOpenedURLs[sessionId, default: []].insert(url)

        sm.openURLInBrowser(url, sessionIndex: i)
    }

    // MARK: - Agent Session ID Capture

    /// Find the most recent Claude Code session ID for a working directory.
    /// Tries multiple strategies:
    /// 1. Exact cwd match in ~/.claude/sessions/
    /// 2. Parent directory match (Claude might cd into a subdirectory)
    /// 3. Most recent session in the project's git root
    private func findClaudeSessionId(for workingDirectory: String) -> String? {
        let sessionsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/sessions")
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: sessionsDir,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return nil }

        // Parse all session files once
        struct SessionEntry {
            let sessionId: String
            let cwd: String
            let date: Date
        }

        var entries: [SessionEntry] = []
        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let cwd = json["cwd"] as? String,
                  let sessionId = json["sessionId"] as? String else { continue }
            let date = (try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            entries.append(SessionEntry(sessionId: sessionId, cwd: cwd, date: date))
        }

        // Strategy 1: Exact cwd match (most recent)
        if let match = entries.filter({ $0.cwd == workingDirectory }).max(by: { $0.date < $1.date }) {
            return match.sessionId
        }

        // Strategy 2: Git root match — Claude might have cd'd into a subdirectory
        if let gitRoot = GitDetector.rootDirectory(for: workingDirectory) {
            if let match = entries.filter({ $0.cwd.hasPrefix(gitRoot) }).max(by: { $0.date < $1.date }) {
                return match.sessionId
            }
        }

        // Strategy 3: Working directory is a parent of the session's cwd
        if let match = entries.filter({ workingDirectory.hasPrefix($0.cwd) || $0.cwd.hasPrefix(workingDirectory) }).max(by: { $0.date < $1.date }) {
            return match.sessionId
        }

        return nil
    }

    /// Find the most recent Amp thread ID for a working directory.
    /// Scans ~/.amp/file-changes/ directories for thread IDs,
    /// then matches by checking if threads were active in this directory.
    private func findAmpThreadId(for workingDirectory: String) -> String? {
        let fileChangesDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".amp/file-changes")
        guard let threadDirs = try? FileManager.default.contentsOfDirectory(
            at: fileChangesDir,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return nil }

        // Get the most recently modified thread directory
        // Amp thread IDs look like T-019d16e7-c6e5-77a9-be9e-dd5a59f0344b
        var bestThread: (id: String, date: Date)?
        for dir in threadDirs where dir.lastPathComponent.hasPrefix("T-") {
            let date = (try? dir.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let threadId = dir.lastPathComponent
            if bestThread == nil || date > bestThread!.date {
                bestThread = (threadId, date)
            }
        }
        return bestThread?.id
    }
}
