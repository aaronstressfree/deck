import SwiftUI
import Combine

@MainActor
final class ThemeManager: ObservableObject {
    @Published var activeTheme: Theme
    @Published var availableThemes: [Theme]
    @Published var pendingShareImport: Theme?

    private let userThemesDirectory: URL
    private let activeThemeKey = "activeThemeId"

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let deckDir = appSupport.appendingPathComponent("Deck", isDirectory: true)
        self.userThemesDirectory = deckDir.appendingPathComponent("Themes", isDirectory: true)

        // Ensure directories exist
        try? FileManager.default.createDirectory(at: userThemesDirectory, withIntermediateDirectories: true)

        // Load themes
        var themes = Theme.builtInThemes
        let userThemes = ThemeManager.loadUserThemes(from: userThemesDirectory)
        themes.append(contentsOf: userThemes)
        self.availableThemes = themes

        // Restore active theme
        let savedId = UserDefaults.standard.string(forKey: activeThemeKey) ?? "obsidian"
        self.activeTheme = themes.first(where: { $0.id == savedId }) ?? .obsidian
    }

    func setActiveTheme(_ theme: Theme) {
        withAnimation(.easeInOut(duration: 0.4)) {
            activeTheme = theme
        }
        UserDefaults.standard.set(theme.id, forKey: activeThemeKey)
    }

    func saveUserTheme(_ theme: Theme) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(theme)
        let url = userThemesDirectory.appendingPathComponent("\(theme.id).json")
        try data.write(to: url)

        // Update available themes
        if let index = availableThemes.firstIndex(where: { $0.id == theme.id }) {
            availableThemes[index] = theme
        } else {
            availableThemes.append(theme)
        }

        // If editing active theme, update it
        if activeTheme.id == theme.id {
            activeTheme = theme
        }
    }

    func deleteUserTheme(_ theme: Theme) throws {
        guard !theme.metadata.isBuiltIn else { return }

        let url = userThemesDirectory.appendingPathComponent("\(theme.id).json")
        try FileManager.default.removeItem(at: url)

        availableThemes.removeAll(where: { $0.id == theme.id })

        if activeTheme.id == theme.id {
            setActiveTheme(.obsidian)
        }
    }

    func duplicateTheme(_ theme: Theme, newName: String) -> Theme {
        let slugName = newName.lowercased().replacingOccurrences(of: " ", with: "-")
        let newId = "user.\(slugName)-\(Int(Date().timeIntervalSince1970))"

        var newTheme = theme
        newTheme.metadata = ThemeMetadata(
            id: newId,
            name: newName,
            author: "Custom",
            version: theme.metadata.version,
            colorScheme: theme.metadata.colorScheme,
            description: "Custom theme based on \(theme.metadata.name)",
            isBuiltIn: false
        )

        try? saveUserTheme(newTheme)
        return newTheme
    }

    func importTheme(from url: URL) throws -> Theme {
        let data = try Data(contentsOf: url)
        var theme = try JSONDecoder().decode(Theme.self, from: data)

        // Ensure it's not marked as built-in
        theme.metadata = ThemeMetadata(
            id: theme.metadata.id.hasPrefix("user.") ? theme.metadata.id : "user.\(theme.metadata.id)",
            name: theme.metadata.name,
            author: theme.metadata.author,
            version: theme.metadata.version,
            colorScheme: theme.metadata.colorScheme,
            description: theme.metadata.description,
            isBuiltIn: false
        )

        try saveUserTheme(theme)
        return theme
    }

    func exportTheme(_ theme: Theme, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(theme)
        try data.write(to: url)
    }

    // MARK: - Theme Sharing

    /// Handle an incoming `deck://theme/...` URL.
    func handleShareURL(_ url: URL) {
        guard let theme = ThemeSharing.theme(from: url) else { return }
        pendingShareImport = theme
    }

    /// Import the pending shared theme, assigning it a fresh user ID.
    /// Returns the imported theme, or nil if nothing was pending.
    @discardableResult
    func confirmShareImport() -> Theme? {
        guard var theme = pendingShareImport else { return nil }

        let slug = theme.metadata.name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
        let newId = "user.\(slug)-\(Int(Date().timeIntervalSince1970))"

        theme.metadata = ThemeMetadata(
            id: newId,
            name: theme.metadata.name,
            author: theme.metadata.author,
            version: theme.metadata.version,
            colorScheme: theme.metadata.colorScheme,
            description: theme.metadata.description,
            isBuiltIn: false
        )

        try? saveUserTheme(theme)
        pendingShareImport = nil
        return theme
    }

    func cancelShareImport() {
        pendingShareImport = nil
    }

    // MARK: - Private

    private static func loadUserThemes(from directory: URL) -> [Theme] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter({ $0.pathExtension == "json" }) else {
            return []
        }

        return files.compactMap { url in
            guard let data = try? Data(contentsOf: url),
                  let theme = try? JSONDecoder().decode(Theme.self, from: data) else {
                return nil
            }
            return theme
        }
    }
}
