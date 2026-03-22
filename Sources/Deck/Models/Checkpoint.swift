import Foundation

/// A snapshot of session state at a point in time.
struct Checkpoint: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    let gitCommitHash: String?
    let createdAt: Date
    let scrollbackSnapshotPath: String?

    init(name: String, gitCommitHash: String? = nil, scrollbackSnapshotPath: String? = nil) {
        self.id = UUID()
        self.name = name
        self.gitCommitHash = gitCommitHash
        self.createdAt = Date()
        self.scrollbackSnapshotPath = scrollbackSnapshotPath
    }

    /// Relative time string ("2m ago", "1h ago")
    var relativeTime: String {
        let interval = Date().timeIntervalSince(createdAt)
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let mins = Int(interval / 60)
            return "\(mins)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}
