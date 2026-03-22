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

    @State private var isEditing = false
    @State private var editName: String = ""
    @State private var isDropTarget = false
    @State private var isHovered = false

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
            }
        }
        // Accept drops — sessions dragged onto this project
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
    }

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

            // "+" button to add a new chat to this project
            if isHovered && !isEditing {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
                    .onTapGesture {
                        onNewSession(.claude)
                    }
            }
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
        .onHover { isHovered = $0 }
        .onTapGesture { withAnimation(.easeOut(duration: 0.15)) { onToggleCollapse() } }
        .gesture(TapGesture(count: 2).onEnded {
            editName = group.name
            isEditing = true
        })
        .contextMenu {
            Button("Rename") { editName = group.name; isEditing = true }
            Button(group.isCollapsed ? "Expand" : "Collapse") { onToggleCollapse() }

            if !group.isGeneral {
                Divider()
                Button("Delete Project", role: .destructive) { onDeleteGroup() }
            }
        }
    }
}
