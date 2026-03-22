import Foundation

/// SQLite-backed history store for searchable session history.
/// Stub implementation — will be backed by SQLite in a future phase.
@MainActor
final class HistoryStore: ObservableObject {
    struct HistoryEntry: Identifiable, Codable {
        let id: UUID
        let sessionName: String
        let agentType: AgentType
        let workingDirectory: String
        let startedAt: Date
        let endedAt: Date
        let promptCount: Int
    }

    @Published var entries: [HistoryEntry] = []

    static let shared = HistoryStore()

    func recordSession(_ session: Session) {
        let entry = HistoryEntry(
            id: session.id,
            sessionName: session.displayName,
            agentType: session.agentType,
            workingDirectory: session.workingDirectory,
            startedAt: session.createdAt,
            endedAt: Date(),
            promptCount: 0
        )
        entries.append(entry)
        save()
    }

    func search(query: String) -> [HistoryEntry] {
        if query.isEmpty { return entries }
        return entries.filter {
            $0.sessionName.localizedCaseInsensitiveContains(query) ||
            $0.workingDirectory.localizedCaseInsensitiveContains(query)
        }
    }

    private func save() {
        let url = AppState.storageURL.deletingLastPathComponent().appendingPathComponent("history.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: url)
    }

    private init() {
        let url = AppState.storageURL.deletingLastPathComponent().appendingPathComponent("history.json")
        guard let data = try? Data(contentsOf: url),
              let loaded = try? JSONDecoder().decode([HistoryEntry].self, from: data) else { return }
        entries = loaded
    }
}
