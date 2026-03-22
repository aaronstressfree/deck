import SwiftUI

/// Sheet shown when a shared theme link is opened.
/// Displays a rich preview of the theme and lets the user import or cancel.
struct ThemeImportSheet: View {
    let theme: Theme
    let onImport: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 6) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(theme.accent.primary.swiftUIColor)

                Text("Theme Shared With You")
                    .font(.headline)
            }

            // Name + meta
            VStack(spacing: 6) {
                Text(theme.metadata.name)
                    .font(.system(size: 18, weight: .semibold))

                HStack(spacing: 12) {
                    Label(theme.metadata.author, systemImage: "person")
                    Label(
                        theme.metadata.colorScheme == .dark ? "Dark" : "Light",
                        systemImage: theme.metadata.colorScheme == .dark ? "moon.fill" : "sun.max.fill"
                    )
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

                if let desc = theme.metadata.description {
                    Text(desc)
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
            }

            // Mini preview
            themePreview

            // Color palette strip
            HStack(spacing: 5) {
                dot(theme.surfaces.primary)
                dot(theme.surfaces.inset)
                dot(theme.accent.primary)
                dot(theme.terminal.background)
                dot(theme.terminal.foreground)
                dot(theme.terminal.ansi.green)
                dot(theme.terminal.ansi.red)
                dot(theme.terminal.ansi.blue)
                dot(theme.terminal.ansi.yellow)
                dot(theme.terminal.ansi.magenta)
            }

            // Actions
            HStack(spacing: 12) {
                Button("Cancel") { onCancel() }
                    .keyboardShortcut(.cancelAction)

                Button("Import Theme") { onImport() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 380)
    }

    // MARK: - Preview

    private var themePreview: some View {
        VStack(spacing: 0) {
            // Sidebar strip
            HStack(spacing: 5) {
                Circle()
                    .fill(theme.status.success.primary.swiftUIColor)
                    .frame(width: 5, height: 5)
                Text("Claude: project")
                    .font(.system(size: 10))
                    .foregroundStyle(theme.text.primary.swiftUIColor)
                Spacer()
            }
            .padding(8)
            .background(theme.surfaces.inset.swiftUIColor)

            // Terminal
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 3) {
                    Text("$")
                        .foregroundStyle(theme.terminal.ansi.green.swiftUIColor)
                    Text("ls -la")
                        .foregroundStyle(theme.terminal.foreground.swiftUIColor)
                }
                HStack(spacing: 3) {
                    Text("drwxr-xr-x")
                        .foregroundStyle(theme.terminal.ansi.blue.swiftUIColor)
                    Text("src/")
                        .foregroundStyle(theme.terminal.ansi.cyan.swiftUIColor)
                }
                HStack(spacing: 3) {
                    Text("-rw-r--r--")
                        .foregroundStyle(theme.terminal.ansi.yellow.swiftUIColor)
                    Text("README.md")
                        .foregroundStyle(theme.terminal.foreground.swiftUIColor)
                }
                HStack(spacing: 3) {
                    Text("$")
                        .foregroundStyle(theme.terminal.ansi.green.swiftUIColor)
                    Rectangle()
                        .fill(theme.terminal.cursor.swiftUIColor)
                        .frame(width: 7, height: 13)
                }
            }
            .font(.system(size: 11, design: .monospaced))
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.terminal.background.swiftUIColor)

            // Status bar
            HStack {
                Text("~/project")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
                Spacer()
                Text("main")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(theme.accent.primary.swiftUIColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.surfaces.bar.swiftUIColor)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    private func dot(_ color: ThemeColor) -> some View {
        Circle()
            .fill(color.swiftUIColor)
            .frame(width: 20, height: 20)
            .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 0.5))
    }
}
