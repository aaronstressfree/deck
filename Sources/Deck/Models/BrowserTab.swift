import Foundation

/// A browser tab associated with a session.
struct BrowserTab: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var title: String
    var url: String
    var isActive: Bool

    init(url: String, title: String? = nil) {
        self.id = UUID()
        self.url = url
        self.title = title ?? url
        self.isActive = true
    }
}
