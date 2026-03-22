import Foundation

/// Parses terminal title + buffer to detect AI agent status.
/// Priority: keyword matching first (most specific), then spinner character fallback.
final class AgentOutputParser {

    static func parseStatus(from output: String, agentType: AgentType) -> AgentStatus? {
        switch agentType {
        case .claude: return parseClaudeStatus(from: output)
        case .amp: return parseAmpStatus(from: output)
        case .shell: return nil
        }
    }

    private static func parseClaudeStatus(from output: String) -> AgentStatus? {
        let lower = output.lowercased()

        // 1. KEYWORDS — highest priority, most specific
        // Check for explicit status words anywhere in title + buffer

        // Waiting for user input (highest priority — needs user action)
        if lower.contains("bypass permissions") || lower.contains("allow?") ||
           lower.contains("(y/n)") || lower.contains("shift+tab to cycle") ||
           lower.contains("approve") || lower.contains("confirm") ||
           lower.contains("enter to confirm") {
            return .waitingForInput
        }

        // Thinking
        if lower.contains("thinking") || lower.contains("assembling") ||
           lower.contains("planning") || lower.contains("reasoning") ||
           lower.contains("high effort") {
            return .thinking
        }

        // Writing/creating files
        if lower.contains("writing to") || lower.contains("editing") ||
           lower.contains("creating") || lower.contains("updating") ||
           lower.contains("wrote to") {
            return .writing
        }

        // Reading/executing
        if lower.contains("reading") || lower.contains("searching") ||
           lower.contains("running") || lower.contains("executing") ||
           lower.contains("compiling") || lower.contains("bash(") ||
           lower.contains("read(") || lower.contains("searching for") {
            return .running
        }

        // Errors
        if lower.contains("error:") || lower.contains("failed") {
            return .error
        }

        // 2. SPINNER CHARACTER — fallback for title-only detection
        // Claude Code title starts with a spinner or sparkle character
        let titleLine = output.components(separatedBy: "\n").first ?? output
        if let firstChar = titleLine.first {
            let brailleSpinner: Set<Character> = ["⠂", "⠐", "⠈", "⠑", "⠡", "⡀", "⢀", "⠠", "⠄", "⠁"]
            if brailleSpinner.contains(firstChar) {
                let task = titleLine.dropFirst().trimmingCharacters(in: .whitespaces)
                if task == "Claude Code" {
                    return .thinking
                }
                return .running
            }
            // ✳ sparkle = idle/done
            if firstChar == "✳" || firstChar == "⠿" {
                return .idle
            }
        }

        return nil
    }

    private static func parseAmpStatus(from output: String) -> AgentStatus? {
        let lower = output.lowercased()

        if lower.contains("thinking") || lower.contains("reasoning") || lower.contains("planning") {
            return .thinking
        }
        if lower.contains("editing") || lower.contains("writing") || lower.contains("creating") {
            return .writing
        }
        if lower.contains("running") || lower.contains("executing") || lower.contains("reading") {
            return .running
        }
        if lower.contains("confirm") || lower.contains("(y/n)") {
            return .waitingForInput
        }
        return nil
    }
}
