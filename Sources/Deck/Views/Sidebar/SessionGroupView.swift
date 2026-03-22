import SwiftUI
import UniformTypeIdentifiers

struct SessionGroupView: View {
    @Environment(\.deckTheme) private var theme
    let group: SessionGroup
    let sessions: [Session]
    let allGroups: [SessionGroup]
    let activeSessionId: UUID?
    let onToggleCollapse: () -> Void
    let onSelectSession: (UUID) -> Void
    let onCloseSession: (UUID) -> Void
    let onRenameSession: (UUID, String) -> Void
    let onMoveSession: (UUID, UUID?) -> Void
    let onRenameGroup: (String) -> Void
    let onDeleteGroup: () -> Void
    let onNewSession: (AgentType) -> Void
    let onUpdateInstructions: (String) -> Void
    var onReorderSessions: ((IndexSet, Int) -> Void)? = nil

    @State private var isEditing = false
    @State private var editName: String = ""
    @State private var isDropTarget = false
    @State private var isHeaderHovered = false
    @State private var showNewPicker = false
    @State private var showSettings = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            // Project header
            projectHeader

            // Sessions when expanded
            if !group.isCollapsed {
                ForEach(sessions) { session in
                    SessionRowView(
                        session: session,
                        isSelected: session.id == activeSessionId,
                        onSelect: { onSelectSession(session.id) },
                        onClose: { onCloseSession(session.id) },
                        onRename: { name in onRenameSession(session.id, name) },
                        onMoveToGroup: { groupId in onMoveSession(session.id, groupId) },
                        availableGroups: allGroups
                    )
                    .padding(.leading, 6)
                }
                .onMove { source, destination in
                    onReorderSessions?(source, destination)
                }
            }
        }
        .dropDestination(for: String.self) { items, _ in
            for item in items {
                if let uuid = UUID(uuidString: item) {
                    onMoveSession(uuid, group.id)
                }
            }
            return true
        } isTargeted: { targeted in
            isDropTarget = targeted
        }
        .alert("Delete Project?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { onDeleteGroup() }
                .keyboardShortcut(.defaultAction)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Delete \"\(group.name)\"? Sessions will be ungrouped, not deleted.")
        }
        .sheet(isPresented: $showSettings) {
            ProjectSettingsSheet(
                group: group,
                sessions: sessions,
                onRename: onRenameGroup,
                onUpdateInstructions: onUpdateInstructions
            )
        }
    }

    // MARK: - Project header

    private var projectHeader: some View {
        HStack(spacing: 5) {
            Image(systemName: group.isCollapsed ? "chevron.right" : "chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(theme.text.quaternary.swiftUIColor)
                .frame(width: 10)

            if isEditing {
                TextField("Project", text: $editName, onCommit: {
                    onRenameGroup(editName)
                    isEditing = false
                })
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.text.tertiary.swiftUIColor)
            } else {
                Text(group.name.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
                    .tracking(0.5)
            }

            if group.isCollapsed && !sessions.isEmpty {
                Text("\(sessions.count)")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(theme.surfaces.hover.swiftUIColor))
            }

            Spacer()

            // Action buttons — always rendered for stable popover anchoring
            HStack(spacing: 4) {
                SidebarIconButton(icon: "gearshape", theme: theme) {
                    showSettings = true
                }

                SidebarIconButton(icon: "plus", theme: theme) {
                    showNewPicker.toggle()
                }
                .popover(isPresented: $showNewPicker, arrowEdge: .trailing) {
                    VStack(alignment: .leading, spacing: 0) {
                        agentPickerButton(icon: "sparkles", label: "Claude Code", type: .claude)
                        agentPickerButton(icon: "bolt.fill", label: "Amp", type: .amp)
                        agentPickerButton(icon: "terminal.fill", label: "Shell", type: .shell)
                    }
                    .padding(4)
                    .frame(width: 160)
                    .background(theme.surfaces.elevated.swiftUIColor)
                    .environment(\.colorScheme, .dark)
                }
            }
            .opacity(isHeaderHovered && !isEditing ? 1 : 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isDropTarget ? theme.accent.subtle.swiftUIColor : Color.clear)
        )
        .overlay(
            isDropTarget
                ? RoundedRectangle(cornerRadius: 4).stroke(theme.accent.primary.swiftUIColor, lineWidth: 1)
                : nil
        )
        .contentShape(Rectangle())
        .onHover { isHeaderHovered = $0 }
        .onTapGesture { withAnimation(.easeOut(duration: 0.15)) { onToggleCollapse() } }
        .gesture(TapGesture(count: 2).onEnded {
            editName = group.name
            isEditing = true
        })
        .contextMenu {
            Button("Rename") { editName = group.name; isEditing = true }
            Button("Project Settings...") { showSettings = true }
            Button(group.isCollapsed ? "Expand" : "Collapse") { onToggleCollapse() }

            if !group.isGeneral {
                Divider()
                Button("Delete Project", role: .destructive) { showDeleteConfirmation = true }
            }
        }
    }

    // MARK: - Helpers

    private func agentPickerButton(icon: String, label: String, type: AgentType) -> some View {
        SidebarMenuRow(icon: icon, label: label, theme: theme) {
            onNewSession(type)
            showNewPicker = false
        }
    }

    private func truncatedPath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        var display = path
        if display.hasPrefix(home) {
            display = "~" + display.dropFirst(home.count)
        }
        return display
    }
}

// MARK: - Project Settings Sheet

struct ProjectSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let group: SessionGroup
    let sessions: [Session]
    let onRename: (String) -> Void
    let onUpdateInstructions: (String) -> Void

    @State private var editName: String = ""
    @State private var editInstructions: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Project Settings")
                .font(.system(size: 18, weight: .semibold))

            // Name
            VStack(alignment: .leading, spacing: 4) {
                Text("Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("Project name", text: $editName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))
            }

            // Working directory
            if let dir = group.workingDirectory {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Working Directory")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    HStack {
                        Text(dir)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button("Show in Finder") {
                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: dir)
                        }
                        .font(.system(size: 12))
                    }
                }
            }

            // Shared context explanation
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "shared.with.you")
                        .font(.system(size: 14))
                        .foregroundStyle(.blue)
                    Text("Shared Context")
                        .font(.system(size: 14, weight: .semibold))
                }

                Text("Instructions you write here are automatically shared with every chat in this project. Each chat can see what the others are working on and will coordinate to avoid duplicating work.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Show which chats are in the project
                if !sessions.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Chats in this project (\(sessions.count)):")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.tertiary)
                        ForEach(sessions.prefix(5)) { session in
                            HStack(spacing: 4) {
                                Image(systemName: session.agentType.iconName)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                                Text(session.displayName)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if sessions.count > 5 {
                            Text("+ \(sessions.count - 5) more")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                    )
            )

            // Instructions editor
            VStack(alignment: .leading, spacing: 4) {
                Text("Project Instructions")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                TextEditor(text: $editInstructions)
                    .font(.system(size: 14, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(minHeight: 100, maxHeight: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                            )
                    )
            }

            // Actions
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    if editName != group.name { onRename(editName) }
                    if editInstructions != group.instructions { onUpdateInstructions(editInstructions) }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 480)
        .onAppear {
            editName = group.name
            editInstructions = group.instructions
        }
    }
}
