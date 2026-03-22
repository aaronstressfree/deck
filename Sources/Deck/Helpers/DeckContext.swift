import Foundation

/// Manages context files that give AI agents full awareness of:
/// 1. Deck's tools (browser, checkpoints, etc.)
/// 2. Other active tabs (sibling awareness)
/// 3. Custom instructions (global → project → session hierarchy)
enum DeckContext {
    static let fileName = ".deck-context.md"
    static let claudeMarker = "<!-- deck-context -->"

    /// Context inputs for generating files
    struct ContextInputs {
        let session: Session
        let siblings: [Session]
        let globalInstructions: String
        let groupInstructions: String  // from the session's project, if any
        let sessionContext: String     // from the session's intentText
    }

    // MARK: - Refresh all sessions

    static func refreshAll(sessions: [Session], groups: [SessionGroup], globalInstructions: String) {
        // Include ALL sessions (not just isRunning) — newly spawned sessions need context too
        guard !sessions.isEmpty else { return }

        // Group by working directory since CLAUDE.md is per-directory
        let byDir = Dictionary(grouping: sessions, by: \.workingDirectory)

        for (dir, sessionsInDir) in byDir {
            // For CLAUDE.md: list ALL tabs so every session in this dir sees the full picture.
            // Each session can identify itself by name in the list.
            let allOthersFromDifferentDirs = sessions.filter { $0.workingDirectory != dir }
            let group = groups.first(where: { $0.id == sessionsInDir.first?.groupId })

            let inputs = ContextInputs(
                session: sessionsInDir.first!,
                siblings: allOthersFromDifferentDirs,
                globalInstructions: globalInstructions,
                groupInstructions: group?.instructions ?? "",
                sessionContext: sessionsInDir.first?.intentText ?? ""
            )

            // Write .deck-context.md (full context)
            write(to: dir, inputs: inputs)

            // Write CLAUDE.md block — includes ALL tabs with project-scoped awareness
            appendToClaudeMd(in: dir, allSessions: sessions, sessionsInThisDir: sessionsInDir, groups: groups, inputs: inputs)

            // Write .cursorrules for Cursor/Windsurf
            let rulesUrl = URL(fileURLWithPath: dir).appendingPathComponent(".cursorrules")
            try? generateCompact(inputs: inputs).write(to: rulesUrl, atomically: true, encoding: .utf8)
        }
    }

    static func remove(from directory: String) {
        let url = URL(fileURLWithPath: directory).appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Write files

    private static func write(to directory: String, inputs: ContextInputs) {
        let content = generateFull(inputs: inputs)
        let url = URL(fileURLWithPath: directory).appendingPathComponent(fileName)
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func appendToClaudeMd(in directory: String, allSessions: [Session], sessionsInThisDir: [Session], groups: [SessionGroup], inputs: ContextInputs) {
        let claudeMdUrl = URL(fileURLWithPath: directory).appendingPathComponent("CLAUDE.md")

        // Build the tab awareness block — scoped to projects
        var lines: [String] = []
        lines.append("## Deck Context")
        lines.append("")
        lines.append("You are running inside **Deck**, an AI-first terminal for macOS.")
        lines.append("")

        // Determine which project(s) the sessions in this directory belong to
        let thisProjectId = sessionsInThisDir.first?.groupId
        let thisProject = groups.first(where: { $0.id == thisProjectId })

        // Project siblings — detailed info
        let projectSiblings: [Session]
        if let pid = thisProjectId {
            projectSiblings = allSessions.filter { $0.groupId == pid }
        } else {
            projectSiblings = sessionsInThisDir
        }

        if let project = thisProject {
            lines.append("### Your Project: \(project.name)")
            if !project.instructions.isEmpty {
                lines.append("**Project instructions:** \(project.instructions)")
            }
            lines.append("")
        }

        if projectSiblings.count > 1 {
            lines.append("**Tabs in your project** (\(projectSiblings.count)):")
            for session in projectSiblings {
                let dirName = URL(fileURLWithPath: session.workingDirectory).lastPathComponent
                var desc = "- \(session.agentType.displayName): \(session.displayName) in `\(dirName)`"
                if let ctx = session.intentText, !ctx.isEmpty {
                    desc += " — \(ctx)"
                }
                let statusDesc: String
                if session.isRunning {
                    statusDesc = session.agentStatus == .idle ? "idle" : session.agentStatus.label.lowercased()
                } else {
                    statusDesc = "not started"
                }
                desc += " [\(statusDesc)]"
                let isThisDir = sessionsInThisDir.contains(where: { $0.id == session.id })
                if isThisDir && sessionsInThisDir.count == 1 {
                    desc += " ← **you**"
                }
                lines.append(desc)
            }
            lines.append("")
            lines.append("Coordinate with your project tabs. Don't duplicate their work.")
        }

        // Other projects — brief summary only
        let otherSessions = allSessions.filter { s in
            !projectSiblings.contains(where: { $0.id == s.id })
        }
        if !otherSessions.isEmpty {
            let otherProjects = Dictionary(grouping: otherSessions) { $0.groupId }
            lines.append("")
            lines.append("**Other projects** (\(otherSessions.count) tab(s)):")
            for (projectId, sessions) in otherProjects {
                let projectName = groups.first(where: { $0.id == projectId })?.name ?? "Unassigned"
                let names = sessions.map { $0.displayName }.joined(separator: ", ")
                lines.append("- \(projectName): \(names)")
            }
        }

        // Instructions
        if !inputs.globalInstructions.isEmpty {
            lines.append("")
            lines.append("**Instructions:** \(inputs.globalInstructions)")
        }

        lines.append("")
        lines.append("**Browser (Cmd+B):** localhost preview. **User:** product designer, visual output focus.")
        lines.append("")
        lines.append("**IMPORTANT:** Always open URLs with `$BROWSER \"<url>\"` instead of `open <url>`. Deck intercepts $BROWSER to show previews in its built-in browser pane.")

        let block = "\n\(claudeMarker)\n" + lines.joined(separator: "\n") + "\n\(claudeMarker)\n"

        if FileManager.default.fileExists(atPath: claudeMdUrl.path) {
            if var existing = try? String(contentsOf: claudeMdUrl, encoding: .utf8) {
                // Remove old deck-context block
                if let s = existing.range(of: claudeMarker),
                   let e = existing.range(of: claudeMarker, range: s.upperBound..<existing.endIndex) {
                    existing.removeSubrange(s.lowerBound...e.upperBound)
                }
                existing += block
                try? existing.write(to: claudeMdUrl, atomically: true, encoding: .utf8)
            }
        } else {
            try? block.write(to: claudeMdUrl, atomically: true, encoding: .utf8)
        }
    }

    // MARK: - Full context (.deck-context.md)

    private static func generateFull(inputs: ContextInputs) -> String {
        var lines: [String] = []
        lines.append("# Deck — AI-First Terminal Context")
        lines.append("")
        lines.append("You are running inside **Deck**, an AI-first terminal for macOS.")
        lines.append("")

        // Custom instructions hierarchy
        if !inputs.globalInstructions.isEmpty {
            lines.append("## Global Instructions")
            lines.append(inputs.globalInstructions)
            lines.append("")
        }
        if !inputs.groupInstructions.isEmpty {
            lines.append("## Project Instructions")
            lines.append(inputs.groupInstructions)
            lines.append("")
        }
        if !inputs.sessionContext.isEmpty {
            lines.append("## Session Context")
            lines.append(inputs.sessionContext)
            lines.append("")
        }

        // Siblings
        if !inputs.siblings.isEmpty {
            lines.append("## Other Active Tabs")
            lines.append("")
            for (i, sib) in inputs.siblings.enumerated() {
                let desc = "### Tab \(i + 1): \(sib.displayName)"
                lines.append(desc)
                lines.append("- **Agent:** \(sib.agentType.displayName)")
                lines.append("- **Directory:** \(sib.workingDirectory)")
                if let ctx = sib.intentText, !ctx.isEmpty {
                    lines.append("- **Working on:** \(ctx)")
                }
                lines.append("")
            }
            lines.append("Coordinate: don't duplicate their work, reference it when relevant.")
            lines.append("")
        }

        // Tools
        lines.append("## Tools")
        lines.append("- **Browser (Cmd+B):** Split preview for localhost. Device frames: Desktop/Tablet/Phone.")
        lines.append("- **Context panel:** User can pin instructions visible to you.")
        lines.append("- **Checkpoints:** User can snapshot and restore state.")
        lines.append("")
        lines.append("## Opening URLs")
        lines.append("**IMPORTANT:** Always open URLs with `$BROWSER \"<url>\"` instead of `open <url>`.")
        lines.append("Deck intercepts $BROWSER to show previews in its built-in browser pane.")
        lines.append("The $BROWSER env var is pre-configured in your environment.")
        lines.append("")
        lines.append("## User")
        lines.append("Product designer at Block. Prioritize visual output. Suggest browser preview.")

        return lines.joined(separator: "\n")
    }

    // MARK: - Compact context (CLAUDE.md / .cursorrules)

    private static func generateCompact(inputs: ContextInputs) -> String {
        var lines: [String] = []
        lines.append("## Deck Context")
        lines.append("")

        // Instructions
        if !inputs.globalInstructions.isEmpty {
            lines.append("**Instructions:** \(inputs.globalInstructions)")
            lines.append("")
        }
        if !inputs.groupInstructions.isEmpty {
            lines.append("**Project instructions:** \(inputs.groupInstructions)")
            lines.append("")
        }
        if !inputs.sessionContext.isEmpty {
            lines.append("**Session context:** \(inputs.sessionContext)")
            lines.append("")
        }

        // Siblings
        if !inputs.siblings.isEmpty {
            lines.append("**Other tabs:**")
            for sib in inputs.siblings {
                var desc = "- \(sib.displayName) (\(sib.agentType.displayName)) in `\(URL(fileURLWithPath: sib.workingDirectory).lastPathComponent)`"
                if let ctx = sib.intentText, !ctx.isEmpty { desc += " — \(ctx)" }
                lines.append(desc)
            }
            lines.append("")
            lines.append("Coordinate with other tabs. Don't duplicate their work.")
            lines.append("")
        }

        lines.append("**Browser (Cmd+B):** localhost preview. **User:** product designer, visual output focus.")
        lines.append("")
        lines.append("**IMPORTANT:** Always open URLs with `$BROWSER \"<url>\"` instead of `open <url>`. Deck intercepts $BROWSER to show previews in its built-in browser pane.")

        return lines.joined(separator: "\n")
    }

    /// Generate a preview of ALL context being sent — for the settings/visibility view.
    static func previewContext(session: Session, siblings: [Session], groups: [SessionGroup], globalInstructions: String) -> String {
        let group = groups.first(where: { $0.id == session.groupId })
        let inputs = ContextInputs(
            session: session,
            siblings: siblings,
            globalInstructions: globalInstructions,
            groupInstructions: group?.instructions ?? "",
            sessionContext: session.intentText ?? ""
        )
        return generateFull(inputs: inputs)
    }
}
