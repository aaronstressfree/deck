import SwiftUI
import AppKit

class DeckAppDelegate: NSObject, NSApplicationDelegate {
    var menuManager: AppMenuManager?
    var sessionManager: SessionManager?
    var designMode: DesignModeManager?
    var urlBarFocusHandler: (() -> Void)?
    var newSessionSheetHandler: (() -> Void)?
    private var menuTimer: Timer?

    func applicationWillTerminate(_ notification: Notification) {
        guard let sm = sessionManager else { return }
        let scrollbackDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Deck/Scrollback", isDirectory: true)
        try? FileManager.default.createDirectory(at: scrollbackDir, withIntermediateDirectories: true)

        for i in sm.sessions.indices {
            let session = sm.sessions[i]

            // Save scrollback
            let path = scrollbackDir.appendingPathComponent("\(session.id.uuidString).txt").path
            if let controller = sm.terminalControllers[session.id] {
                controller.saveScrollback(to: path)
                sm.sessions[i].scrollbackPath = path

                // Save conversation summary into intentText for Claude/Amp sessions.
                // DeckContext writes intentText to CLAUDE.md, so Claude reads it
                // as system context on startup — no messages sent, it just "knows."
                if session.agentType != .shell {
                    let buffer = controller.readFullVisibleBuffer()
                    let summary = DeckAppDelegate.extractConversationSummary(from: buffer)
                    if !summary.isEmpty {
                        // Prepend to existing intent text, don't overwrite
                        let existing = sm.sessions[i].intentText ?? ""
                        if existing.isEmpty {
                            sm.sessions[i].intentText = summary
                        } else if !existing.contains("Recent prompts:") {
                            sm.sessions[i].intentText = existing + "\n\n" + summary
                        }
                        // Also store separately for reference
                        sm.sessions[i].lastConversationSummary = summary
                    }
                }
            }
        }
        sm.saveStatePublic()
    }

    /// Extract a brief conversation summary from terminal buffer.
    /// Captures user prompts (lines starting with ❯ or >) and key output lines.
    static func extractConversationSummary(from buffer: String) -> String {
        let lines = buffer.components(separatedBy: "\n")
        var prompts: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // User prompts
            if trimmed.hasPrefix("❯ ") || trimmed.hasPrefix("> ") {
                let prompt = trimmed
                    .replacingOccurrences(of: "^[❯>]\\s+", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                if !prompt.isEmpty && prompt.count > 2 {
                    prompts.append(prompt)
                }
            }
        }

        // Keep last 3 prompts as context
        let recent = prompts.suffix(3)
        guard !recent.isEmpty else { return "" }

        return "Recent prompts from previous session:\n" +
            recent.map { "- \($0)" }.joined(separator: "\n") +
            "\nPick up where we left off if relevant."
    }

    /// Find the most recent Claude Code session ID for a given working directory.
    private func findClaudeSessionId(for workingDirectory: String) -> String? {
        let sessionsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/sessions")
        guard let files = try? FileManager.default.contentsOfDirectory(at: sessionsDir, includingPropertiesForKeys: [.contentModificationDateKey]) else { return nil }

        // Find the most recently modified session file matching this cwd
        var bestMatch: (id: String, date: Date)?
        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let cwd = json["cwd"] as? String,
                  let sessionId = json["sessionId"] as? String else { continue }

            if cwd == workingDirectory {
                let date = (try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                if bestMatch == nil || date > bestMatch!.date {
                    bestMatch = (sessionId, date)
                }
            }
        }
        return bestMatch?.id
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register bundled fonts before any terminal views are created
        registerBundledFonts()

        // Set terminal color env vars in launchd so future Dock launches
        // inherit them. Claude Code checks COLORTERM at startup to decide
        // whether to output true color (24-bit RGB) for its orange logo.
        // Without this, Dock launches get a minimal env and Claude outputs gray.
        let setenv = { (key: String, value: String) in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            task.arguments = ["setenv", key, value]
            task.standardOutput = FileHandle.nullDevice
            task.standardError = FileHandle.nullDevice
            try? task.run()
        }
        setenv("COLORTERM", "truecolor")
        setenv("TERM", "xterm-256color")

        NSLog("[DECK] App launched, fonts registered, launchd env set")
        try? "launch: \(Date())\n".write(toFile: "/tmp/deck-debug.log", atomically: true, encoding: .utf8)
        // Poll until state objects are available (set by DeckApp body evaluation)
        menuTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            if self.menuManager != nil { timer.invalidate(); return }
            guard let sm = self.sessionManager, let dm = self.designMode else {
                NSLog("[DECK] Waiting for state objects...")
                return
            }
            timer.invalidate()
            self.menuTimer = nil
            self.menuManager = AppMenuManager(
                sessionManager: sm,
                urlBarFocusHandler: { [weak self] in self?.urlBarFocusHandler?() },
                newSessionSheetHandler: { [weak self] in self?.newSessionSheetHandler?() },
                toggleRawModeHandler: {
                    if let id = sm.activeSessionId {
                        sm.toggleChatMode(for: id)
                    }
                },
                toggleDesignModeHandler: { [weak dm] in dm?.toggleInspect() }
            )
            NSLog("[DECK] Menu manager installed via timer")
        }
    }
}

/// Register all bundled fonts so they're available even if not installed system-wide
private func registerBundledFonts() {
    // SPM executable targets put resources in Deck_Deck.bundle inside the app's Resources
    let candidates = [
        Bundle.main.url(forResource: "Fonts", withExtension: nil),
        Bundle.main.resourceURL?.appendingPathComponent("Deck_Deck.bundle/Fonts"),
        Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/Deck_Deck.bundle/Fonts"),
    ]

    guard let fontsURL = candidates.compactMap({ $0 }).first(where: {
        FileManager.default.fileExists(atPath: $0.path)
    }) else { return }

    guard let fontFiles = try? FileManager.default.contentsOfDirectory(at: fontsURL, includingPropertiesForKeys: nil) else { return }

    for file in fontFiles where file.pathExtension == "ttf" || file.pathExtension == "otf" {
        CTFontManagerRegisterFontsForURL(file as CFURL, .process, nil)
    }
}

@main
struct DeckApp: App {
    @NSApplicationDelegateAdaptor(DeckAppDelegate.self) var appDelegate
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var sessionManager = SessionManager()
    @StateObject private var designMode = DesignModeManager()
    @StateObject private var updateChecker = UpdateChecker()
    @State private var showNewSessionSheet = false
    @State private var urlBarFocused = false

    init() {
        registerBundledFonts()
    }

    var body: some Scene {
        // Set delegate references on every body evaluation
        let _ = {
            if appDelegate.sessionManager == nil {
                appDelegate.sessionManager = sessionManager
                appDelegate.designMode = designMode
                appDelegate.urlBarFocusHandler = { urlBarFocused = true }
                appDelegate.newSessionSheetHandler = { showNewSessionSheet = true }
                try? "body set refs: \(Date())\n".write(toFile: "/tmp/deck-debug-body.log", atomically: true, encoding: .utf8)
            }
        }()

        WindowGroup {
            ContentView(appDelegate: appDelegate, sessionManager: sessionManager, urlBarFocused: $urlBarFocused, showNewSessionSheet: $showNewSessionSheet)
                .environment(\.deckTheme, themeManager.activeTheme)
                .environment(\.colorScheme, themeManager.activeTheme.metadata.colorScheme == .dark ? .dark : .light)
                .preferredColorScheme(themeManager.activeTheme.metadata.colorScheme == .dark ? .dark : .light)
                .environmentObject(themeManager)
                .environmentObject(designMode)
                .environmentObject(sessionManager)
                .environmentObject(updateChecker)
                .onAppear { FullDiskAccess.requestIfNeeded() }
                .onOpenURL { url in themeManager.handleShareURL(url) }
                .sheet(isPresented: $showNewSessionSheet) {
                    NewSessionSheet(
                        onCreate: { agentType, cwd, groupId, name in
                            sessionManager.createSession(agentType: agentType, workingDirectory: cwd, groupId: groupId, name: name)
                        },
                        groups: sessionManager.groups,
                        activeProjectId: sessionManager.activeProject?.id
                    )
                }
                .sheet(item: $themeManager.pendingShareImport) { theme in
                    ThemeImportSheet(
                        theme: theme,
                        onImport: {
                            if let imported = themeManager.confirmShareImport() {
                                themeManager.setActiveTheme(imported)
                            }
                        },
                        onCancel: { themeManager.cancelShareImport() }
                    )
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)

        Settings {
            SettingsView(sessionManager: sessionManager)
                .environmentObject(themeManager)
                .environment(\.colorScheme, themeManager.activeTheme.metadata.colorScheme == .dark ? .dark : .light)
        }
    }
}
