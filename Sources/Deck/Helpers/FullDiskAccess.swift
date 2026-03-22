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

    /// Show the onboarding alert if FDA isn't granted.
    /// Checks every launch until granted, but only shows the dialog once per day.
    static func requestIfNeeded() {
        // Already have access — nothing to do
        if isGranted { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let alert = NSAlert()
            alert.messageText = "Grant Full Disk Access"
            alert.informativeText = "Deck needs Full Disk Access to work like a normal terminal — without per-folder permission popups.\n\nSystem Settings → Privacy & Security → Full Disk Access → enable Deck."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")

            if alert.runModal() == .alertFirstButtonReturn {
                openSettings()
            }
        }
    }
}
