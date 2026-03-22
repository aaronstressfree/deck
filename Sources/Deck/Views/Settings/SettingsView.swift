import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var sessionManager: SessionManager

    private var isDark: Bool {
        themeManager.activeTheme.metadata.colorScheme == .dark
    }

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }

            ContextSettingsView(sessionManager: sessionManager)
                .tabItem { Label("Context", systemImage: "doc.text") }

            AppearanceSettingsView()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }

            TerminalSettingsView()
                .tabItem { Label("Terminal", systemImage: "terminal") }

            ThemeEditorView()
                .tabItem { Label("Themes", systemImage: "paintpalette") }

            FeedbackView()
                .tabItem { Label("Feedback", systemImage: "bubble.left.and.exclamationmark.bubble.right") }
        }
        .frame(minWidth: 700, minHeight: 550)
        .frame(width: 780, height: 600)
        .preferredColorScheme(isDark ? .dark : .light)
    }
}
