# Deck — AI-First Terminal Emulator for macOS

Deck is a native macOS terminal emulator designed specifically for AI-assisted coding with Claude Code and Amp. Think of it as "Cursor for the terminal" — it wraps AI coding agents in a purpose-built environment with a chat input, built-in browser preview, session management, and design tools.

## Vision & Spirit

Deck exists because raw terminal is a poor experience for AI coding. When Claude Code or Amp writes code, you want to:
- **See the result instantly** — built-in browser pane shows localhost previews side-by-side
- **Send prompts comfortably** — chat input with Enter-to-send, not typing into a raw PTY
- **Manage multiple agents** — sessions with named tabs, groups, and switching
- **Keep context** — intent pins, checkpoints, and persistent sessions across restarts
- **Stay in flow** — everything in one window, no switching between terminal + browser + Figma

### Design Principles
1. **Progressive disclosure** — start minimal, reveal features on hover/need
2. **Chat-first** — AI agents get a text input, not raw terminal keystrokes (but raw mode is available)
3. **Session = project** — sessions persist with scrollback, intent, and checkpoints
4. **Theme-first** — every pixel reads from the theme system, no hardcoded colors
5. **Native Mac** — Swift + SwiftUI + SwiftTerm, 30MB idle, sub-second launch

### Who It's For
Product designers and developers who use Claude Code and Amp daily. The user is assumed to be thinking about visual output and UX, not low-level terminal operations.

## Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| Language | Swift 5.9+ | Native Mac, fast compilation |
| UI Framework | SwiftUI | Declarative, reactive, native feel |
| Terminal | [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) | Production-grade VT100/xterm emulation with Metal GPU support |
| Browser | WKWebView | Native WebKit, no Chromium overhead |
| Build | Swift Package Manager | Simple, CLI-buildable, no Xcode project needed |
| App Bundle | Custom script (`scripts/build-app.sh`) | Creates .app with Info.plist and entitlements |

## Architecture

```
Sources/Deck/
├── DeckApp.swift                    # @main entry, window config, app delegate
├── ContentView.swift                # Root layout: sidebar + terminal + status bar
├── Models/
│   ├── Session.swift                # Core model: terminal session with all state
│   ├── AgentType.swift              # .claude / .amp / .shell
│   ├── AgentStatus.swift            # .idle / .thinking / .writing / etc.
│   ├── SessionGroup.swift           # Named groups for organizing sessions
│   ├── Checkpoint.swift             # State snapshots
│   ├── BrowserTab.swift             # Browser pane tabs
│   ├── TodoItem.swift               # To-do list items
│   └── AppState.swift               # Persisted state (JSON)
├── Theme/
│   ├── ThemeColor.swift             # Codable color type → SwiftUI Color / NSColor
│   ├── Theme.swift                  # All semantic token structs (surfaces, text, etc.)
│   ├── BuiltInThemes.swift          # Obsidian, Porcelain, Ember, Aurora
│   ├── ThemeManager.swift           # Load/save/switch themes, import/export
│   └── ThemeEnvironment.swift       # SwiftUI EnvironmentKey
├── Views/
│   ├── Terminal/
│   │   ├── TerminalBridge.swift     # NSViewRepresentable wrapping SwiftTerm
│   │   ├── TerminalContainerView.swift  # Terminal + intent pin + checkpoints + chat
│   │   ├── ChatInputView.swift      # Chat input bar (Enter sends, Shift+Enter newline)
│   │   └── AgentOutputParser.swift  # Parses Claude/Amp output for status
│   ├── Sidebar/
│   │   ├── SidebarView.swift        # Session list + groups + to-do
│   │   ├── SessionRowView.swift     # Individual session row with drag support
│   │   ├── SessionGroupView.swift   # Collapsible group with drop target
│   │   ├── SidebarFooter.swift      # "+ New" popover menu
│   │   ├── NewSessionSheet.swift    # Session creation form
│   │   └── TodoListView.swift       # Inline to-do list
│   ├── Browser/
│   │   ├── BrowserPaneView.swift    # WKWebView with tabs, URL bar, device frames
│   │   ├── DeviceFrameView.swift    # Phone/tablet bezels
│   │   └── FigmaOverlayView.swift   # Figma design overlay toolbar
│   ├── SessionChrome/
│   │   ├── IntentPinView.swift      # Design intent bar (hidden when empty)
│   │   └── CheckpointStripView.swift # Checkpoint pills (hidden when empty)
│   ├── StatusBar/StatusBarView.swift # CWD, git, agent status
│   ├── Landing/LandingView.swift    # Welcome screen with launch cards
│   ├── Settings/                    # Settings window (4 tabs)
│   ├── History/                     # Session history + daily digest
│   ├── Market/                      # Market component palette
│   └── Shared/
│       ├── ResizeHandle.swift       # Sidebar drag-to-resize
│       └── ColorSwatchView.swift    # Theme editor color picker
├── ViewModels/
│   └── SessionManager.swift         # Central state: sessions, groups, CRUD, persistence
├── Storage/                         # Persistence helpers (JSON, scrollback)
└── Helpers/
    ├── AppMenu.swift                # NSMenu shortcuts (work in raw mode)
    ├── GitDetector.swift            # Git branch/status detection
    ├── AutoNamer.swift              # Session auto-naming
    ├── DeckContext.swift            # Writes .deck-context.md for AI agents
    ├── FullDiskAccess.swift         # FDA onboarding prompt
    └── AccessibilityIDs.swift       # UI test identifiers
```

## Key Design Decisions

### Chat Mode vs Raw Mode
- **Chat mode** (default): User types in a SwiftUI text editor at the bottom. Enter sends. Shift+Enter for newlines. Text is written to the PTY so the terminal processes it.
- **Raw mode**: Keystrokes go directly to the terminal's PTY. Used for interactive TUIs (vim, htop) or when the AI agent needs direct key input.
- Toggle via View → Toggle Raw/Chat Mode (Cmd+Shift+E).
- State is tracked in `SessionManager.chatModeSessionIds` (a `@Published Set<UUID>`) so SwiftUI reliably re-renders on toggle.

### Focus Management
The hardest technical challenge. SwiftTerm's `LocalProcessTerminalView` aggressively claims first responder. Solutions:
- In chat mode, `TerminalController.unfocusTerminal()` calls `window.makeFirstResponder(nil)` to release the terminal.
- The chat input uses an `NSTextView` (via `NSViewRepresentable`) instead of SwiftUI's `TextEditor` to get reliable Enter vs Shift+Enter handling.
- App-level menu shortcuts (`AppMenu.swift`) use `NSMenu` items which fire regardless of which view has focus — critical for raw mode.

### Menu Shortcuts
SwiftUI's `.keyboardShortcut()` only works when SwiftUI views have focus. When SwiftTerm's NSView is first responder, those shortcuts are invisible. Solution: install custom `NSMenu` items in the app's main menu bar via `AppMenuManager` (must inherit `NSObject`). Menu must be installed with a 1-second delay after app launch because SwiftUI overwrites the menu bar during setup.

### Session Switching
Each session gets a unique `TerminalController` stored in `SessionManager.terminalControllers[id]`. The `TerminalContainerView` is keyed with `.id(activeSessionId)` to force SwiftUI to recreate it when switching, ensuring each session gets its own terminal view.

### Theme System
Every view reads colors from `@Environment(\.deckTheme)`. The `Theme` struct contains nested sub-structs (`SurfaceColors`, `TextColors`, `AccentColors`, etc.) with all properties as `var` for editability. 4 built-in themes ship with the app. User themes are saved as JSON to `~/Library/Application Support/Deck/Themes/`.

### AI Agent Context
When a session is created, `DeckContext.swift` writes a `.deck-context.md` file (and appends to `CLAUDE.md` for Claude sessions) that tells the AI agent about all of Deck's features — browser pane, device frames, checkpoints, Market palette, etc. This way Claude/Amp can proactively suggest using Deck's tools.

## Building & Running

```bash
cd ~/Development/Deck

# Build and create app bundle
bash scripts/build-app.sh

# Launch
open .build/Deck.app

# Or run directly (for debugging — logs go to stderr)
.build/Deck.app/Contents/MacOS/Deck
```

### Requirements
- macOS 14+
- Swift 5.9+ (comes with Xcode or Command Line Tools)
- `claude` CLI (for Claude Code sessions)
- `amp` CLI (for Amp sessions)

### First Launch
Grant Full Disk Access in System Settings → Privacy & Security → Full Disk Access → add Deck. This prevents per-folder permission dialogs.

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd+N | New shell session |
| Cmd+Shift+C | New Claude Code session |
| Cmd+Shift+A | New Amp session |
| Cmd+Shift+N | New session (with dialog) |
| Cmd+W | Close session |
| Cmd+1-9 | Switch to session N |
| Cmd+[ / ] | Previous / next session |
| Cmd+B | Toggle browser pane |
| Cmd+L | Focus browser URL bar |
| Cmd+Shift+L | Toggle sidebar |
| Cmd+Shift+E | Toggle raw/chat mode |
| Cmd+Shift+S | Create checkpoint |
| Cmd+, | Settings |
| Enter | Send text (chat mode) |
| Shift+Enter | New line (chat mode) |

## What's Implemented vs Stubbed

### Fully Working
- Terminal emulation (SwiftTerm), shell/Claude/Amp sessions
- Chat input with Enter-to-send
- Raw/chat mode toggle
- Sidebar with sessions, groups, drag-and-drop
- Browser pane with WKWebView, URL bar, device frames
- Theme system with 4 built-in themes + editor
- Intent pin, checkpoint strip
- Status bar, to-do list, landing screen
- Session persistence, auto-naming
- All keyboard shortcuts via NSMenu

### Stubbed (UI built, backend not wired)
- Figma overlay (toolbar built, no Figma API)
- Market component palette (sample data, not real docs)
- Smart history (views built, no SQLite)
- Daily digest (template, no git analysis)
- Color token inline detection
- Pattern detection
