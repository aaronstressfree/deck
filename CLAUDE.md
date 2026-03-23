# Deck Development Guidelines

## Critical: Do NOT break clipboard (copy/paste)

Clipboard support uses the **standard macOS responder chain**. Do NOT add custom event monitors, notification-based paste routing, or intercept Cmd+V.

Architecture:
- Edit menu → `paste:` with `target: nil` → dispatched to first responder
- `DeckChatTextView` is the first responder in chat mode
- `DeckChatTextView.paste(_:)` handles both text and image paste
- `viewDidMoveToWindow` registers a fallback notification observer
- Auto-focus in `updateNSView` keeps the text view as first responder

**Before modifying ChatInputView.swift or DeckChatTextView, verify paste still works.**

## Critical: Terminal Colors

Claude Code checks `TERM_PROGRAM` env var to decide color depth. Deck sets `TERM_PROGRAM=ghostty` in the spawned process environment (TerminalBridge.swift). Without this, the Claude logo renders gray instead of orange.

Required env vars in `startProcess`:
- `TERM_PROGRAM=ghostty` (Claude Code checks this for 24-bit color)
- `COLORTERM=truecolor`
- `TERM=xterm-256color`
- `FORCE_COLOR=3`

## Build & Test

```bash
swift build                    # Build
swift test                     # Run tests (requires Xcode toolchain)
bash scripts/build-app.sh      # Build .app bundle
open .build/Deck.app           # Launch
```

## Architecture

- **SwiftUI + SwiftTerm** — Native macOS app, no Electron
- **Project-first** — Sessions auto-organize into projects by git root
- **Session resume** — `claude --resume <id>` on relaunch, IDs captured by StatusPoller
- **Context sharing** — DeckContext writes to CLAUDE.md for sibling awareness
- **Fonts bundled** — JetBrains Mono, Fira Code, Cascadia Code, IBM Plex Mono, Source Code Pro
