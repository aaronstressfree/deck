import Foundation

/// Parses terminal title + buffer to detect AI agent status.
///
/// Status meanings from the USER's perspective:
/// - **Idle**: Agent is done, showing its prompt. Nothing happening.
/// - **Thinking**: Agent is processing/reasoning. User waits.
/// - **Writing**: Agent is creating or editing files.
/// - **Running**: Agent is executing commands, reading files, searching.
/// - **Waiting for input**: Agent needs a YES/NO decision from the user (permission prompts).
/// - **Error**: Something went wrong.
///
/// Key design decision: "Waiting for input" only shows for permission prompts,
/// NOT when the agent is simply done and showing its prompt. That's "Idle."
final class AgentOutputParser {

    static func parseStatus(from output: String, agentType: AgentType) -> AgentStatus? {
        switch agentType {
        case .claude: return parseClaudeStatus(from: output)
        case .amp: return parseAmpStatus(from: output)
        case .shell: return nil
        }
    }

    // MARK: - Claude Code

    private static func parseClaudeStatus(from output: String) -> AgentStatus? {
        // Split into title (first line, set via OSC) and buffer (remaining lines)
        let lines = output.components(separatedBy: "\n")
        let titleLine = lines.first ?? ""
        let bufferText = lines.dropFirst().joined(separator: "\n").lowercased()

        // 1. TERMINAL TITLE — most reliable signal (set by Claude Code via OSC)
        if let firstChar = titleLine.first {
            let brailleSpinner: Set<Character> = ["⠂", "⠐", "⠈", "⠑", "⠡", "⡀", "⢀", "⠠", "⠄", "⠁"]

            if firstChar == "✳" || firstChar == "⠿" {
                // Sparkle = agent is done, showing prompt → Idle
                // Don't check buffer — old permission prompts might still be visible
                return .idle
            }

            if brailleSpinner.contains(firstChar) {
                // Spinner = agent is actively working. Parse the task description.
                let task = titleLine.dropFirst().trimmingCharacters(in: .whitespaces).lowercased()

                if task == "claude code" || task.isEmpty {
                    return .thinking
                }
                if task.contains("thinking") || task.contains("planning") || task.contains("reasoning") {
                    return .thinking
                }
                if task.contains("writing") || task.contains("editing") || task.contains("creating") || task.contains("updating") {
                    return .writing
                }
                // Everything else while spinner is active = running
                return .running
            }
        }

        // 2. BUFFER KEYWORDS — fallback when title doesn't have spinner/sparkle
        // Only check buffer if title didn't give us a definitive answer
        let lower = (titleLine + "\n" + bufferText).lowercased()

        // Permission prompts — agent genuinely needs user action
        // Only match these if they appear in the LAST FEW LINES (not old scrollback)
        let recentBuffer = lines.suffix(5).joined(separator: "\n").lowercased()
        if recentBuffer.contains("bypass permissions") || recentBuffer.contains("allow?") ||
           recentBuffer.contains("(y/n)") || recentBuffer.contains("shift+tab to cycle") ||
           recentBuffer.contains("approve") || recentBuffer.contains("enter to confirm") {
            return .waitingForInput
        }

        // Active work keywords
        if lower.contains("thinking") || lower.contains("assembling") || lower.contains("planning") {
            return .thinking
        }
        if lower.contains("writing to") || lower.contains("editing") {
            return .writing
        }
        if lower.contains("reading") || lower.contains("searching") || lower.contains("running") ||
           lower.contains("executing") || lower.contains("compiling") ||
           lower.contains("bash(") || lower.contains("read(") {
            return .running
        }

        // The prompt character "❯" or ">" at the start of a recent line = idle
        let lastNonEmpty = lines.last(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? ""
        let trimmedLast = lastNonEmpty.trimmingCharacters(in: .whitespaces)
        if trimmedLast == "❯" || trimmedLast == ">" || trimmedLast.hasSuffix("❯") || trimmedLast.hasSuffix("> ") {
            return .idle
        }

        return nil
    }

    // MARK: - Amp

    private static func parseAmpStatus(from output: String) -> AgentStatus? {
        let lines = output.components(separatedBy: "\n")
        let recentBuffer = lines.suffix(5).joined(separator: "\n").lowercased()

        // Amp uses different terminal conventions than Claude Code
        // Check recent buffer lines for status indicators

        // Permission/confirmation prompts
        if recentBuffer.contains("confirm") || recentBuffer.contains("(y/n)") ||
           recentBuffer.contains("approve") || recentBuffer.contains("allow") {
            return .waitingForInput
        }

        // Active work
        if recentBuffer.contains("thinking") || recentBuffer.contains("reasoning") || recentBuffer.contains("planning") {
            return .thinking
        }
        if recentBuffer.contains("editing") || recentBuffer.contains("writing") || recentBuffer.contains("creating") {
            return .writing
        }
        if recentBuffer.contains("running") || recentBuffer.contains("executing") || recentBuffer.contains("reading") {
            return .running
        }

        // Amp prompt indicators — agent is done
        if recentBuffer.contains("amp>") || recentBuffer.contains("amp ❯") {
            return .idle
        }

        return nil
    }
}
