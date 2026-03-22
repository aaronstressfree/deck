import Foundation

/// Manages scrollback persistence for session restore.
enum ScrollbackStore {
    static var baseDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Deck/Scrollback", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func save(_ text: String, for sessionId: UUID) {
        let url = baseDirectory.appendingPathComponent("\(sessionId.uuidString).txt")
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }

    static func load(for sessionId: UUID) -> String? {
        let url = baseDirectory.appendingPathComponent("\(sessionId.uuidString).txt")
        return try? String(contentsOf: url, encoding: .utf8)
    }

    static func delete(for sessionId: UUID) {
        let url = baseDirectory.appendingPathComponent("\(sessionId.uuidString).txt")
        try? FileManager.default.removeItem(at: url)
    }
}
