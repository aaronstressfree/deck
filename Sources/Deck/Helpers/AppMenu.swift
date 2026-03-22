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
        installMenu()
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

        // --- Edit menu ---
        // Don't replace the system Edit menu — SwiftUI provides a default one with
        // Cut/Copy/Paste/Undo/Redo that works correctly through the responder chain.
        // If no system Edit menu exists, create one.
        if !mainMenu.items.contains(where: { $0.title == "Edit" }) {
            let editMenu = NSMenu(title: "Edit")
            let editItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
            editItem.submenu = editMenu
            editMenu.addItem(NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
            editMenu.addItem(NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z"))
            editMenu.addItem(NSMenuItem.separator())
            editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
            editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
            editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
            editMenu.addItem(NSMenuItem(title: "Delete", action: #selector(NSText.delete(_:)), keyEquivalent: ""))
            editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
            let pos = min(mainMenu.items.count, 1)
            mainMenu.insertItem(editItem, at: pos)
        }

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

        // Insert custom menus into the existing menu bar
        // Use insertItem to avoid fighting with SwiftUI's menu management
        func insert(_ item: NSMenuItem, afterTitle: String) {
            // Replace existing menu with same title, or insert after the target
            if let i = mainMenu.items.firstIndex(where: { $0.title == item.title }) {
                mainMenu.removeItem(at: i)
                mainMenu.insertItem(item, at: i)
            } else if let i = mainMenu.items.firstIndex(where: { $0.title == afterTitle }) {
                mainMenu.insertItem(item, at: i + 1)
            } else {
                // Fallback: insert at position 1 (after app menu)
                let pos = min(mainMenu.items.count, 1)
                mainMenu.insertItem(item, at: pos)
            }
        }

        let appMenuTitle = mainMenu.items.first?.title ?? ""
        insert(fileItem, afterTitle: appMenuTitle)
        insert(viewItem, afterTitle: "Edit")
        insert(sessionItem, afterTitle: "View")

        NSLog("[DECK] Menus inserted, total: \(mainMenu.items.count), titles: \(mainMenu.items.map(\.title))")
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
