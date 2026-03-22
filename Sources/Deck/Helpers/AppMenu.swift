import AppKit
import SwiftUI

/// Installs Deck keyboard shortcuts into the macOS main menu bar.
/// Cut/Copy/Paste are handled entirely by the system Edit menu + responder chain.
/// No custom interception — whatever view has focus gets the clipboard actions.
final class AppMenuManager: NSObject {
    private weak var sessionManager: SessionManager?
    private var urlBarFocusHandler: (() -> Void)?
    private var newSessionSheetHandler: (() -> Void)?
    private var toggleRawModeHandler: (() -> Void)?
    private var toggleDesignModeHandler: (() -> Void)?

    init(sessionManager: SessionManager, urlBarFocusHandler: @escaping () -> Void, newSessionSheetHandler: @escaping () -> Void, toggleRawModeHandler: @escaping () -> Void = {}, toggleDesignModeHandler: @escaping () -> Void = {}) {
        self.sessionManager = sessionManager
        self.urlBarFocusHandler = urlBarFocusHandler
        self.newSessionSheetHandler = newSessionSheetHandler
        self.toggleRawModeHandler = toggleRawModeHandler
        self.toggleDesignModeHandler = toggleDesignModeHandler
        super.init()
        // Install menus and keep reinstalling until they stick.
        // SwiftUI aggressively overwrites the menu bar on early run loop cycles.
        installMenu()
        var attempts = 0
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] timer in
            attempts += 1
            guard let self else { timer.invalidate(); return }

            // Check if our menus are still there
            let titles = NSApplication.shared.mainMenu?.items.map(\.title) ?? []
            if !titles.contains("File") || !titles.contains("Edit") || !titles.contains("Session") {
                self.installMenu()
            }

            // Stop after 10 seconds — menus should be stable by then
            if attempts > 33 { timer.invalidate() }
        }
    }

    private func installMenu() {
        guard let mainMenu = NSApplication.shared.mainMenu else { return }

        // --- File menu ---
        let fileMenu = NSMenu(title: "File")
        let fileItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        fileItem.submenu = fileMenu

        fileMenu.addItem(mi("New Shell", #selector(newShell), "n"))
        fileMenu.addItem(mi("New Claude Code", #selector(newClaude), "c", [.command, .shift]))
        fileMenu.addItem(mi("New Amp", #selector(newAmp), "a", [.command, .shift]))
        fileMenu.addItem(mi("New Session...", #selector(newSessionSheet), "n", [.command, .shift]))
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(mi("Close Session", #selector(closeSession), "w"))

        // --- View menu ---
        let viewMenu = NSMenu(title: "View")
        let viewItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        viewItem.submenu = viewMenu

        viewMenu.addItem(mi("Toggle Sidebar", #selector(toggleSidebar), "l", [.command, .shift]))
        viewMenu.addItem(mi("Toggle Browser", #selector(toggleBrowser), "b"))
        viewMenu.addItem(mi("Focus URL Bar", #selector(focusUrlBar), "l"))
        viewMenu.addItem(mi("Toggle Design Mode", #selector(toggleDesignMode), "d"))
        viewMenu.addItem(mi("Toggle Raw/Chat Mode", #selector(toggleRawMode), "e", [.command, .shift]))
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(mi("Previous Session", #selector(prevSession), "["))
        viewMenu.addItem(mi("Next Session", #selector(nextSession), "]"))

        // --- Session menu ---
        let sessionMenu = NSMenu(title: "Session")
        let sessionItem = NSMenuItem(title: "Session", action: nil, keyEquivalent: "")
        sessionItem.submenu = sessionMenu

        sessionMenu.addItem(mi("Create Checkpoint", #selector(createCheckpoint), "s", [.command, .shift]))

        sessionMenu.addItem(NSMenuItem.separator())
        for i in 1...9 {
            let item = NSMenuItem(title: "Session \(i)", action: #selector(switchN(_:)), keyEquivalent: "\(i)")
            item.tag = i; item.target = self
            sessionMenu.addItem(item)
        }

        // Build the full menu bar from scratch — SwiftUI fights with insertions
        let appMenuItem = mainMenu.items.first  // Keep the app menu (Deck)
        mainMenu.removeAllItems()
        if let appMenuItem = appMenuItem {
            mainMenu.addItem(appMenuItem)
        }
        mainMenu.addItem(fileItem)

        // Re-add the Edit menu (system-provided or our fallback)
        if let existingEdit = mainMenu.items.first(where: { $0.title == "Edit" }) {
            // Already there from the block above
            _ = existingEdit
        } else {
            // Add standard Edit menu
            let editMenu = NSMenu(title: "Edit")
            let editItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
            editItem.submenu = editMenu
            editMenu.addItem(NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
            editMenu.addItem(NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z"))
            editMenu.addItem(NSMenuItem.separator())
            editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
            editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
            editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
            editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
            mainMenu.addItem(editItem)
        }

        mainMenu.addItem(viewItem)
        mainMenu.addItem(sessionItem)

        // Re-add Window and Help menus
        let windowMenu = NSMenu(title: "Window")
        let windowItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        windowItem.submenu = windowMenu
        windowMenu.addItem(NSMenuItem(title: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m"))
        windowMenu.addItem(NSMenuItem(title: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: ""))
        mainMenu.addItem(windowItem)
        NSApp.windowsMenu = windowMenu

        let helpMenu = NSMenu(title: "Help")
        let helpItem = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")
        helpItem.submenu = helpMenu
        mainMenu.addItem(helpItem)
        NSApp.helpMenu = helpMenu

        NSLog("[DECK] Menu bar rebuilt: \(mainMenu.items.map(\.title))")
    }

    private func mi(_ title: String, _ action: Selector, _ key: String, _ mods: NSEvent.ModifierFlags = .command) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.keyEquivalentModifierMask = mods
        item.target = self
        return item
    }

    // MARK: - Actions (all run on main thread via menu dispatch)

    @objc private func newShell() { onMain { self.sessionManager?.createSession(agentType: .shell) } }
    @objc private func newClaude() { onMain { self.sessionManager?.createSession(agentType: .claude) } }
    @objc private func newAmp() { onMain { self.sessionManager?.createSession(agentType: .amp) } }
    @objc private func newSessionSheet() { onMain { self.newSessionSheetHandler?() } }
    @objc private func toggleRawMode() { onMain { self.toggleRawModeHandler?() } }
    @objc private func toggleDesignMode() { onMain { self.toggleDesignModeHandler?() } }

    @objc private func closeSession() {
        onMain {
            guard let sm = self.sessionManager,
                  let id = sm.activeSessionId,
                  let session = sm.sessions.first(where: { $0.id == id }) else { return }

            let alert = NSAlert()
            alert.messageText = "Close Session?"
            alert.informativeText = "Close \"\(session.displayName)\"? This will end the running process."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Close")
            alert.addButton(withTitle: "Cancel")
            if alert.runModal() == .alertFirstButtonReturn {
                sm.closeSession(id: id)
            }
        }
    }

    @objc private func toggleSidebar() {
        onMain { withAnimation(.easeOut(duration: 0.2)) { self.sessionManager?.sidebarCollapsed.toggle() } }
    }

    @objc private func toggleBrowser() {
        onMain {
            guard let sm = self.sessionManager,
                  let i = sm.sessions.firstIndex(where: { $0.id == sm.activeSessionId }) else { return }
            sm.sessions[i].browserVisible.toggle()
        }
    }

    @objc private func focusUrlBar() {
        onMain {
            if let sm = self.sessionManager,
               let i = sm.sessions.firstIndex(where: { $0.id == sm.activeSessionId }),
               !sm.sessions[i].browserVisible {
                sm.sessions[i].browserVisible = true
            }
            // Longer delay to ensure browser pane is rendered before focusing URL bar
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.urlBarFocusHandler?() }
        }
    }

    @objc private func createCheckpoint() {
        onMain {
            guard let sm = self.sessionManager,
                  let i = sm.sessions.firstIndex(where: { $0.id == sm.activeSessionId }) else { return }
            sm.sessions[i].checkpoints.append(Checkpoint(name: "Checkpoint \(sm.sessions[i].checkpoints.count + 1)"))
        }
    }

    @objc private func prevSession() {
        onMain {
            guard let sm = self.sessionManager, let activeId = sm.activeSessionId,
                  let idx = sm.sessions.firstIndex(where: { $0.id == activeId }), idx > 0 else { return }
            sm.switchToSession(id: sm.sessions[idx - 1].id)
        }
    }

    @objc private func nextSession() {
        onMain {
            guard let sm = self.sessionManager, let activeId = sm.activeSessionId,
                  let idx = sm.sessions.firstIndex(where: { $0.id == activeId }), idx < sm.sessions.count - 1 else { return }
            sm.switchToSession(id: sm.sessions[idx + 1].id)
        }
    }

    @objc private func switchN(_ sender: NSMenuItem) {
        let n = sender.tag
        onMain {
            guard let sm = self.sessionManager else { return }
            if n >= 1 && n <= sm.sessions.count { sm.switchToSession(id: sm.sessions[n - 1].id) }
        }
    }

    private func onMain(_ block: @escaping @MainActor () -> Void) {
        DispatchQueue.main.async { MainActor.assumeIsolated { block() } }
    }
}
