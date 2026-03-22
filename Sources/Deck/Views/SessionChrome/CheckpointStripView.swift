import SwiftUI

/// Checkpoint strip — completely hidden when empty. Shows pills when checkpoints exist.
/// Progressive disclosure: no visual noise until the user creates their first checkpoint.
struct CheckpointStripView: View {
    @Environment(\.deckTheme) private var theme
    @Binding var checkpoints: [Checkpoint]

    @State private var isCreating = false
    @State private var newCheckpointName = ""
    @State private var isHovered = false

    var body: some View {
        Group {
            if checkpoints.isEmpty && !isCreating {
                // Empty: invisible thin line, reveals "+" on hover
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: isHovered ? 28 : 1)
                    .overlay(
                        Group {
                            if isHovered {
                                HStack {
                                    Spacer()
                                    Button(action: startCreating) {
                                        HStack(spacing: 3) {
                                            Image(systemName: "diamond")
                                                .font(.system(size: 12))
                                            Text("Checkpoint")
                                                .font(.system(size: 12))
                                        }
                                        .foregroundStyle(theme.text.quaternary.swiftUIColor)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                            }
                        }
                    )
                    .contentShape(Rectangle())
                    .onHover { isHovered = $0 }
                    .animation(.easeOut(duration: 0.15), value: isHovered)
            } else {
                // Has checkpoints: show strip
                stripContent
            }
        }
    }

    private var stripContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(checkpoints) { checkpoint in
                    CheckpointPillView(
                        checkpoint: checkpoint,
                        onRestore: {},
                        onDelete: { checkpoints.removeAll(where: { $0.id == checkpoint.id }) }
                    )
                }

                if isCreating {
                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.accent.primary.swiftUIColor)
                        TextField("Name", text: $newCheckpointName, onCommit: commitCheckpoint)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .foregroundStyle(theme.text.primary.swiftUIColor)
                            .frame(width: 80)
                            .onExitCommand { isCreating = false }
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(theme.surfaces.elevated.swiftUIColor)
                            .overlay(Capsule().stroke(theme.accent.primary.swiftUIColor.opacity(0.5), lineWidth: 1))
                    )
                } else {
                    Button(action: startCreating) {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.text.quaternary.swiftUIColor)
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(theme.surfaces.hover.swiftUIColor))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
        }
        .frame(height: 28)
        .background(theme.surfaces.primary.swiftUIColor)
    }

    private func startCreating() {
        newCheckpointName = ""
        isCreating = true
    }

    private func commitCheckpoint() {
        let name = newCheckpointName.isEmpty ? "Checkpoint \(checkpoints.count + 1)" : newCheckpointName
        checkpoints.append(Checkpoint(name: name))
        isCreating = false
    }
}

struct CheckpointPillView: View {
    @Environment(\.deckTheme) private var theme
    let checkpoint: Checkpoint
    let onRestore: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "diamond.fill")
                .font(.system(size: 12))
                .foregroundStyle(theme.text.quaternary.swiftUIColor)
            Text(checkpoint.name)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.text.secondary.swiftUIColor)
                .lineLimit(1)
            Text(checkpoint.relativeTime)
                .font(.system(size: 12))
                .foregroundStyle(theme.text.quaternary.swiftUIColor)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(isHovered ? theme.surfaces.hover.swiftUIColor : theme.surfaces.elevated.swiftUIColor)
        )
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Restore") { onRestore() }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
    }
}
