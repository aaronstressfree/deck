import SwiftUI

/// Minimal status bar — shows only what's relevant, no visual noise.
struct StatusBarView: View {
    @Environment(\.deckTheme) private var theme
    let session: Session?

    @State private var gitBranch: String?
    @State private var isDirty: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            if let session = session {
                // CWD
                Text(truncatedPath(session.workingDirectory))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
                    .lineLimit(1)
                    .help(session.workingDirectory)

                // Git branch
                if let branch = gitBranch {
                    separator
                    Circle()
                        .fill(isDirty ? theme.status.warning.primary.swiftUIColor : theme.status.success.primary.swiftUIColor)
                        .frame(width: 5, height: 5)
                    Text(branch)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(theme.text.quaternary.swiftUIColor)
                        .padding(.leading, 3)
                }

                Spacer()

                // Agent badge — right side
                Text(session.agentType.displayName)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 22)
        .background(theme.surfaces.bar.swiftUIColor)
        .overlay(
            Rectangle().frame(height: 1).foregroundStyle(theme.borders.subtle.swiftUIColor),
            alignment: .top
        )
        .onChange(of: session?.workingDirectory) { _, cwd in updateGitInfo(cwd: cwd) }
        .onAppear { updateGitInfo(cwd: session?.workingDirectory) }
    }

    private var separator: some View {
        Text("·")
            .font(.system(size: 12))
            .foregroundStyle(theme.text.quaternary.swiftUIColor)
            .padding(.horizontal, 5)
    }

    private func truncatedPath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        var display = path
        if display.hasPrefix(home) {
            display = "~" + display.dropFirst(home.count)
        }
        if display.count > 35 {
            let parts = display.split(separator: "/")
            if parts.count > 3 {
                return "\(parts.first!)/…/\(parts.suffix(2).joined(separator: "/"))"
            }
        }
        return display
    }

    private func updateGitInfo(cwd: String?) {
        guard let cwd = cwd else { return }
        Task.detached {
            let branch = GitDetector.currentBranch(in: cwd)
            let dirty = GitDetector.isDirty(directory: cwd)
            await MainActor.run { gitBranch = branch; isDirty = dirty }
        }
    }
}
