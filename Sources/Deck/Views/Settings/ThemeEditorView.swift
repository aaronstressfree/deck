import SwiftUI

struct ThemeEditorView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedThemeId: String?
    @State private var editingTheme: Theme?
    @State private var showCopiedFeedback = false
    @State private var showLinkImportError = false

    var body: some View {
        HSplitView {
            // Left: theme list
            themeList
                .frame(minWidth: 160, maxWidth: 200)

            // Right: editor or placeholder
            if let theme = editingTheme, !theme.metadata.isBuiltIn {
                themeEditor(theme: theme)
            } else if let theme = editingTheme, theme.metadata.isBuiltIn {
                builtInThemeView(theme: theme)
            } else {
                VStack {
                    Spacer()
                    Text("Select a theme to edit")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 700, height: 500)
    }

    // MARK: - Theme List

    private var themeList: some View {
        VStack(spacing: 0) {
            List(selection: $selectedThemeId) {
                Section("Built-in") {
                    ForEach(themeManager.availableThemes.filter(\.metadata.isBuiltIn)) { theme in
                        themeListRow(theme: theme)
                    }
                }

                let userThemes = themeManager.availableThemes.filter { !$0.metadata.isBuiltIn }
                if !userThemes.isEmpty {
                    Section("Custom") {
                        ForEach(userThemes) { theme in
                            themeListRow(theme: theme)
                        }
                    }
                }
            }
            .onChange(of: selectedThemeId) { _, newId in
                editingTheme = themeManager.availableThemes.first(where: { $0.id == newId })
            }

            Divider()

            HStack {
                Button(action: createNewTheme) {
                    Label("New Theme", systemImage: "plus")
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))

                Spacer()

                Button(action: importFromLink) {
                    Text("Paste Link")
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .help("Import a theme from a share link on your clipboard")

                Button(action: importTheme) {
                    Text("Import...")
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
            }
            .padding(8)
            .alert("Invalid Link", isPresented: $showLinkImportError) {
                Button("OK") {}
            } message: {
                Text("No valid Deck theme link found on your clipboard. Copy a deck://theme/... link and try again.")
            }
        }
    }

    private func themeListRow(theme: Theme) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(theme.accent.primary.swiftUIColor)
                .frame(width: 10, height: 10)

            Text(theme.metadata.name)
                .font(.system(size: 12))

            Spacer()

            if theme.metadata.isBuiltIn {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }

            if theme.id == themeManager.activeTheme.id {
                Image(systemName: "checkmark")
                    .font(.system(size: 10))
                    .foregroundStyle(.blue)
            }
        }
        .tag(theme.id)
        .contextMenu {
            if !theme.metadata.isBuiltIn {
                Button("Delete", role: .destructive) {
                    try? themeManager.deleteUserTheme(theme)
                }
            }
            Button("Duplicate") {
                let dup = themeManager.duplicateTheme(theme, newName: "\(theme.metadata.name) Copy")
                selectedThemeId = dup.id
                editingTheme = dup
            }
            Button("Copy Share Link") { copyShareLink(theme) }
            Button("Export...") { exportTheme(theme) }
        }
    }

    // MARK: - Built-in Theme View

    private func builtInThemeView(theme: Theme) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("\(theme.metadata.name) is a built-in theme")
                .font(.headline)
            Text("Duplicate it to create an editable copy")
                .foregroundStyle(.secondary)
            Button("Duplicate & Edit") {
                let dup = themeManager.duplicateTheme(theme, newName: "\(theme.metadata.name) (Custom)")
                selectedThemeId = dup.id
                editingTheme = dup
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Theme Editor

    private func themeEditor(theme: Theme) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Name field
                HStack {
                    Text("Name:")
                        .font(.system(size: 12, weight: .medium))
                    TextField("Theme name", text: Binding(
                        get: { editingTheme?.metadata.name ?? "" },
                        set: { editingTheme?.metadata.name = $0; saveEditing() }
                    ))
                    .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                // Color scheme
                HStack {
                    Text("Scheme:")
                        .font(.system(size: 12, weight: .medium))
                    Picker("", selection: Binding(
                        get: { editingTheme?.metadata.colorScheme ?? .dark },
                        set: { _ in } // Color scheme isn't easily changeable after creation
                    )) {
                        Text("Dark").tag(ColorSchemeType.dark)
                        Text("Light").tag(ColorSchemeType.light)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
                .padding(.horizontal)

                Divider()

                // Color sections
                if var t = editingTheme {
                    colorSection("Accent", colors: [
                        ("Primary", $editingTheme.forceUnwrap.accent.primary),
                        ("Hover", $editingTheme.forceUnwrap.accent.hover),
                        ("Active", $editingTheme.forceUnwrap.accent.active),
                    ])

                    colorSection("Surfaces", colors: [
                        ("Surface", $editingTheme.forceUnwrap.surfaces.primary),
                        ("Inset", $editingTheme.forceUnwrap.surfaces.inset),
                        ("Elevated", $editingTheme.forceUnwrap.surfaces.elevated),
                        ("Hover", $editingTheme.forceUnwrap.surfaces.hover),
                        ("Bar", $editingTheme.forceUnwrap.surfaces.bar),
                    ])

                    colorSection("Text", colors: [
                        ("Primary", $editingTheme.forceUnwrap.text.primary),
                        ("Secondary", $editingTheme.forceUnwrap.text.secondary),
                        ("Tertiary", $editingTheme.forceUnwrap.text.tertiary),
                        ("Link", $editingTheme.forceUnwrap.text.link),
                    ])

                    colorSection("Terminal", colors: [
                        ("Background", $editingTheme.forceUnwrap.terminal.background),
                        ("Foreground", $editingTheme.forceUnwrap.terminal.foreground),
                        ("Cursor", $editingTheme.forceUnwrap.terminal.cursor),
                    ])

                    colorSection("ANSI Colors", colors: [
                        ("Black", $editingTheme.forceUnwrap.terminal.ansi.black),
                        ("Red", $editingTheme.forceUnwrap.terminal.ansi.red),
                        ("Green", $editingTheme.forceUnwrap.terminal.ansi.green),
                        ("Yellow", $editingTheme.forceUnwrap.terminal.ansi.yellow),
                        ("Blue", $editingTheme.forceUnwrap.terminal.ansi.blue),
                        ("Magenta", $editingTheme.forceUnwrap.terminal.ansi.magenta),
                        ("Cyan", $editingTheme.forceUnwrap.terminal.ansi.cyan),
                        ("White", $editingTheme.forceUnwrap.terminal.ansi.white),
                    ])

                    colorSection("ANSI Bright", colors: [
                        ("Bright Black", $editingTheme.forceUnwrap.terminal.ansi.brightBlack),
                        ("Bright Red", $editingTheme.forceUnwrap.terminal.ansi.brightRed),
                        ("Bright Green", $editingTheme.forceUnwrap.terminal.ansi.brightGreen),
                        ("Bright Yellow", $editingTheme.forceUnwrap.terminal.ansi.brightYellow),
                        ("Bright Blue", $editingTheme.forceUnwrap.terminal.ansi.brightBlue),
                        ("Bright Magenta", $editingTheme.forceUnwrap.terminal.ansi.brightMagenta),
                        ("Bright Cyan", $editingTheme.forceUnwrap.terminal.ansi.brightCyan),
                        ("Bright White", $editingTheme.forceUnwrap.terminal.ansi.brightWhite),
                    ])

                    // Live preview
                    livePreview(theme: t)
                        .padding(.horizontal)

                    // Actions
                    HStack {
                        Button("Export...") {
                            if let t = editingTheme { exportTheme(t) }
                        }

                        Button(action: {
                            if let t = editingTheme { copyShareLink(t) }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: showCopiedFeedback ? "checkmark" : "link")
                                Text(showCopiedFeedback ? "Copied!" : "Copy Share Link")
                            }
                        }

                        Spacer()
                        Button("Apply as Active") {
                            if let t = editingTheme { themeManager.setActiveTheme(t) }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .padding(.vertical)
        }
    }

    private func colorSection(_ title: String, colors: [(String, Binding<ThemeColor>)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 140), spacing: 8)
            ], spacing: 6) {
                ForEach(colors, id: \.0) { label, binding in
                    ColorSwatchView(label: label, color: binding)
                        .onChange(of: binding.wrappedValue) { _, _ in saveEditing() }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Live Preview

    private func livePreview(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("PREVIEW")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            VStack(spacing: 0) {
                // Mini sidebar
                HStack(spacing: 6) {
                    Circle().fill(theme.status.success.primary.swiftUIColor).frame(width: 6, height: 6)
                    Text("Claude: project")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.text.primary.swiftUIColor)
                    Spacer()
                }
                .padding(8)
                .background(theme.surfaces.inset.swiftUIColor)

                // Mini terminal
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text("$")
                            .foregroundStyle(theme.terminal.ansi.green.swiftUIColor)
                        Text("echo hello")
                            .foregroundStyle(theme.terminal.foreground.swiftUIColor)
                    }
                    Text("hello")
                        .foregroundStyle(theme.terminal.foreground.swiftUIColor)
                    HStack(spacing: 4) {
                        Text("$")
                            .foregroundStyle(theme.terminal.ansi.green.swiftUIColor)
                        Rectangle()
                            .fill(theme.terminal.cursor.swiftUIColor)
                            .frame(width: 7, height: 12)
                    }
                }
                .font(.system(size: 10, design: .monospaced))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.terminal.background.swiftUIColor)

                // Mini status bar
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
                .padding(.vertical, 3)
                .background(theme.surfaces.bar.swiftUIColor)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Actions

    private func createNewTheme() {
        let dup = themeManager.duplicateTheme(themeManager.activeTheme, newName: "New Theme")
        selectedThemeId = dup.id
        editingTheme = dup
    }

    private func importTheme() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            if let imported = try? themeManager.importTheme(from: url) {
                selectedThemeId = imported.id
                editingTheme = imported
            }
        }
    }

    private func exportTheme(_ theme: Theme) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(theme.metadata.name).json"
        if panel.runModal() == .OK, let url = panel.url {
            try? themeManager.exportTheme(theme, to: url)
        }
    }

    private func copyShareLink(_ theme: Theme) {
        if ThemeSharing.copyToClipboard(theme: theme) {
            showCopiedFeedback = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showCopiedFeedback = false
            }
        }
    }

    private func importFromLink() {
        if let theme = ThemeSharing.themeFromClipboard() {
            themeManager.pendingShareImport = theme
        } else {
            showLinkImportError = true
        }
    }

    private func saveEditing() {
        guard let theme = editingTheme, !theme.metadata.isBuiltIn else { return }
        try? themeManager.saveUserTheme(theme)
    }
}

// MARK: - Binding Helper

extension Binding where Value == Theme? {
    var forceUnwrap: Binding<Theme> {
        Binding<Theme>(
            get: { self.wrappedValue! },
            set: { self.wrappedValue = $0 }
        )
    }
}
