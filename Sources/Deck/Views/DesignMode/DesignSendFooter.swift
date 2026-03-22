import SwiftUI

struct DesignSendFooter: View {
    @Environment(\.deckTheme) private var theme
    @EnvironmentObject var designMode: DesignModeManager
    @EnvironmentObject var sessionManager: SessionManager

    private var agentSessions: [(Session, TerminalController)] {
        sessionManager.sessions
            .filter { $0.agentType != .shell }
            .compactMap { session in
                let controller = sessionManager.controllerFor(sessionId: session.id)
                return (session, controller)
            }
    }

    var body: some View {
        HStack(spacing: 10) {
            // Change count
            if designMode.hasChanges {
                Text("\(designMode.changeCount)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(theme.accent.primary.swiftUIColor)
                +
                Text(" change\(designMode.changeCount == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.text.tertiary.swiftUIColor)
            }

            Spacer()

            // Reset — reloads page to undo all live changes
            if designMode.hasChanges {
                Button(action: { designMode.resetPreview() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11))
                        Text("Reset")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(theme.text.tertiary.swiftUIColor)
                }
                .buttonStyle(.plain)
                .help("Reset all changes and reload page")
            }

            // Preview
            Button(action: { designMode.showPreview = true }) {
                Image(systemName: "eye")
                    .font(.system(size: 12))
                    .foregroundStyle(designMode.hasChanges ? theme.text.secondary.swiftUIColor : theme.text.quaternary.swiftUIColor)
            }
            .buttonStyle(.plain)
            .disabled(!designMode.hasChanges)
            .help("Preview instructions")
            .sheet(isPresented: $designMode.showPreview) {
                DesignPreviewSheet()
            }

            // Copy
            Button(action: { designMode.copyToClipboard() }) {
                Image(systemName: designMode.copiedConfirmation ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 12))
                    .foregroundStyle(designMode.copiedConfirmation ? Color.green : (designMode.hasChanges ? theme.text.secondary.swiftUIColor : theme.text.quaternary.swiftUIColor))
            }
            .buttonStyle(.plain)
            .disabled(!designMode.hasChanges)
            .help("Copy instructions to clipboard")

            // Send
            if agentSessions.count == 1, let (_, controller) = agentSessions.first {
                Button(action: { designMode.sendToSession(controller: controller) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 11))
                        Text("Send")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(designMode.hasChanges ? theme.accent.primary.swiftUIColor : theme.text.quaternary.swiftUIColor)
                }
                .buttonStyle(.plain)
                .disabled(!designMode.hasChanges)
            } else if agentSessions.count > 1 {
                Menu {
                    ForEach(agentSessions, id: \.0.id) { session, controller in
                        Button(session.displayName) {
                            designMode.sendToSession(controller: controller)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 11))
                        Text("Send")
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8))
                    }
                    .foregroundStyle(designMode.hasChanges ? theme.accent.primary.swiftUIColor : theme.text.quaternary.swiftUIColor)
                }
                .menuStyle(.borderlessButton)
                .disabled(!designMode.hasChanges)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(theme.surfaces.elevated.swiftUIColor)
    }
}
