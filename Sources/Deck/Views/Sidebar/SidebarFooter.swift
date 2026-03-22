import SwiftUI

/// Sidebar footer — "New" button creates a chat in the current project.
struct SidebarFooter: View {
    @Environment(\.deckTheme) private var theme
    @State private var showMenu = false

    let activeProjectName: String?
    let onNewClaude: () -> Void
    let onNewAmp: () -> Void
    let onNewShell: () -> Void
    let onNewProject: ((String, String?) -> Void)?
    let onShowNewProject: () -> Void

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
            .buttonStyle(HoverButtonStyle(hoverColor: theme.surfaces.hover.swiftUIColor))
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
                    Divider().padding(.vertical, 2)
                    menuButton(icon: "folder.badge.plus", label: "New Project...", shortcut: "") {
                        showMenu = false
                        // Delay to let popover dismiss before showing sheet
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onShowNewProject()
                        }
                    }
                }
                .padding(6)
                .frame(width: 200)
                .background(theme.surfaces.elevated.swiftUIColor)
                .environment(\.colorScheme, .dark)
            }

            Spacer()

            // Settings gear
            SettingsLink {
                Image(systemName: "gear")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(HoverButtonStyle(hoverColor: theme.surfaces.hover.swiftUIColor))
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
            .background(RoundedRectangle(cornerRadius: 4).fill(Color.clear))
        }
        .buttonStyle(HoverButtonStyle(hoverColor: theme.surfaces.hover.swiftUIColor))
    }
}

// MARK: - New Project Sheet

struct NewProjectSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onCreate: (String, String?) -> Void

    @State private var name = ""
    @State private var directory = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("New Project")
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text("Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("Project name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Working Directory")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Optional — leave empty to set later")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                HStack {
                    TextField("~/Development/my-project", text: $directory)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 14))
                    Button("Browse...") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        if panel.runModal() == .OK, let url = panel.url {
                            directory = url.path
                            if name.isEmpty {
                                name = url.lastPathComponent
                            }
                        }
                    }
                }
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Create") {
                    onCreate(name, directory.isEmpty ? nil : directory)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}
