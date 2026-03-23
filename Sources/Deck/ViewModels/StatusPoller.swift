import Foundation

/// Polls terminal output to detect agent status changes, URLs, and context refresh needs.
/// Extracted from SessionManager for single-responsibility.
@MainActor
final class StatusPoller {
    private var urlDetectionCounter = 0
    private var contextRefreshCounter = 0
    private var contextDirty = false
    private var summaryCounter = 0
    private var autoOpenedURLs: [UUID: Set<String>] = [:]
    /// Cache last-seen terminal title per session to skip redundant buffer scans
    private var lastSeenTitle: [UUID: String] = [:]
    /// Timestamp of when this poller started — only use session files newer than this
    private let startedAt = Date()

    private weak var sessionManager: SessionManager?

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    deinit {}

    func start() {
        scheduleTick()
    }

    private func scheduleTick() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self else { return }
            self.tick()
            self.scheduleTick() // Reschedule
        }
    }

    func stop() {
        // DispatchQueue-based polling stops when weak self becomes nil
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
        var capturedNewId = false
        for i in sm.sessions.indices {
            guard sm.sessions[i].agentSessionId == nil else { continue }
            switch sm.sessions[i].agentType {
            case .claude:
                if let sid = findClaudeSessionId(for: sm.sessions[i].workingDirectory) {
                    sm.sessions[i].agentSessionId = sid
                    capturedNewId = true
                }
            case .amp:
                if let tid = findAmpThreadId(for: sm.sessions[i].workingDirectory) {
                    sm.sessions[i].agentSessionId = tid
                    capturedNewId = true
                }
            case .shell:
                break
            }
        }
        // Persist captured IDs so they survive a crash/force-quit
        if capturedNewId {
            sm.saveStatePublic()
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

        // Save conversation summaries every ~30 seconds for session context persistence.
        // This ensures intentText has recent prompts even if the app is force-quit.
        summaryCounter += 1
        // Summary save removed from here — handled in TerminalContainerView
        if summaryCounter >= 15 {
            summaryCounter = 0
            saveConversationSummaries(sm: sm)
        }
    }

    // MARK: - Conversation Summary

    private func saveConversationSummaries(sm: SessionManager) {
        var changed = false
        for i in sm.sessions.indices {
            guard sm.sessions[i].agentType != .shell else { continue }
            guard let controller = sm.terminalControllers[sm.sessions[i].id] else { continue }

            let buffer = controller.readFullVisibleBuffer()
            let summary = Self.extractSummary(from: buffer)
            guard !summary.isEmpty else { continue }

            // Only update if summary changed
            if sm.sessions[i].lastConversationSummary != summary {
                sm.sessions[i].lastConversationSummary = summary
                // Set as intentText if user hasn't written their own
                let existing = sm.sessions[i].intentText ?? ""
                if existing.isEmpty || existing.hasPrefix("Recent prompts") {
                    sm.sessions[i].intentText = summary
                    changed = true
                }
            }
        }
        if changed {
            sm.saveStatePublic()
        }
    }

    /// Extract recent user prompts from terminal buffer for session context
    static func extractSummary(from buffer: String) -> String {
        let lines = buffer.components(separatedBy: "\n")
        var prompts: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("❯ ") || trimmed.hasPrefix("> ") || trimmed.hasPrefix("› ") {
                let prompt = trimmed
                    .replacingOccurrences(of: "^[❯>›]\\s+", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                if !prompt.isEmpty && prompt.count > 2 {
                    prompts.append(prompt)
                }
            }
        }

        let recent = prompts.suffix(3)
        guard !recent.isEmpty else { return "" }

        return "Recent prompts from previous session:\n" +
            recent.map { "- \($0)" }.joined(separator: "\n") +
            "\nPick up where we left off if relevant."
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

    /// Find the best Claude Code session ID for a working directory.
    /// Two-phase strategy:
    /// 1. Check live session files (from THIS launch) — active conversation
    /// 2. Fall back to most recent conversation FILE in the project dir — resumable history
    private func findClaudeSessionId(for workingDirectory: String) -> String? {
        let home = FileManager.default.homeDirectoryForCurrentUser

        // Phase 1: Live session files from this launch
        let sessionsDir = home.appendingPathComponent(".claude/sessions")
        if let files = try? FileManager.default.contentsOfDirectory(at: sessionsDir, includingPropertiesForKeys: [.contentModificationDateKey]) {
            var best: (id: String, date: Date)?
            for file in files where file.pathExtension == "json" {
                guard let data = try? Data(contentsOf: file),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let cwd = json["cwd"] as? String,
                      let sessionId = json["sessionId"] as? String else { continue }
                let date = (try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                // Only from this launch
                guard date >= startedAt.addingTimeInterval(-5) else { continue }
                if cwd == workingDirectory {
                    if best == nil || date > best!.date { best = (sessionId, date) }
                }
            }
            if let match = best { return match.id }
        }

        // Phase 2: Most recent conversation file in the project directory
        // These persist across Claude restarts and are the real resumable history
        let encodedPath = workingDirectory.replacingOccurrences(of: "/", with: "-")
        let projectDir = home.appendingPathComponent(".claude/projects/\(encodedPath)")
        if let files = try? FileManager.default.contentsOfDirectory(at: projectDir, includingPropertiesForKeys: [.contentModificationDateKey]) {
            var best: (id: String, date: Date)?
            for file in files where file.pathExtension == "jsonl" {
                let sessionId = file.deletingPathExtension().lastPathComponent
                // Validate it looks like a UUID
                guard UUID(uuidString: sessionId) != nil else { continue }
                let date = (try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                if best == nil || date > best!.date {
                    best = (sessionId, date)
                }
            }
            if let match = best { return match.id }
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
