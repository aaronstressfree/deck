import Foundation

/// Generates auto-names for sessions based on context.
enum AutoNamer {
    /// Generate an auto-name for a session.
    static func generateName(
        agentType: AgentType,
        workingDirectory: String,
        oscTitle: String? = nil,
        gitBranch: String? = nil,
        sessionIndex: Int = 0
    ) -> String {
        let dirName = URL(fileURLWithPath: workingDirectory).lastPathComponent

        // Priority 1: OSC title (shell-provided)
        if let title = oscTitle, !title.isEmpty {
            // Strip user@host: prefix if present (common in zsh)
            let cleaned = title
                .replacingOccurrences(of: #"^[^:]+:\s*"#, with: "", options: .regularExpression)
            if !cleaned.isEmpty {
                return cleaned
            }
        }

        // Priority 2: Git branch + directory name
        if let branch = gitBranch ?? GitDetector.currentBranch(in: workingDirectory) {
            return "\(dirName)/\(branch)"
        }

        // Priority 3: Directory name
        if dirName != NSHomeDirectory() && dirName != "aaronstevens" {
            return dirName
        }

        // Priority 4: Fallback
        return "Session \(sessionIndex + 1)"
    }
}
