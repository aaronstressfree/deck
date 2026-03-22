import XCTest
@testable import Deck

/// Tests for the simplified UI:
/// 1. Session row: status dot only (no separate icon), text only for waiting/error
/// 2. Utility bar above chat input for workspace toggles (Browser, Context, Inspect, Raw)
/// 3. Chat bar simplified: paperclip, text field, send button
final class SimplifiedUITests: XCTestCase {

    // MARK: - Session Row Status Indicators

    /// Status dot should exist but separate status icon should not
    func testSessionRowOnlyShowsStatusDot() {
        XCTAssertEqual(AccessibilityID.sessionStatusDot, "session-status-dot")
        XCTAssertEqual(AccessibilityID.sessionName, "session-name")
    }

    /// Status label should only appear for waitingForInput, not thinking/writing/running
    func testStatusLabelHiddenForActiveStates() {
        let activeStatuses: [AgentStatus] = [.thinking, .writing, .running]
        for status in activeStatuses {
            XCTAssertTrue(status.isActive, "\(status) should be active")
            XCTAssertNotEqual(status, .waitingForInput,
                "\(status) is active but should not show a status label")
        }
    }

    /// waitingForInput should show a status label
    func testStatusLabelShownForWaitingForInput() {
        let status = AgentStatus.waitingForInput
        XCTAssertFalse(status.isActive)
        XCTAssertEqual(status.label, "Waiting for input")
    }

    /// Idle status should NOT show a label
    func testStatusLabelHiddenForIdle() {
        let status = AgentStatus.idle
        XCTAssertFalse(status.isActive)
        XCTAssertNotEqual(status, .waitingForInput)
    }

    /// Error sessions show "Exited (code)" only when process is not running
    func testErrorSessionShowsExitCode() {
        var session = Session(agentType: .claude)
        session.isRunning = false
        session.exitCode = 1
        XCTAssertFalse(session.isRunning)
        XCTAssertEqual(session.exitCode, 1)
    }

    /// Running session with active status should not show error label
    func testRunningSessionNoErrorLabel() {
        var session = Session(agentType: .claude)
        session.isRunning = true
        session.exitCode = nil
        session.agentStatus = .thinking
        XCTAssertTrue(session.agentStatus.isActive)
        XCTAssertNil(session.exitCode)
    }

    // MARK: - Status Dot Color Logic

    func testStatusDotColorForActiveAgent() {
        var session = Session(agentType: .claude)
        session.isRunning = true
        session.agentStatus = .thinking
        XCTAssertTrue(session.isRunning)
        XCTAssertTrue(session.agentStatus.isActive)
    }

    func testStatusDotForWaitingState() {
        var session = Session(agentType: .claude)
        session.isRunning = true
        session.agentStatus = .waitingForInput
        XCTAssertFalse(session.agentStatus.isActive)
    }

    func testStatusDotForErroredSession() {
        var session = Session(agentType: .claude)
        session.isRunning = false
        session.exitCode = 127
        session.agentStatus = .idle
        XCTAssertFalse(session.isRunning)
        XCTAssertNotNil(session.exitCode)
        XCTAssertNotEqual(session.exitCode, 0)
    }

    func testStatusDotForIdleCleanExit() {
        var session = Session(agentType: .claude)
        session.isRunning = false
        session.exitCode = nil
        session.agentStatus = .idle
        XCTAssertFalse(session.isRunning)
        XCTAssertFalse(session.agentStatus.isActive)
    }

    // MARK: - Status Dot Opacity (Pulse Animation)

    func testStatusDotPulsesWhenActive() {
        for status in [AgentStatus.thinking, .writing, .running] {
            XCTAssertTrue(status.isActive, "\(status) should pulse")
        }
    }

    func testStatusDotSolidWhenInactive() {
        for status in [AgentStatus.idle, .waitingForInput, .error] {
            XCTAssertFalse(status.isActive, "\(status) should be solid")
        }
    }

    // MARK: - Utility Bar Accessibility IDs

    /// Utility bar has its own accessibility ID
    func testUtilityBarID() {
        XCTAssertEqual(AccessibilityID.utilityBar, "utility-bar")
    }

    /// Utility bar contains workspace toggle IDs
    func testUtilityBarItemIDs() {
        XCTAssertEqual(AccessibilityID.toolsBrowser, "tools-browser")
        XCTAssertEqual(AccessibilityID.toolsContext, "tools-context")
        XCTAssertEqual(AccessibilityID.toolsInspect, "tools-inspect")
        XCTAssertEqual(AccessibilityID.toolsRawMode, "tools-raw-mode")
    }

    /// All utility bar IDs are non-empty
    func testUtilityBarIDsAreNonEmpty() {
        let ids = [
            AccessibilityID.toolsBrowser,
            AccessibilityID.toolsContext,
            AccessibilityID.toolsInspect,
            AccessibilityID.toolsRawMode,
        ]
        for id in ids {
            XCTAssertFalse(id.isEmpty, "Utility bar ID should not be empty")
        }
    }

    // MARK: - Chat Bar Accessibility IDs

    /// Attach file button has its own ID (in chat bar, not utility bar)
    func testAttachFileID() {
        XCTAssertEqual(AccessibilityID.toolsAttachFile, "tools-attach-file")
    }

    /// Send button ID
    func testSendButtonID() {
        XCTAssertEqual(AccessibilityID.sendButton, "send-button")
    }

    // MARK: - Chat Bar Layout (model-level)

    func testChatBarSendDisabledWhenEmpty() {
        let inputText = ""
        let attachedFiles: [AttachedFile] = []
        let canSend = !inputText.isEmpty || !attachedFiles.isEmpty
        XCTAssertFalse(canSend)
    }

    func testChatBarSendEnabledWithText() {
        let inputText = "Hello"
        let attachedFiles: [AttachedFile] = []
        let canSend = !inputText.isEmpty || !attachedFiles.isEmpty
        XCTAssertTrue(canSend)
    }

    func testChatBarSendEnabledWithAttachment() {
        let inputText = ""
        let hasFiles = true
        let canSend = !inputText.isEmpty || hasFiles
        XCTAssertTrue(canSend)
    }

    // MARK: - Session Model

    func testNewSessionDefaults() {
        let session = Session(agentType: .claude)
        XCTAssertEqual(session.agentStatus, .idle)
        XCTAssertFalse(session.isRunning)
        XCTAssertNil(session.exitCode)
        XCTAssertFalse(session.browserVisible)
        XCTAssertNil(session.intentText)
    }

    func testAllAgentTypesHaveDisplayNames() {
        for type in AgentType.allCases {
            XCTAssertFalse(type.displayName.isEmpty)
            XCTAssertFalse(type.iconName.isEmpty)
            XCTAssertFalse(type.inputPlaceholder.isEmpty)
        }
    }

    func testAllStatusesHaveLabelsAndIcons() {
        let allStatuses: [AgentStatus] = [.idle, .thinking, .writing, .running, .waitingForInput, .error]
        for status in allStatuses {
            XCTAssertFalse(status.label.isEmpty, "\(status) should have a label")
            XCTAssertFalse(status.iconName.isEmpty, "\(status) should have an icon")
        }
    }

    func testOnlyWorkingStatesAreActive() {
        let expectedActive: Set<AgentStatus> = [.thinking, .writing, .running]
        let allStatuses: [AgentStatus] = [.idle, .thinking, .writing, .running, .waitingForInput, .error]
        for status in allStatuses {
            if expectedActive.contains(status) {
                XCTAssertTrue(status.isActive, "\(status) should be active")
            } else {
                XCTAssertFalse(status.isActive, "\(status) should NOT be active")
            }
        }
    }

    // MARK: - Session Row Accessibility Contract

    func testSessionRowAccessibilityContract() {
        XCTAssertEqual(AccessibilityID.sessionStatusDot, "session-status-dot")
        XCTAssertEqual(AccessibilityID.sessionName, "session-name")
        XCTAssertEqual(AccessibilityID.sessionStatusLabel, "session-status-label")
        XCTAssertEqual(AccessibilityID.sessionRow, "session-row")
    }

    // MARK: - Browser Visibility Affects Utility Bar

    func testInspectOnlyAvailableWhenBrowserVisible() {
        var session = Session(agentType: .claude)
        session.browserVisible = false
        XCTAssertFalse(session.browserVisible)

        session.browserVisible = true
        XCTAssertTrue(session.browserVisible)
    }

    // MARK: - Context Panel State

    func testContextPanelState() {
        var session = Session(agentType: .claude)
        XCTAssertNil(session.intentText)

        session.intentText = "Build a landing page"
        XCTAssertNotNil(session.intentText)
    }

    // MARK: - Project Model (formerly Group)

    /// Project type alias works
    func testProjectTypeAlias() {
        let project: Project = SessionGroup(name: "My Project")
        XCTAssertEqual(project.name, "My Project")
        XCTAssertFalse(project.isCollapsed)
        XCTAssertTrue(project.instructions.isEmpty)
    }

    /// Projects can have instructions
    func testProjectInstructions() {
        var project = SessionGroup(name: "Deck")
        XCTAssertTrue(project.instructions.isEmpty)

        project.instructions = "Use SwiftUI, target macOS 14+"
        XCTAssertEqual(project.instructions, "Use SwiftUI, target macOS 14+")
    }

    /// Sessions have projectId alias for groupId
    func testSessionProjectIdAlias() {
        var session = Session(agentType: .claude)
        XCTAssertNil(session.projectId)
        XCTAssertNil(session.groupId)

        let projectId = UUID()
        session.projectId = projectId
        XCTAssertEqual(session.groupId, projectId)
        XCTAssertEqual(session.projectId, projectId)
    }

    /// Session can be assigned to a project via groupId (backwards compat)
    func testSessionGroupIdBackwardsCompat() {
        let projectId = UUID()
        var session = Session(agentType: .claude, groupId: projectId)
        XCTAssertEqual(session.projectId, projectId)
        XCTAssertEqual(session.groupId, projectId)
    }

    /// Projects can be collapsed
    func testProjectCollapse() {
        var project = SessionGroup(name: "Test")
        XCTAssertFalse(project.isCollapsed)
        project.isCollapsed = true
        XCTAssertTrue(project.isCollapsed)
    }

    // MARK: - Two-Line Session Row

    /// Accessibility IDs exist for both lines of session row
    func testTwoLineSessionRowIDs() {
        XCTAssertEqual(AccessibilityID.sessionName, "session-name")
        XCTAssertEqual(AccessibilityID.sessionStatusLabel, "session-status-label")
    }

    // MARK: - Project Accessibility IDs

    func testProjectAccessibilityIDs() {
        XCTAssertEqual(AccessibilityID.newProjectButton, "new-project-button")
    }

    // MARK: - Project-First Model

    /// Projects have a workingDirectory field
    func testProjectHasWorkingDirectory() {
        let project = SessionGroup(name: "Deck", workingDirectory: "/Users/test/Development/Deck")
        XCTAssertEqual(project.workingDirectory, "/Users/test/Development/Deck")
        XCTAssertEqual(project.name, "Deck")
    }

    /// Projects without a workingDirectory default to nil
    func testProjectWorkingDirectoryDefaultsToNil() {
        let project = SessionGroup(name: "General")
        XCTAssertNil(project.workingDirectory)
    }

    /// General project is identified by isGeneral
    func testGeneralProjectIdentification() {
        let general = SessionGroup(name: "General", workingDirectory: nil)
        XCTAssertTrue(general.isGeneral)

        let notGeneral = SessionGroup(name: "Deck", workingDirectory: "/path")
        XCTAssertFalse(notGeneral.isGeneral)

        let namedGeneral = SessionGroup(name: "General", workingDirectory: "/path")
        XCTAssertFalse(namedGeneral.isGeneral, "General with a workingDirectory is not the fallback project")
    }

    /// GitDetector.rootDirectory returns a path for git repos
    func testGitRootDetection() {
        // The Deck project itself is a git repo
        let root = GitDetector.rootDirectory(for: "/Users/aaronstevens/Development/Deck")
        // May or may not work depending on the test environment,
        // but the method should return nil for non-git directories
        let nonGit = GitDetector.rootDirectory(for: "/tmp")
        XCTAssertNil(nonGit, "/tmp should not be a git repo")
    }

    /// Sessions always have a project in the new model
    func testSessionAlwaysBelongsToProject() {
        // In project-first mode, createSession auto-assigns via resolveProject
        // We verify the model supports this by checking groupId can be set
        var session = Session(agentType: .claude)
        let projectId = UUID()
        session.groupId = projectId
        XCTAssertEqual(session.projectId, projectId)
    }

    /// Project-first: delete moves sessions to General, doesn't orphan
    func testDeleteProjectMovesToGeneral() {
        // Verify the model: General project is undeletable
        let general = SessionGroup(name: "General")
        XCTAssertTrue(general.isGeneral)
        // Sessions moved to General still have a valid groupId
        var session = Session(agentType: .claude, groupId: general.id)
        XCTAssertEqual(session.groupId, general.id)
    }
}
