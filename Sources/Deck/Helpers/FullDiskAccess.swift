import AppKit
import SwiftUI

/// Checks and requests Full Disk Access so Deck never shows per-folder permission dialogs.
enum FullDiskAccess {
    /// Check if we likely have Full Disk Access by trying to read a TCC-protected path.
    static var isGranted: Bool {
        // Try to access ~/Library/Safari — this is TCC-protected and only accessible with FDA
        let testPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Safari/Bookmarks.plist").path
        return FileManager.default.isReadableFile(atPath: testPath)
    }

    /// Open System Settings to the Full Disk Access pane.
    static func openSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Show the onboarding alert once.
    static func requestIfNeeded() {
        let key = "hasRequestedFullDiskAccess"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        // Only show if we don't already have it
        if isGranted { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let alert = NSAlert()
            alert.messageText = "Grant Full Disk Access"
            alert.informativeText = "Deck is a terminal emulator that needs access to your entire filesystem — just like Terminal.app or iTerm2.\n\nGrant Full Disk Access once in System Settings so you never see per-folder permission dialogs again."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")

            if alert.runModal() == .alertFirstButtonReturn {
                openSettings()
            }
        }
    }
}
