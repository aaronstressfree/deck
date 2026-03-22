import SwiftUI

// MARK: - Environment Key

private struct DeckThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .obsidian
}

extension EnvironmentValues {
    var deckTheme: Theme {
        get { self[DeckThemeKey.self] }
        set { self[DeckThemeKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    func deckTheme(_ theme: Theme) -> some View {
        environment(\.deckTheme, theme)
    }
}
