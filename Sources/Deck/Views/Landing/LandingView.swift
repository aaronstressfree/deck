import SwiftUI

struct LandingView: View {
    @Environment(\.deckTheme) private var theme
    @ObservedObject var sessionManager: SessionManager

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Minimal branding
                VStack(spacing: 6) {
                    Text("Deck")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundStyle(theme.text.primary.swiftUIColor)
                    Text("AI-first terminal")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.text.tertiary.swiftUIColor)
                }

                // Launch options — clean cards
                HStack(spacing: 10) {
                    launchCard(
                        icon: "sparkles",
                        title: "Claude Code",
                        shortcut: "⌘⇧C",
                        isPrimary: true,
                        action: { sessionManager.createSession(agentType: .claude) }
                    )
                    launchCard(
                        icon: "bolt.fill",
                        title: "Amp",
                        shortcut: "⌘⇧A",
                        isPrimary: false,
                        action: { sessionManager.createSession(agentType: .amp) }
                    )
                    launchCard(
                        icon: "terminal.fill",
                        title: "Shell",
                        shortcut: "⌘N",
                        isPrimary: false,
                        action: { sessionManager.createSession(agentType: .shell) }
                    )
                }

                // Recent sessions — only if they exist
                if !sessionManager.recentSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Recent")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(theme.text.quaternary.swiftUIColor)
                            .tracking(0.5)

                        ForEach(sessionManager.recentSessions.prefix(3)) { session in
                            Button(action: { sessionManager.switchToSession(id: session.id) }) {
                                HStack(spacing: 6) {
                                    Image(systemName: session.agentType.iconName)
                                        .font(.system(size: 14))
                                        .foregroundStyle(theme.text.quaternary.swiftUIColor)
                                        .frame(width: 16)
                                    Text(session.displayName)
                                        .font(.system(size: 14))
                                        .foregroundStyle(theme.text.secondary.swiftUIColor)
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(width: 260)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.surfaces.primary.swiftUIColor)
    }

    private func launchCard(icon: String, title: String, shortcut: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(
                        isPrimary ? theme.accent.primary.swiftUIColor : theme.text.tertiary.swiftUIColor
                    )
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.text.primary.swiftUIColor)
                Text(shortcut)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
            }
            .frame(width: 100, height: 90)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.surfaces.elevated.swiftUIColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isPrimary ? theme.accent.primary.swiftUIColor.opacity(0.2) : theme.borders.subtle.swiftUIColor,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
