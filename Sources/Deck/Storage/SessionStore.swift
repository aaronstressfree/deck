import Foundation

/// Handles saving and loading session state to disk.
enum SessionStore {
    static var baseDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Deck/Sessions", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func saveScrollback(_ data: Data, for sessionId: UUID) {
        let url = baseDirectory.appendingPathComponent("\(sessionId.uuidString).scrollback")
        try? data.write(to: url)
    }

    static func loadScrollback(for sessionId: UUID) -> Data? {
        let url = baseDirectory.appendingPathComponent("\(sessionId.uuidString).scrollback")
        return try? Data(contentsOf: url)
    }

    static func deleteScrollback(for sessionId: UUID) {
        let url = baseDirectory.appendingPathComponent("\(sessionId.uuidString).scrollback")
        try? FileManager.default.removeItem(at: url)
    }
}
