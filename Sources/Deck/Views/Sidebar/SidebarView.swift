import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @Environment(\.deckTheme) private var theme
    @ObservedObject var sessionManager: SessionManager

    @State private var showTodos = false
    @State private var showNewProject = false

    var body: some View {
        VStack(spacing: 0) {
            // Minimal clearance for traffic lights
            Color.clear.frame(height: 2)

            // Project list — every session belongs to a project
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(sortedProjects) { group in
                        let groupSessions = sessionManager.sessions.filter { $0.groupId == group.id }
                        SessionGroupView(
                            group: group,
                            sessions: groupSessions,
                            allGroups: sessionManager.groups,
                            activeSessionId: sessionManager.activeSessionId,
                            onToggleCollapse: { sessionManager.toggleGroupCollapsed(id: group.id) },
                            onSelectSession: { sessionManager.switchToSession(id: $0) },
                            onCloseSession: { sessionManager.closeSession(id: $0) },
                            onRenameSession: { id, name in sessionManager.renameSession(id: id, name: name) },
                            onMoveSession: { id, groupId in sessionManager.moveSession(id: id, toGroup: groupId) },
                            onRenameGroup: { name in sessionManager.renameGroup(id: group.id, name: name) },
                            onDeleteGroup: { sessionManager.deleteGroup(id: group.id) },
                            onNewSession: { agentType in
                                sessionManager.createSession(
                                    agentType: agentType,
                                    workingDirectory: group.workingDirectory,
                                    groupId: group.id
                                )
                            },
                            onUpdateInstructions: { instructions in
                                sessionManager.updateGroupInstructions(id: group.id, instructions: instructions)
                            }
                        )
                    }

                    // Empty state
                    if sessionManager.sessions.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)
            }

            Spacer(minLength: 0)

            // To-do — collapsible
            if showTodos || !sessionManager.todos.isEmpty {
                Divider().background(theme.borders.subtle.swiftUIColor)
                todoSection
            }

            // Footer
            Divider().background(theme.borders.subtle.swiftUIColor)

            SidebarFooter(
                activeProjectName: sessionManager.activeProject?.name,
                onNewClaude: { sessionManager.createSession(agentType: .claude) },
                onNewAmp: { sessionManager.createSession(agentType: .amp) },
                onNewShell: { sessionManager.createSession(agentType: .shell) },
                onNewProject: { name, dir in
                    sessionManager.createGroup(name: name, workingDirectory: dir)
                },
                onShowNewProject: { showNewProject = true }
            )
        }
        .background(theme.surfaces.inset.swiftUIColor)
        .sheet(isPresented: $showNewProject) {
            NewProjectSheet(
                onCreate: { name, dir in
                    sessionManager.createGroup(name: name, workingDirectory: dir)
                }
            )
        }
    }

    // MARK: - Sorted projects (active project first)

    private var sortedProjects: [SessionGroup] {
        let activeProjectId = sessionManager.activeSession?.groupId
        // Pre-compute latest activity per group in one pass (O(n) instead of O(n²))
        var latestByGroup: [UUID: Date] = [:]
        for session in sessionManager.sessions {
            if let gid = session.groupId {
                if let existing = latestByGroup[gid] {
                    if session.lastActiveAt > existing { latestByGroup[gid] = session.lastActiveAt }
                } else {
                    latestByGroup[gid] = session.lastActiveAt
                }
            }
        }
        return sessionManager.groups.sorted { a, b in
            if a.id == activeProjectId { return true }
            if b.id == activeProjectId { return false }
            let aLatest = latestByGroup[a.id] ?? .distantPast
            let bLatest = latestByGroup[b.id] ?? .distantPast
            return aLatest > bLatest
        }
    }

    // MARK: - To-do section

    private var todoSection: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation(.easeOut(duration: 0.15)) { showTodos.toggle() } }) {
                HStack(spacing: 6) {
                    Image(systemName: showTodos ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(theme.text.quaternary.swiftUIColor)
                        .frame(width: 10)
                    Text("TO-DO")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.text.quaternary.swiftUIColor)
                        .tracking(0.5)

                    let count = sessionManager.todos.filter { !$0.isCompleted }.count
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(theme.text.quaternary.swiftUIColor)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(theme.surfaces.hover.swiftUIColor))
                    }
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
            }
            .buttonStyle(.plain)

            if showTodos {
                TodoListView(todos: $sessionManager.todos)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 60)
            Image(systemName: "terminal")
                .font(.system(size: 28))
                .foregroundStyle(theme.text.quaternary.swiftUIColor)
            Text("No sessions")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(theme.text.tertiary.swiftUIColor)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
