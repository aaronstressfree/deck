# Deck

**An AI-powered terminal for designers.** Deck wraps Claude Code and Amp in a native Mac app with a built-in browser preview, design inspector, and session management.

## Install

```
curl -sL https://raw.githubusercontent.com/aaronstressfree/deck/main/scripts/install.sh | bash
```

That's it. Deck is now in your Applications folder. Run the same command anytime to update to the latest version.

To launch: **open Deck from your Applications folder**, or run `open -a Deck` in terminal.

## What it does

Deck replaces the raw terminal experience when working with AI coding agents. Instead of staring at a scrolling terminal, you get:

- **Chat input** — Type prompts in a real text box. Press Enter to send. Shift+Enter for new lines.
- **Browser preview** — See your localhost app side-by-side with the terminal. No switching windows.
- **Design inspector** — Click elements in the browser preview to inspect and tweak their styles. Changes preview live.
- **Sessions** — Each Claude/Amp/shell session is a tab. Name them, group them, switch between them.
- **Themes** — 10+ built-in themes. Fully customizable. Share themes with coworkers via URL.

## Getting started

### First time setup

1. Install Deck using the command above
2. Open Deck
3. If prompted, grant **Full Disk Access** in System Settings (Privacy & Security → Full Disk Access → add Deck). This avoids per-folder permission popups.
4. Click **Claude Code**, **Amp**, or **Shell** to start your first session

### Prerequisites

- **macOS 14** (Sonoma) or later
- **Claude Code CLI** — install from [claude.ai/download](https://claude.ai/download) (for Claude sessions)
- **Amp CLI** — install from [amp.dev](https://amp.dev) (for Amp sessions)

Neither is required — you can use Deck as a regular terminal too.

## How to use it

### The basics

| What you want to do | How |
|---------------------|-----|
| Start a new Claude session | Click **+ New** in the sidebar, or press **Cmd+Shift+C** |
| Send a prompt | Type in the chat box at the bottom, press **Enter** |
| Open the browser preview | Press **Cmd+B**, then **Cmd+L** to type a URL |
| Switch between sessions | Click in the sidebar, or press **Cmd+1** through **Cmd+9** |
| Open settings | Click the gear icon in the sidebar, or press **Cmd+,** |

### Browser preview

The browser pane shows your localhost app right next to the terminal. When Claude or Amp starts a dev server, Deck automatically detects the URL and opens it.

You can also:
- **Switch device sizes** — Desktop, Tablet (768px), or Phone (375px) using the icons in the URL bar
- **Inspect elements** — Click the cursor icon in the URL bar (or press **Cmd+D**) to enter inspect mode. Hover to highlight elements, click to select. The Design panel opens with the element's current styles.

### Design inspector

When you select an element in the browser:
1. The design panel appears to the right showing the element's current CSS values
2. Adjust properties (colors, font size, spacing, borders, etc.) — changes show live in the browser
3. When you're happy, click **Send** to send the changes as instructions to your Claude/Amp session
4. Click **Reset** to undo all live changes and reload the page
5. Click **Copy** to copy the instructions to your clipboard instead

### Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| **Cmd+N** | New shell session |
| **Cmd+Shift+C** | New Claude Code session |
| **Cmd+Shift+A** | New Amp session |
| **Cmd+W** | Close session |
| **Cmd+1-9** | Switch to session 1-9 |
| **Cmd+B** | Toggle browser preview |
| **Cmd+L** | Focus browser URL bar |
| **Cmd+D** | Toggle design inspector |
| **Cmd+Shift+E** | Toggle chat/raw mode |
| **Cmd+,** | Settings |

### Chat mode vs Raw mode

By default, Deck is in **chat mode** — you type in a text box and press Enter to send. This is the best experience for Claude Code and Amp.

Switch to **raw mode** (Cmd+Shift+E) when you need to use interactive terminal programs like vim, htop, or ssh.

## Updating

Run the install command again:

```
curl -sL https://raw.githubusercontent.com/aaronstressfree/deck/main/scripts/install.sh | bash
```

It will quit the running app, download the latest build, and install it. Your sessions and settings are preserved.

## Building from source

If you want to build Deck yourself instead of using the install script:

```bash
git clone https://github.com/aaronstressfree/deck.git
cd deck
bash scripts/build-app.sh
open .build/Deck.app
```

Requires Swift 5.9+ (comes with Xcode Command Line Tools: `xcode-select --install`).

## Troubleshooting

**"Deck can't be opened because it is from an unidentified developer"**
Right-click Deck.app → Open → click Open in the dialog. You only need to do this once.

**Permissions dialogs keep appearing**
Grant Full Disk Access: System Settings → Privacy & Security → Full Disk Access → add Deck.

**Claude/Amp sessions show "command not found"**
Make sure the `claude` or `amp` CLI is installed and in your PATH. Try running `claude` or `amp` in a regular terminal first.

**Browser preview is blank**
Make sure your dev server is running. Press Cmd+L to focus the URL bar and type the URL (e.g., `localhost:3000`).

## Feedback

File issues at [github.com/aaronstressfree/deck/issues](https://github.com/aaronstressfree/deck/issues), or use **Settings → Feedback** inside the app to submit directly.

## Architecture

Deck is a native macOS app built with Swift and SwiftUI. No Electron, no web views for the UI — just the terminal and browser preview use web technologies.

### Tech stack

- **SwiftUI** — All UI views, sidebar, settings, design inspector
- **SwiftTerm** — Terminal emulator (PTY management, escape sequence parsing)
- **WKWebView** — Browser preview pane with JavaScript bridge for element inspection
- **Swift Package Manager** — Build system and dependency management

### How it works

```
┌──────────────────────────────────────────────────────┐
│ Deck.app                                              │
├──────────┬───────────────────────────────────────────┤
│ Sidebar  │  Terminal (SwiftTerm)  │  Browser (WKWeb) │
│          │                       │                   │
│ Projects │  TerminalBridge ←→ PTY │  WebViewBridge    │
│ Sessions │  AgentOutputParser     │  JS Inspect Mode  │
│          │  ChatInputView         │  Design Panel     │
├──────────┴───────────────────────┴───────────────────┤
│ StatusBar │ StatusPoller │ DeckContext │ SessionMgr    │
└──────────────────────────────────────────────────────┘
```

### Key concepts

| Concept | What it is |
|---------|------------|
| **Session** | A terminal process (PTY). Each session has its own agent (Claude/Amp/Shell), working directory, and browser tabs. |
| **Project** | A group of related sessions, mapped to a git repository root. Auto-created from working directories. Shares instructions and context across all sessions. |
| **TerminalController** | Manages a `LocalProcessTerminalView` from SwiftTerm. Handles buffer reading, cursor visibility, and process lifecycle. |
| **StatusPoller** | Polls terminal output every 2 seconds to detect agent status (Thinking, Writing, Running, etc.) via title parsing and buffer keyword matching. |
| **DeckContext** | Writes context files (CLAUDE.md, .deck-context.md) so AI agents know about sibling sessions, project instructions, and Deck's tools. |
| **SessionIntelligence** | Optional AI-powered naming and project name enhancement. Uses Anthropic API (Haiku) when an API key is configured. Fully optional — app works without it. |
| **DesignModeManager** | Manages the browser element inspector. Injects JavaScript for hover highlighting and click selection, reads computed styles, and applies live CSS changes. |

### Project-first model

Deck organizes sessions into projects automatically:

1. When you create a session, `GitDetector.rootDirectory(for:)` finds the git repo root
2. `SessionManager.resolveProject(for:)` finds or creates a matching project
3. Every session belongs to a project — no orphaned tabs
4. Projects share instructions and context via `DeckContext`
5. AI naming (optional) enhances generic directory names ("java" → "Square Monorepo")

### File structure

```
Sources/Deck/
├── Models/          # Session, SessionGroup (Project), AgentStatus, etc.
├── ViewModels/      # SessionManager, StatusPoller, DesignModeManager
├── Helpers/         # GitDetector, DeckContext, AnthropicClient, SessionIntelligence
├── Views/
│   ├── Sidebar/     # SidebarView, SessionGroupView, SessionRowView
│   ├── Terminal/    # TerminalBridge, ChatInputView, AgentOutputParser
│   ├── Browser/     # BrowserPaneView, WebViewBridge, DeviceFrameView
│   ├── DesignMode/  # DesignPanelView, color/spacing/typography sections
│   ├── Settings/    # General, Appearance, Terminal, Context, Themes, Feedback
│   └── StatusBar/   # StatusBarView
├── Theme/           # Theme system, built-in themes, sharing
└── DeckApp.swift    # App entry point, window configuration
```

### Performance design

- **Terminal buffer scanning** uses preallocated character buffers and skips unchanged sessions
- **Git root lookups** are cached after first call per directory
- **Sidebar sorting** precomputes activity indices in O(n) instead of O(n²)
- **Context file writes** happen on a background thread with 10-second debounce
- **All sessions stay alive** in a ZStack for instant tab switching (no process restart)
- **AI features are progressive** — zero overhead when no API key is set
