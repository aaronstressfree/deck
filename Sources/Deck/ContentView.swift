import SwiftUI

struct ContentView: View {
    @Environment(\.deckTheme) private var theme
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var designMode: DesignModeManager
    let appDelegate: DeckAppDelegate
    @ObservedObject var sessionManager: SessionManager
    @Binding var urlBarFocused: Bool
    @Binding var showNewSessionSheet: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                if sessionManager.sidebarCollapsed {
                    // Collapsed: thin icon strip
                    collapsedSidebar
                        .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
                    // Expanded: full sidebar
                    SidebarView(sessionManager: sessionManager)
                        .frame(width: sessionManager.sidebarWidth)
                        .transition(.move(edge: .leading).combined(with: .opacity))

                    SidebarResizeHandle(
                        width: $sessionManager.sidebarWidth,
                        minWidth: 160,
                        maxWidth: 360
                    )
                    .transition(.opacity)
                }

                // Main content — ALL sessions live in a ZStack, only active one is visible.
                // This keeps terminal processes alive when switching tabs.
                ZStack {
                    theme.surfaces.primary.swiftUIColor
                        .ignoresSafeArea()

                    if sessionManager.sessions.isEmpty {
                        LandingView(sessionManager: sessionManager)
                    } else {
                        // Keep every session's terminal alive
                        ForEach(sessionManager.sessions) { session in
                            if let binding = sessionBinding(for: session.id) {
                                let isActive = session.id == sessionManager.activeSessionId
                                TerminalContainerView(
                                    session: binding,
                                    urlBarFocused: $urlBarFocused,
                                    controller: sessionManager.controllerFor(sessionId: session.id),
                                    sessionManager: sessionManager
                                )
                                .opacity(isActive ? 1 : 0)
                                .allowsHitTesting(isActive)
                                .transaction { $0.animation = nil }
                            }
                        }

                        // Show landing if no session is active (all closed but array not empty yet)
                        if sessionManager.activeSessionId == nil {
                            LandingView(sessionManager: sessionManager)
                        }
                    }
                }
            }

            StatusBarView(session: sessionManager.activeSession)
        }
        .frame(minWidth: 800, minHeight: 500)
        .background(theme.surfaces.primary.swiftUIColor)
    }

    // MARK: - Collapsed sidebar (thin icon strip)

    private var collapsedSidebar: some View {
        VStack(spacing: 0) {
            // Traffic light space
            Color.clear.frame(height: 28)

            // Expand button
            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) { sessionManager.sidebarCollapsed = false }
            }) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
                    .frame(width: 44, height: 28)
            }
            .buttonStyle(HoverButtonStyle(hoverColor: theme.surfaces.hover.swiftUIColor))
            .help("Show sidebar (⌘⇧L)")

            Divider().background(theme.borders.subtle.swiftUIColor)

            // Session icons grouped by project
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(sessionManager.groups) { group in
                        let groupSessions = sessionManager.sessions.filter { $0.groupId == group.id }
                        if !groupSessions.isEmpty {
                            // Project divider dot
                            if group.id != sessionManager.groups.first?.id {
                                Circle()
                                    .fill(theme.borders.subtle.swiftUIColor)
                                    .frame(width: 3, height: 3)
                                    .padding(.vertical, 4)
                            }

                            ForEach(groupSessions) { session in
                                collapsedSessionIcon(session)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Spacer(minLength: 0)

            // Quick new session button
            Divider().background(theme.borders.subtle.swiftUIColor)
            Button(action: { sessionManager.createSession(agentType: .claude) }) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.text.secondary.swiftUIColor)
                    .frame(width: 44, height: 32)
            }
            .buttonStyle(.plain)
            .help("New session")
        }
        .frame(width: 44)
        .background(theme.surfaces.inset.swiftUIColor)
    }

    private func collapsedSessionIcon(_ session: Session) -> some View {
        Button(action: { sessionManager.switchToSession(id: session.id) }) {
            ZStack {
                // Agent type icon
                Image(systemName: session.agentType.iconName)
                    .font(.system(size: 14))
                    .foregroundStyle(
                        session.id == sessionManager.activeSessionId
                            ? theme.accent.primary.swiftUIColor
                            : theme.text.tertiary.swiftUIColor
                    )

                // Status dot overlay (top-right)
                if session.isRunning && session.agentStatus.isActive {
                    Circle()
                        .fill(theme.accent.primary.swiftUIColor)
                        .frame(width: 5, height: 5)
                        .offset(x: 8, y: -8)
                        .opacity(0.8)
                }
            }
            .frame(width: 32, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(session.id == sessionManager.activeSessionId
                        ? theme.surfaces.selected.swiftUIColor
                        : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .help({
            let projectName = sessionManager.groups.first(where: { $0.id == session.groupId })?.name
            if let projectName {
                return "\(projectName) — \(session.displayName)"
            }
            return session.displayName
        }())
    }

    private func sessionBinding(for id: UUID) -> Binding<Session>? {
        sessionManager.bindingFor(sessionId: id)
    }
}
