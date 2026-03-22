import Foundation
import SwiftUI

/// AI-powered session naming and project name enhancement.
/// These are progressive enhancements — the app works fully without an API key.
/// Projects are resolved deterministically by git root; AI just makes names nicer.
@MainActor
final class SessionIntelligence {

    private unowned let sessionManager: SessionManager

    /// Cooldown tracking
    private var lastNamedAt: [UUID: Date] = [:]
    private var enhancedProjectIds: Set<UUID> = []

    /// Queued session IDs waiting to be named (batched after delay)
    private var pendingNaming: Set<UUID> = []

    private let namingCooldown: TimeInterval = 120   // 2 min between renames
    private let namingDelay: TimeInterval = 5        // wait 5s after session creation

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    // MARK: - Public API

    /// Schedule naming for a newly created session. Waits a few seconds
    /// to let the process start and initial output appear.
    func scheduleNaming(for sessionId: UUID) {
        // Skip entirely if no API key — auto-generated names are fine
        guard APIKeyStore.hasKey else { return }

        pendingNaming.insert(sessionId)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(namingDelay * 1_000_000_000))

            guard !pendingNaming.isEmpty else { return }
            let batch = pendingNaming
            pendingNaming.removeAll()

            for id in batch {
                await nameSession(id)
            }

            // Also try to enhance the project name if it's just a directory name
            await enhanceProjectNames()
        }
    }

    // MARK: - Session Naming

    private func nameSession(_ sessionId: UUID) async {
        guard APIKeyStore.hasKey else { return }

        // Skip if user manually named it
        guard let session = sessionManager.sessions.first(where: { $0.id == sessionId }),
              session.name == nil else { return }

        // Skip if recently named
        if let lastNamed = lastNamedAt[sessionId],
           Date().timeIntervalSince(lastNamed) < namingCooldown { return }

        let system = """
        You name terminal sessions in a developer tool. Based on the context, \
        produce a short, descriptive name (2-5 words). Do NOT include prefixes \
        like "Claude:" or "Shell:" — those are added automatically. Focus on \
        WHAT the user is working on: the project, feature, or task. \
        Respond with ONLY the name, nothing else.
        """

        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        let relativeCWD = session.workingDirectory.hasPrefix(homePath)
            ? "~" + session.workingDirectory.dropFirst(homePath.count)
            : session.workingDirectory

        var context = """
        Agent type: \(session.agentType.displayName)
        Working directory: \(relativeCWD)
        """
        if let branch = session.gitBranch {
            context += "\nGit branch: \(branch)"
        }

        do {
            let suggestedName = try await AnthropicClient.complete(
                system: system,
                userMessage: context,
                maxTokens: 30
            )

            let cleaned = suggestedName
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'`."))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !cleaned.isEmpty,
                  let index = sessionManager.sessions.firstIndex(where: { $0.id == sessionId }),
                  sessionManager.sessions[index].name == nil
            else { return }

            withAnimation(.easeInOut(duration: 0.3)) {
                sessionManager.sessions[index].autoName = "\(session.agentType.namePrefix): \(cleaned)"
            }
            lastNamedAt[sessionId] = Date()
            sessionManager.saveStatePublic()

            NSLog("[DECK-AI] Named session: \(cleaned)")
        } catch {
            NSLog("[DECK-AI] Naming failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Project Name Enhancement

    /// Enhance project names that are just directory names (e.g., "java" → "Square Monorepo").
    /// Only runs once per project, only if API key is available.
    private func enhanceProjectNames() async {
        guard APIKeyStore.hasKey else { return }

        for group in sessionManager.groups {
            // Skip if already enhanced, or user-renamed, or General
            if enhancedProjectIds.contains(group.id) { continue }
            if group.isGeneral { continue }
            guard let dir = group.workingDirectory else { continue }

            // Only enhance if the name is just the directory name (auto-generated)
            let dirName = URL(fileURLWithPath: dir).lastPathComponent
            guard group.name == dirName else {
                enhancedProjectIds.insert(group.id)
                continue
            }

            enhancedProjectIds.insert(group.id)

            let system = """
            You name projects in a developer tool. Given a directory path, suggest a \
            short, descriptive project name (1-3 words). Use the project or repo's actual \
            purpose, not just the folder name. If the folder name is already good, return it unchanged. \
            Respond with ONLY the name, nothing else.
            """

            let homePath = FileManager.default.homeDirectoryForCurrentUser.path
            let relativePath = dir.hasPrefix(homePath)
                ? "~" + dir.dropFirst(homePath.count)
                : dir

            do {
                let suggested = try await AnthropicClient.complete(
                    system: system,
                    userMessage: "Directory: \(relativePath)\nCurrent name: \(dirName)",
                    maxTokens: 20
                )

                let cleaned = suggested
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'`."))
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                // Only update if AI suggested something different and non-empty
                guard !cleaned.isEmpty, cleaned.lowercased() != dirName.lowercased() else { continue }

                if let index = sessionManager.groups.firstIndex(where: { $0.id == group.id }),
                   sessionManager.groups[index].name == dirName {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        sessionManager.groups[index].name = cleaned
                    }
                    sessionManager.saveStatePublic()
                    NSLog("[DECK-AI] Enhanced project name: \(dirName) → \(cleaned)")
                }
            } catch {
                NSLog("[DECK-AI] Project naming failed: \(error.localizedDescription)")
            }
        }
    }
}
