import SwiftUI

/// Shows and edits ALL context sent to AI agents.
/// Three-level instruction hierarchy: Global → Group → Session.
/// Also shows a live preview of the full context that gets injected.
struct ContextSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var sessionManager: SessionManager

    @State private var previewSessionId: UUID?
    @State private var editingGroupId: UUID?

    var body: some View {
        HSplitView {
            // Left: instruction editor
            instructionEditor
                .frame(minWidth: 280, maxWidth: 350)

            // Right: live preview of what the agent sees
            contextPreview
                .frame(minWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Instruction Editor

    private var instructionEditor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Global instructions
                VStack(alignment: .leading, spacing: 6) {
                    Label("Global Instructions", systemImage: "globe")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Applied to every session, every agent.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    TextEditor(text: $sessionManager.globalInstructions)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(minHeight: 100, maxHeight: 200)
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.1)))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                }

                Divider()

                // Group instructions
                VStack(alignment: .leading, spacing: 8) {
                    Label("Project Instructions", systemImage: "folder")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Applied to all sessions in a project.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)

                    if sessionManager.groups.isEmpty {
                        Text("No projects created yet. Create a project to add project-level instructions.")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 4)
                    }

                    ForEach($sessionManager.groups) { $group in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(group.name)
                                    .font(.system(size: 11, weight: .medium))
                                Spacer()
                                Text("\(sessionManager.sessions.filter { $0.groupId == group.id }.count) sessions")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                            }
                            TextEditor(text: $group.instructions)
                                .font(.system(size: 12, design: .monospaced))
                                .frame(minHeight: 60, maxHeight: 120)
                                .padding(4)
                                .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.08)))
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                        }
                    }
                }

                Divider()

                // Per-session context
                VStack(alignment: .leading, spacing: 8) {
                    Label("Session Context", systemImage: "doc.text")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Set per-session via the Context button in the toolbar.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)

                    ForEach($sessionManager.sessions) { $session in
                        HStack(spacing: 8) {
                            Image(systemName: session.agentType.iconName)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .frame(width: 14)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.displayName)
                                    .font(.system(size: 11, weight: .medium))
                                if let ctx = session.intentText, !ctx.isEmpty {
                                    Text(ctx)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                } else {
                                    Text("No context set")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            Spacer()
                            Button("Preview") {
                                previewSessionId = session.id
                            }
                            .font(.system(size: 10))
                            .buttonStyle(.plain)
                            .foregroundStyle(.blue)
                        }
                        .padding(.vertical, 2)
                    }

                    if sessionManager.sessions.isEmpty {
                        Text("No active sessions.")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Context Preview

    private var contextPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Context Preview", systemImage: "eye")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                if let id = previewSessionId,
                   let session = sessionManager.sessions.first(where: { $0.id == id }) {
                    Text("Viewing: \(session.displayName)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)

            Text("This is exactly what the AI agent sees — injected via CLAUDE.md and .cursorrules.")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .padding(.horizontal)

            // Pick a session to preview
            if !sessionManager.sessions.isEmpty {
                Picker("Preview session:", selection: $previewSessionId) {
                    Text("Select a session").tag(UUID?.none)
                    ForEach(sessionManager.sessions) { session in
                        Text(session.displayName).tag(Optional(session.id))
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
            }

            // The actual preview
            ScrollView {
                if let id = previewSessionId,
                   let session = sessionManager.sessions.first(where: { $0.id == id }) {
                    let siblings = sessionManager.sessions.filter { $0.id != id && $0.isRunning }
                    let preview = DeckContext.previewContext(
                        session: session,
                        siblings: siblings,
                        groups: sessionManager.groups,
                        globalInstructions: sessionManager.globalInstructions
                    )
                    Text(preview)
                        .font(.system(size: 10, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                } else {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 24))
                            .foregroundStyle(.tertiary)
                        Text("Select a session to preview its context")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .background(Color.gray.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}
