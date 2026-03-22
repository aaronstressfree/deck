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
        // Save terminal scrollback for each session so it can be restored on relaunch
        guard let sm = sessionManager else { return }
        let scrollbackDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Deck/Scrollback", isDirectory: true)
        try? FileManager.default.createDirectory(at: scrollbackDir, withIntermediateDirectories: true)

        for i in sm.sessions.indices {
            let session = sm.sessions[i]
            let path = scrollbackDir.appendingPathComponent("\(session.id.uuidString).txt").path
            if let controller = sm.terminalControllers[session.id] {
                controller.saveScrollback(to: path)
                sm.sessions[i].scrollbackPath = path
            }
        }
        // Save state one final time with scrollback paths
        sm.saveStatePublic()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register bundled fonts before any terminal views are created
        registerBundledFonts()
        NSLog("[DECK] App launched, fonts registered, starting menu install timer")
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
