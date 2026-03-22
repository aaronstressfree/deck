import SwiftUI

struct TerminalContainerView: View {
    @Environment(\.deckTheme) private var theme
    @Binding var session: Session
    @Binding var urlBarFocused: Bool
    @ObservedObject var controller: TerminalController
    @ObservedObject var sessionManager: SessionManager
    @EnvironmentObject var designMode: DesignModeManager

    @State private var terminalTitle: String = ""
    @State private var contextExpanded: Bool = false

    private var isChatMode: Bool {
        sessionManager.isChatMode(for: session.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Context panel (slides down when expanded)
            SessionContextView(
                contextText: $session.intentText,
                isExpanded: $contextExpanded,
                agentType: session.agentType
            )

            // Context indicator — subtle bar when context exists but panel is collapsed
            if !contextExpanded, let ctx = session.intentText, !ctx.isEmpty {
                contextIndicator(ctx)
            }

            // Main content area
            if session.browserVisible {
                HSplitView {
                    terminalWithPadding.frame(minWidth: 300)

                    HStack(spacing: 0) {
                        BrowserPaneView(tabs: $session.browserTabs, activeTabId: $session.activeBrowserTabId, urlBarFocused: $urlBarFocused)
                            .frame(minWidth: 250)

                        // Design inspector appears to the right of browser when element selected
                        if designMode.isVisible {
                            RightPanelResizeHandle(
                                width: $designMode.panelWidth,
                                minWidth: 240,
                                maxWidth: 500
                            )
                            DesignPanelView()
                                .frame(width: designMode.panelWidth)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .frame(minWidth: designMode.isVisible ? 490 : 250)
                }
            } else {
                terminalWithPadding
            }

            // Utility bar — workspace toggles
            utilityBar

            // Chat input
            ChatInputView(
                sessionManager: sessionManager,
                sessionId: session.id,
                agentType: session.agentType,
                onSend: { text in controller.send(text) }
            )
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .background(theme.terminal.background.swiftUIColor)
    }

    // MARK: - Context indicator (collapsed state)

    private func contextIndicator(_ text: String) -> some View {
        Button(action: { withAnimation(.easeOut(duration: 0.15)) { contextExpanded = true } }) {
            HStack(spacing: 6) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.accent.primary.swiftUIColor)
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.text.tertiary.swiftUIColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(theme.accent.muted.swiftUIColor)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Terminal with padding

    private var terminalWithPadding: some View {
        terminalArea
            .padding(.horizontal, 8)
            .padding(.top, 4)
    }

    private var terminalArea: some View {
        TerminalBridge(
            sessionId: session.id,
            agentType: session.agentType,
            workingDirectory: session.workingDirectory,
            theme: theme,
            controller: controller,
            isChatMode: isChatMode,
            continueSession: session.claudeContinue,
            scrollbackPath: session.scrollbackPath,
            terminalTitle: $terminalTitle,
            agentStatus: $session.agentStatus,
            isRunning: $session.isRunning,
            exitCode: $session.exitCode
        )
        .onChange(of: terminalTitle) { _, newTitle in
            if session.name == nil && !newTitle.isEmpty {
                // Strip spinner/sparkle characters from OSC title
                let cleaned = newTitle
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: #"^[✳⠂⠐⠈⠑⠡⡀⢀⠠⠄⠁⠿\s]+"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)

                // Skip generic names — "Claude Code", "Amp", status messages
                let generic: Set<String> = [
                    "Claude Code", "claude", "Amp", "amp", "zsh", "bash",
                    "Thinking", "Thinking...", "Reading", "Writing", "Running",
                    "Assembling", "Planning", "Reasoning"
                ]
                if !cleaned.isEmpty && !generic.contains(cleaned) {
                    session.autoName = cleaned
                }
            }
        }
    }

    // MARK: - Utility bar (workspace toggles)

    private var utilityBar: some View {
        HStack(spacing: 14) {
            utilityButton(
                icon: session.browserVisible ? "sidebar.right" : "globe",
                label: "Browser",
                isActive: session.browserVisible,
                accessibilityId: AccessibilityID.toolsBrowser
            ) {
                session.browserVisible.toggle()
            }

            utilityButton(
                icon: "doc.text",
                label: "Context",
                isActive: contextExpanded || session.intentText != nil,
                accessibilityId: AccessibilityID.toolsContext
            ) {
                withAnimation(.easeOut(duration: 0.15)) { contextExpanded.toggle() }
            }

            if session.browserVisible {
                utilityButton(
                    icon: "cursorarrow.click.2",
                    label: "Inspect",
                    isActive: designMode.inspectMode,
                    accessibilityId: AccessibilityID.toolsInspect
                ) {
                    designMode.toggleInspect()
                }
            }

            Spacer()

            utilityButton(
                icon: isChatMode ? "text.bubble" : "keyboard",
                label: isChatMode ? "Chat" : "Raw",
                isActive: !isChatMode,
                accessibilityId: AccessibilityID.toolsRawMode
            ) {
                sessionManager.toggleChatMode(for: session.id)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }

    private func utilityButton(icon: String, label: String, isActive: Bool, accessibilityId: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 14))
            }
            .foregroundStyle(isActive ? theme.accent.primary.swiftUIColor : theme.text.quaternary.swiftUIColor)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityId)
    }

}
