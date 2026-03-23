import SwiftUI
import UniformTypeIdentifiers

struct SessionRowView: View {
    @Environment(\.deckTheme) private var theme
    let session: Session
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    let onRename: (String) -> Void
    let onMoveToGroup: ((UUID?) -> Void)?
    let availableGroups: [SessionGroup]

    @State private var isHovered = false
    @State private var isEditing = false
    @State private var editName: String = ""
    @State private var isDropTarget = false
    @State private var showCloseConfirmation = false

    init(
        session: Session,
        isSelected: Bool,
        onSelect: @escaping () -> Void,
        onClose: @escaping () -> Void,
        onRename: @escaping (String) -> Void,
        onMoveToGroup: ((UUID?) -> Void)? = nil,
        availableGroups: [SessionGroup] = []
    ) {
        self.session = session
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onClose = onClose
        self.onRename = onRename
        self.onMoveToGroup = onMoveToGroup
        self.availableGroups = availableGroups
    }

    var body: some View {
        HStack(spacing: 7) {
            // Agent icon — real brand icon for Claude, SF Symbol for others
            agentIcon
                .frame(width: 20, height: 20)
                .opacity(session.agentStatus.isActive ? 0.5 : 1.0)
                .animation(
                    session.agentStatus.isActive
                        ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                        : .default,
                    value: session.agentStatus.isActive
                )
                .accessibilityIdentifier(AccessibilityID.sessionStatusDot)

            VStack(alignment: .leading, spacing: 2) {
                // Line 1: Session name
                if isEditing {
                    RenameTextField(text: $editName, onCommit: { commitRename() }, onCancel: { isEditing = false })
                } else {
                    Text(session.displayName)
                        .font(.system(size: 14))
                        .foregroundStyle(isSelected ? theme.text.primary.swiftUIColor : theme.text.secondary.swiftUIColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .accessibilityIdentifier(AccessibilityID.sessionName)
                }

                // Line 2: Status only (agent icon handles type identification)
                Text(statusSummary)
                    .font(.system(size: 11))
                    .foregroundStyle(statusSummaryColor)
                    .lineLimit(1)
                    .accessibilityIdentifier(AccessibilityID.sessionStatusLabel)
            }

            Spacer(minLength: 4)

            if isHovered && !isEditing {
                SidebarIconButton(icon: "xmark", theme: theme) {
                    showCloseConfirmation = true
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isDropTarget ? theme.accent.subtle.swiftUIColor : backgroundColor)
        )
        .overlay(
            isDropTarget
                ? RoundedRectangle(cornerRadius: 5).stroke(theme.accent.primary.swiftUIColor, lineWidth: 1)
                : nil
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture(count: 2) {
            editName = session.name ?? session.autoName
            isEditing = true
        }
        .onTapGesture(count: 1) {
            if !isEditing {
                onSelect()
            }
        }
        // Drag support
        .draggable(session.id.uuidString) {
            // Drag preview
            HStack(spacing: 6) {
                Image(systemName: session.agentType.iconName)
                    .font(.system(size: 12))
                Text(session.displayName)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(radius: 4)
            )
        }
        .contextMenu {
            Button("Rename") {
                editName = session.name ?? session.autoName
                isEditing = true
            }

            if !availableGroups.isEmpty {
                Menu("Move to Project") {
                    Button("No Project") { onMoveToGroup?(nil) }
                    Divider()
                    ForEach(availableGroups) { group in
                        Button(group.name) { onMoveToGroup?(group.id) }
                    }
                }
            }

            Divider()
            Button("Close", role: .destructive) { showCloseConfirmation = true }
        }
        .alert("Close Session?", isPresented: $showCloseConfirmation) {
            Button("Close", role: .destructive) { onClose() }
                .keyboardShortcut(.defaultAction)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Close \"\(session.displayName)\"? This will end the running process.")
        }
    }

    private func commitRename() {
        let trimmed = editName.trimmingCharacters(in: .whitespaces)
        onRename(trimmed)
        isEditing = false
    }

    private var statusSummary: String {
        if !session.isRunning {
            if let code = session.exitCode, code != 0 {
                return "Exited (\(code))"
            }
            return "Ready"
        }
        switch session.agentStatus {
        case .idle: return "Ready"
        case .thinking: return "Thinking..."
        case .writing: return "Writing code..."
        case .running: return "Working..."
        case .waitingForInput: return "Needs approval"
        case .error: return "Error"
        }
    }

    private var statusSummaryColor: Color {
        if !session.isRunning {
            if let code = session.exitCode, code != 0 {
                return theme.status.error.primary.swiftUIColor.opacity(0.85)
            }
            return theme.text.quaternary.swiftUIColor
        }
        if session.agentStatus.isActive {
            return statusColor.opacity(0.85)
        }
        if session.agentStatus == .waitingForInput {
            return theme.status.warning.primary.swiftUIColor.opacity(0.85)
        }
        return theme.text.quaternary.swiftUIColor
    }

    @ViewBuilder
    private var agentIcon: some View {
        switch session.agentType {
        case .claude:
            // Use real Claude icon from bundle, tinted orange
            if let url = Bundle.module.url(forResource: "claude-icon", withExtension: "png"),
               let img = NSImage(contentsOf: url) {
                Image(nsImage: img)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(agentBrandColor)
                    .frame(width: 18, height: 18)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 15))
                    .foregroundStyle(agentBrandColor)
            }
        case .amp:
            Image(systemName: "bolt.fill")
                .font(.system(size: 15))
                .foregroundStyle(agentBrandColor)
        case .shell:
            Image(systemName: "terminal.fill")
                .font(.system(size: 14))
                .foregroundStyle(agentBrandColor)
        }
    }

    private var agentBrandColor: Color {
        switch session.agentType {
        case .claude: return Color(red: 0.90, green: 0.55, blue: 0.25) // Claude orange
        case .amp: return Color(red: 0.55, green: 0.82, blue: 0.78)    // Amp pale blue-green
        case .shell: return theme.text.tertiary.swiftUIColor
        }
    }

    private var statusDotOpacity: Double {
        session.agentStatus.isActive ? 0.4 : 1.0
    }

    private var statusColor: Color {
        if session.isRunning {
            if session.agentStatus.isActive { return theme.accent.primary.swiftUIColor }
            if session.agentStatus == .waitingForInput { return theme.status.warning.primary.swiftUIColor }
            return theme.status.success.primary.swiftUIColor
        } else if let code = session.exitCode, code != 0 {
            return theme.status.error.primary.swiftUIColor
        }
        return theme.text.quaternary.swiftUIColor
    }

    private var backgroundColor: Color {
        if isSelected {
            return isHovered ? theme.surfaces.selectedHover.swiftUIColor : theme.surfaces.selected.swiftUIColor
        }
        return isHovered ? theme.surfaces.hover.swiftUIColor : .clear
    }
}
