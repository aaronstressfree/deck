import Foundation
import SwiftUI

/// AI-powered session naming.
/// Projects are resolved deterministically by git root — no AI needed for organization.
@MainActor
final class SessionIntelligence {

    private unowned let sessionManager: SessionManager

    /// Cooldown tracking
    private var lastNamedAt: [UUID: Date] = [:]

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
    /// Multiple sessions created in quick succession are batched together.
    func scheduleNaming(for sessionId: UUID) {
        pendingNaming.insert(sessionId)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(namingDelay * 1_000_000_000))

            // Drain the queue — first task to fire processes all pending
            guard !pendingNaming.isEmpty else { return }
            let batch = pendingNaming
            pendingNaming.removeAll()

            for id in batch {
                await nameSession(id)
            }
        }
    }

    // MARK: - Naming

    private func nameSession(_ sessionId: UUID) async {
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

            // Clean up the response — strip quotes, periods, etc.
            let cleaned = suggestedName
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'`."))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !cleaned.isEmpty,
                  let index = sessionManager.sessions.firstIndex(where: { $0.id == sessionId }),
                  sessionManager.sessions[index].name == nil // still no manual name
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

}
