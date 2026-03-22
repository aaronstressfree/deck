import Foundation

/// The type of agent/process a session runs.
enum AgentType: String, Codable, Hashable, Sendable, CaseIterable {
    case claude = "claude"
    case amp = "amp"
    case shell = "shell"

    /// Display name for the agent
    var displayName: String {
        switch self {
        case .claude: return "Claude Code"
        case .amp: return "Amp"
        case .shell: return "Shell"
        }
    }

    /// SF Symbol name for the agent icon
    var iconName: String {
        switch self {
        case .claude: return "sparkles"
        case .amp: return "bolt.fill"
        case .shell: return "terminal.fill"
        }
    }

    /// The executable to spawn.
    /// For Claude/Amp: spawns a login shell that runs the CLI, so PATH is resolved correctly.
    /// For Shell: spawns $SHELL directly.
    var command: String {
        switch self {
        case .claude, .amp:
            // Use a shell wrapper so PATH resolution works (homebrew, nvm, etc.)
            return ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        case .shell:
            return ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        }
    }

    /// Arguments to pass when spawning.
    /// `continueSession` resumes the previous conversation (Claude --continue).
    func arguments(continueSession: Bool = false) -> [String] {
        switch self {
        case .claude:
            let continueFlag = continueSession ? " --continue" : ""
            return ["-l", "-i", "-c", "claude\(continueFlag) || { echo '\\n⚠ claude not found. Install: npm install -g @anthropic-ai/claude-code'; exec zsh -l; }"]
        case .amp:
            let resumeCmd = continueSession ? "amp threads continue --last" : "amp"
            return ["-l", "-i", "-c", "\(resumeCmd) || { echo '\\n⚠ amp not found. Install: npm install -g @anthropic-ai/amp'; exec zsh -l; }"]
        case .shell:
            return ["--login", "-i"]
        }
    }

    /// Default arguments (no session continuation)
    var defaultArguments: [String] { arguments() }

    /// Whether the CLI is available on this system
    var isAvailable: Bool {
        switch self {
        case .shell: return true
        case .claude:
            return resolveCommand("claude") != nil
        case .amp:
            return resolveCommand("amp") != nil
        }
    }

    /// Placeholder text for the chat input
    var inputPlaceholder: String {
        switch self {
        case .claude: return "Send a prompt to Claude..."
        case .amp: return "Send a prompt to Amp..."
        case .shell: return "Type a command..."
        }
    }

    /// Short prefix for auto-naming
    var namePrefix: String {
        switch self {
        case .claude: return "Claude"
        case .amp: return "Amp"
        case .shell: return "Shell"
        }
    }

    /// Try to find a command in PATH
    private func resolveCommand(_ name: String) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = [name]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
            task.waitUntilExit()
            guard task.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return path?.isEmpty == false ? path : nil
        } catch {
            return nil
        }
    }
}
