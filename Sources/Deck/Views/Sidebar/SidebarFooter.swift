import SwiftUI

/// Sidebar footer — "New" button creates a chat in the current project.
struct SidebarFooter: View {
    @Environment(\.deckTheme) private var theme
    @State private var showMenu = false

    let activeProjectName: String?
    let onNewClaude: () -> Void
    let onNewAmp: () -> Void
    let onNewShell: () -> Void

    var body: some View {
        HStack {
            // "New" button — creates in current project
            Button(action: { showMenu.toggle() }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                    Text("New")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(theme.text.secondary.swiftUIColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showMenu, arrowEdge: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    // Project context header
                    if let name = activeProjectName {
                        Text("New in \(name)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(theme.text.quaternary.swiftUIColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }

                    menuButton(icon: "sparkles", label: "Claude Code", shortcut: "⌘⇧C") {
                        onNewClaude()
                        showMenu = false
                    }
                    menuButton(icon: "bolt.fill", label: "Amp", shortcut: "⌘⇧A") {
                        onNewAmp()
                        showMenu = false
                    }
                    menuButton(icon: "terminal.fill", label: "Shell", shortcut: "⌘N") {
                        onNewShell()
                        showMenu = false
                    }
                }
                .padding(6)
                .frame(width: 200)
                .background(theme.surfaces.elevated.swiftUIColor)
                .environment(\.colorScheme, .dark)
            }

            Spacer()

            // Settings gear
            Button(action: {
                if !NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) {
                    if !NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil) {
                        NSApp.sendAction(Selector(("orderFrontPreferencesPanel:")), to: nil, from: nil)
                    }
                }
            }) {
                Image(systemName: "gear")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
            }
            .buttonStyle(.plain)
            .help("Settings (⌘,)")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
    }

    private func menuButton(icon: String, label: String, shortcut: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.text.secondary.swiftUIColor)
                    .frame(width: 18)
                Text(label)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.text.primary.swiftUIColor)
                Spacer()
                if !shortcut.isEmpty {
                    Text(shortcut)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(theme.text.quaternary.swiftUIColor)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
