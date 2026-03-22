import SwiftUI

struct SettingsView: View {
    @ObservedObject var sessionManager: SessionManager

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
        }
        .frame(minWidth: 700, minHeight: 550)
        .frame(width: 780, height: 600)
    }
}
