import SwiftUI
import SwiftTerm
import AppKit

@MainActor
final class TerminalController: ObservableObject {
    private weak var terminalView: LocalProcessTerminalView?
    private var savedCaretColor: NSColor?

    func setTerminalView(_ view: LocalProcessTerminalView) {
        self.terminalView = view
    }

    func send(_ text: String) {
        guard let tv = terminalView else {
            NSLog("[DECK] send failed — terminalView is nil")
            return
        }
        tv.send(txt: text)
    }

    func focusTerminal() {
        terminalView?.window?.makeFirstResponder(terminalView)
    }

    func unfocusTerminal() {
        if let window = terminalView?.window, window.firstResponder === terminalView {
            window.makeFirstResponder(nil)
        }
    }

    /// The most recent terminal title set by the shell/agent via OSC escape sequence.
    /// Claude Code uses this to broadcast status like "Thinking...", "Reading file.swift", etc.
    var lastTerminalTitle: String = ""

    /// Save the full visible terminal buffer to a file for session persistence.
    func saveScrollback(to path: String) {
        let content = readFullVisibleBuffer()
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        try? content.write(toFile: path, atomically: true, encoding: .utf8)
    }

    /// Read the terminal title + last visible lines for status parsing.
    /// Uses both the OSC title (most reliable for Claude Code) and buffer text as fallback.
    func readRecentOutput() -> String {
        guard let tv = terminalView else { return "" }
        let terminal = tv.getTerminal()

        // Primary: OSC title (Claude Code updates this with status)
        var combined = lastTerminalTitle

        // Fallback: read visible buffer lines (last 8 rows)
        let rows = terminal.rows
        let cols = terminal.cols
        let startRow = max(0, rows - 8)
        combined += "\n" + scanRows(terminal: terminal, from: startRow, to: rows, cols: cols)

        return combined
    }

    /// Read the full visible buffer for URL detection (scans all visible rows).
    func readFullVisibleBuffer() -> String {
        guard let tv = terminalView else { return "" }
        let terminal = tv.getTerminal()
        return scanRows(terminal: terminal, from: 0, to: terminal.rows, cols: terminal.cols)
    }

    /// Efficiently scan terminal rows into a string, preallocating capacity.
    private func scanRows(terminal: Terminal, from startRow: Int, to endRow: Int, cols: Int) -> String {
        let rowCount = endRow - startRow
        // Preallocate: ~cols characters per row + newlines
        var result = String()
        result.reserveCapacity(rowCount * (cols + 1))

        // Preallocate a line buffer to reuse across rows
        var lineChars = [Character]()
        lineChars.reserveCapacity(cols)

        for row in startRow..<endRow {
            lineChars.removeAll(keepingCapacity: true)
            for col in 0..<cols {
                let pos = Position(col: col, row: row)
                let ch = terminal.buffer.getChar(at: pos)
                lineChars.append(ch.getCharacter())
            }
            // Trim trailing whitespace efficiently
            while let last = lineChars.last, last == " " || last == "\0" {
                lineChars.removeLast()
            }
            if !lineChars.isEmpty {
                if !result.isEmpty { result.append("\n") }
                result.append(contentsOf: lineChars)
            }
        }

        return result
    }

    /// Hide the terminal cursor (chat mode) — makes it clear you're typing in the chat box
    func hideCursor() {
        guard let tv = terminalView else { return }
        if savedCaretColor == nil {
            savedCaretColor = tv.caretColor
        }
        tv.caretColor = .clear
        // Also hide the CaretView subview directly.
        // String-based type checking is used because SwiftTerm's CaretView/MacCaretView
        // are internal types not exposed in the public API. The class names are stable
        // across SwiftTerm versions. Using String(describing:) avoids obj-c bridging overhead.
        for subview in tv.subviews {
            if String(describing: type(of: subview)).contains("Caret") {
                subview.isHidden = true
            }
        }
    }

    /// Show the terminal cursor (raw mode)
    func showCursor(themeColor: NSColor) {
        guard let tv = terminalView else { return }
        tv.caretColor = savedCaretColor ?? themeColor
        savedCaretColor = nil
        // Show the CaretView subview (see hideCursor for why string-based checking is used)
        for subview in tv.subviews {
            if String(describing: type(of: subview)).contains("Caret") {
                subview.isHidden = false
            }
        }
    }
}

struct TerminalBridge: NSViewRepresentable {
    let sessionId: UUID
    let agentType: AgentType
    let workingDirectory: String
    let theme: Theme

    /// Resolve the terminal font: theme font → user setting → auto-detect
    static func resolveFont(themeFont: String? = nil) -> NSFont {
        let userFamily = UserDefaults.standard.string(forKey: "terminalFontFamily") ?? "auto"
        let rawSize = UserDefaults.standard.double(forKey: "terminalFontSize")
        let size = CGFloat(rawSize > 0 ? min(max(rawSize, 10), 24) : 13)

        // 1. User override (explicit selection in Settings)
        if userFamily != "auto", let font = NSFont(name: userFamily, size: size) {
            return font
        }

        // 2. Theme-specified font
        if let themeFont, !themeFont.isEmpty, let font = NSFont(name: themeFont, size: size) {
            return font
        }

        // 3. Auto: try bundled fonts — prefer Light weight for thinner, refined look
        let font = NSFont(name: "JetBrainsMono-Light", size: size)
            ?? NSFont(name: "FiraCode-Light", size: size)
            ?? NSFont(name: "JetBrainsMono-Regular", size: size)
            ?? NSFont(name: "FiraCode-Regular", size: size)
            ?? NSFont(name: "Menlo", size: size)
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: .light)
        try? "Font: \(font.fontName) at \(font.pointSize)pt\n".write(toFile: "/tmp/deck-font-debug.txt", atomically: true, encoding: .utf8)
        return font
    }
    let controller: TerminalController
    let isChatMode: Bool
    var continueSession: Bool = false
    var scrollbackPath: String? = nil

    @Binding var terminalTitle: String
    @Binding var agentStatus: AgentStatus
    @Binding var isRunning: Bool
    @Binding var exitCode: Int?

    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        var parent: TerminalBridge
        var hasStarted = false
        init(_ parent: TerminalBridge) { self.parent = parent }
        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
            DispatchQueue.main.async {
                self.parent.terminalTitle = title
                // Store on controller for status polling to read
                self.parent.controller.lastTerminalTitle = title
            }
        }
        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
        func processTerminated(source: TerminalView, exitCode: Int32?) {
            DispatchQueue.main.async {
                self.parent.isRunning = false
                self.parent.exitCode = exitCode.map { Int($0) }
                self.parent.agentStatus = .idle
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let tv = LocalProcessTerminalView(frame: .zero)
        tv.processDelegate = context.coordinator
        applyTheme(to: tv)
        tv.font = Self.resolveFont(themeFont: theme.terminal.fontFamily)
        controller.setTerminalView(tv)
        startProcess(tv: tv, context: context)

        // Apply initial cursor state
        if isChatMode {
            controller.hideCursor()
        }

        return tv
    }

    func updateNSView(_ tv: LocalProcessTerminalView, context: Context) {
        applyTheme(to: tv)
        context.coordinator.parent = self
        controller.setTerminalView(tv)

        // Update cursor visibility based on chat/raw mode
        if isChatMode {
            controller.hideCursor()
        } else {
            controller.showCursor(themeColor: theme.terminal.cursor.nsColor)
        }
    }

    private func startProcess(tv: LocalProcessTerminalView, context: Context) {
        guard !context.coordinator.hasStarted else { return }
        context.coordinator.hasStarted = true
        let cmd = agentType.command
        let args = agentType.arguments(continueSession: continueSession)

        // Inherit process env, override BROWSER, and prepend ~/.deck/bin to PATH
        // so Deck's `open` wrapper intercepts URL opens from agents
        var envDict = ProcessInfo.processInfo.environment
        envDict["BROWSER"] = SessionManager.browserScriptPath
        let existingPath = envDict["PATH"] ?? "/usr/bin:/bin"
        envDict["PATH"] = SessionManager.deckBinDir + ":" + existingPath
        let env = envDict.map { "\($0.key)=\($0.value)" }

        tv.startProcess(executable: cmd, args: args, environment: env,
                        execName: URL(fileURLWithPath: cmd).lastPathComponent)
        DispatchQueue.main.async { self.isRunning = true; self.agentStatus = .idle }

        // Clean up saved scrollback file (scrollback restore via feed() produces
        // garbled output because the raw buffer contains escape sequences that don't
        // re-render correctly. For Claude Code, --continue resumes the conversation
        // which is more valuable than raw scrollback.)
        if let scrollbackPath = scrollbackPath {
            try? FileManager.default.removeItem(atPath: scrollbackPath)
        }
    }

    private func applyTheme(to tv: LocalProcessTerminalView) {
        let tc = theme.terminal
        tv.nativeBackgroundColor = tc.background.nsColor
        tv.nativeForegroundColor = tc.foreground.nsColor
        // Don't override caretColor here if we're managing it for chat/raw mode
        tv.selectedTextBackgroundColor = tc.selection.nsColor
        let a = tc.ansi
        tv.installColors([
            stc(a.black), stc(a.red), stc(a.green), stc(a.yellow),
            stc(a.blue), stc(a.magenta), stc(a.cyan), stc(a.white),
            stc(a.brightBlack), stc(a.brightRed), stc(a.brightGreen), stc(a.brightYellow),
            stc(a.brightBlue), stc(a.brightMagenta), stc(a.brightCyan), stc(a.brightWhite),
        ])
    }

    private func stc(_ c: ThemeColor) -> SwiftTerm.Color {
        SwiftTerm.Color(red: UInt16(c.red * 65535), green: UInt16(c.green * 65535), blue: UInt16(c.blue * 65535))
    }
}
