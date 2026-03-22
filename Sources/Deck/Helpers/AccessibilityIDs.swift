import Foundation

/// Accessibility identifiers for UI testing.
enum AccessibilityID {
    // Sidebar
    static let sidebar = "sidebar"
    static let sessionRow = "session-row"
    static let newSessionButton = "new-session-button"
    static let newProjectButton = "new-project-button"
    static let sidebarFooter = "sidebar-footer"

    // Landing
    static let landingView = "landing-view"
    static let claudeCard = "claude-launch-card"
    static let ampCard = "amp-launch-card"
    static let shellCard = "shell-launch-card"

    // Terminal
    static let terminalView = "terminal-view"
    static let chatInput = "chat-input"
    static let sendButton = "send-button"
    static let rawModeToggle = "raw-mode-toggle"

    // Chat bar
    static let toolsAttachFile = "tools-attach-file"

    // Utility bar (workspace toggles above chat input)
    static let utilityBar = "utility-bar"
    static let toolsBrowser = "tools-browser"
    static let toolsContext = "tools-context"
    static let toolsInspect = "tools-inspect"
    static let toolsRawMode = "tools-raw-mode"

    // Session row
    static let sessionStatusDot = "session-status-dot"
    static let sessionStatusLabel = "session-status-label"
    static let sessionName = "session-name"

    // Session Chrome
    static let intentPin = "intent-pin"
    static let checkpointStrip = "checkpoint-strip"
    static let checkpointPill = "checkpoint-pill"

    // Status Bar
    static let statusBar = "status-bar"

    // Browser
    static let browserPane = "browser-pane"
    static let urlBar = "url-bar"

    // Settings
    static let settingsWindow = "settings-window"
}
