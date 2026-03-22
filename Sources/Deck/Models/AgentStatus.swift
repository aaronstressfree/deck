import Foundation

/// The current status of an AI agent, parsed from terminal output.
enum AgentStatus: String, Codable, Hashable, Sendable {
    case idle = "idle"
    case thinking = "thinking"
    case writing = "writing"
    case running = "running"
    case waitingForInput = "waitingForInput"
    case error = "error"

    /// Human-readable label
    var label: String {
        switch self {
        case .idle: return "Idle"
        case .thinking: return "Thinking..."
        case .writing: return "Writing code..."
        case .running: return "Running..."
        case .waitingForInput: return "Waiting for input"
        case .error: return "Error"
        }
    }

    /// SF Symbol for this status
    var iconName: String {
        switch self {
        case .idle: return "circle.fill"
        case .thinking: return "brain"
        case .writing: return "pencil.line"
        case .running: return "play.circle.fill"
        case .waitingForInput: return "questionmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    /// Whether this status indicates active work
    var isActive: Bool {
        switch self {
        case .thinking, .writing, .running: return true
        default: return false
        }
    }
}
