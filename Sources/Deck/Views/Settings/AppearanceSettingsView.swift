import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var filter: ColorSchemeType? = nil

    var filteredThemes: [Theme] {
        if let filter = filter {
            return themeManager.availableThemes.filter { $0.metadata.colorScheme == filter }
        }
        return themeManager.availableThemes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Filter tabs
            HStack(spacing: 8) {
                filterButton("All", isActive: filter == nil) { filter = nil }
                filterButton("Dark", isActive: filter == .dark) { filter = .dark }
                filterButton("Light", isActive: filter == .light) { filter = .light }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Theme grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 16)
                ], spacing: 16) {
                    ForEach(filteredThemes) { theme in
                        ThemePreviewCard(
                            theme: theme,
                            isActive: theme.id == themeManager.activeTheme.id,
                            onSelect: { themeManager.setActiveTheme(theme) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func filterButton(_ label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    isActive ? Color.accentColor.opacity(0.15) : Color.clear
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Theme Preview Card

struct ThemePreviewCard: View {
    let theme: Theme
    let isActive: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Mini preview
            VStack(spacing: 0) {
                // Sidebar preview
                HStack(spacing: 4) {
                    Circle()
                        .fill(theme.status.success.primary.swiftUIColor)
                        .frame(width: 4, height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.text.tertiary.swiftUIColor)
                        .frame(width: 40, height: 4)
                    Spacer()
                }
                .padding(6)
                .frame(height: 20)
                .background(theme.surfaces.inset.swiftUIColor)

                // Terminal preview
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(theme.terminal.ansi.green.swiftUIColor)
                            .frame(width: 12, height: 3)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(theme.terminal.foreground.swiftUIColor)
                            .frame(width: 30, height: 3)
                    }
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(theme.terminal.ansi.blue.swiftUIColor)
                            .frame(width: 20, height: 3)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(theme.terminal.ansi.yellow.swiftUIColor)
                            .frame(width: 15, height: 3)
                    }
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(theme.terminal.ansi.red.swiftUIColor)
                            .frame(width: 25, height: 3)
                    }
                }
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.terminal.background.swiftUIColor)

                // Status bar preview
                HStack {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(theme.text.quaternary.swiftUIColor)
                        .frame(width: 30, height: 3)
                    Spacer()
                    RoundedRectangle(cornerRadius: 1)
                        .fill(theme.accent.primary.swiftUIColor)
                        .frame(width: 20, height: 3)
                }
                .padding(4)
                .frame(height: 14)
                .background(theme.surfaces.bar.swiftUIColor)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isActive ? Color.accentColor : Color.gray.opacity(0.3),
                        lineWidth: isActive ? 2 : 1
                    )
            )

            // Label
            HStack(spacing: 4) {
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.accentColor)
                }
                Text(theme.metadata.name)
                    .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(.primary)
            }
            .padding(.top, 6)

            if theme.metadata.isBuiltIn {
                Text("Built-in")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
    }
}
