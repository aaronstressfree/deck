#!/bin/bash
# Full test script for Deck
set -e
cd "$(dirname "$0")/.."

SCREENSHOT_DIR="/tmp/deck-screenshots"
rm -rf "$SCREENSHOT_DIR"
mkdir -p "$SCREENSHOT_DIR"

echo "=== Building Deck ==="
bash scripts/build-app.sh 2>&1 | tail -3

echo "=== Launching Deck ==="
pkill Deck 2>/dev/null || true
sleep 1

# Clear saved state so we start fresh
rm -f ~/Library/Application\ Support/Deck/state.json

open .build/Deck.app
sleep 4

focus() {
    osascript -e 'tell application "System Events" to tell process "Deck" to set frontmost to true' 2>/dev/null
    sleep 0.5
}

shot() {
    screencapture -x "$SCREENSHOT_DIR/$1.png"
    echo "  [$1] captured"
}

key() {
    focus
    osascript -e "tell application \"System Events\" to tell process \"Deck\" to keystroke \"$1\" using $2" 2>/dev/null
    sleep "$3"
}

echo "=== Test 1: Landing screen (first launch) ==="
focus
shot "01-landing"

echo "=== Test 2: Create shell session (Cmd+N) ==="
key "n" "command down" 3
shot "02-shell-session"

echo "=== Test 3: Create second session (Cmd+N) ==="
key "n" "command down" 2
shot "03-two-sessions"

echo "=== Test 4: Switch to session 1 (Cmd+1) ==="
key "1" "command down" 1
shot "04-switched-session"

echo "=== Test 5: Toggle browser pane (Cmd+B) ==="
key "b" "command down" 2
shot "05-browser-pane"

echo "=== Test 6: Toggle browser off (Cmd+B) ==="
key "b" "command down" 1
shot "06-browser-hidden"

echo "=== Test 7: Toggle sidebar off (Cmd+Shift+L) ==="
key "l" "{command down, shift down}" 1
shot "07-no-sidebar"

echo "=== Test 8: Toggle sidebar on (Cmd+Shift+L) ==="
key "l" "{command down, shift down}" 1
shot "08-sidebar-back"

echo "=== Test 9: Open settings (Cmd+,) ==="
key "," "command down" 2
shot "09-settings"

echo "=== Test 10: Close settings (Cmd+W) ==="
key "w" "command down" 1

echo "=== Test 11: Close session (Cmd+W) ==="
key "w" "command down" 1
shot "11-session-closed"

echo "=== Test 12: Close last session — should show landing ==="
key "w" "command down" 2
shot "12-back-to-landing"

echo ""
echo "=== All screenshots ==="
ls -1 "$SCREENSHOT_DIR/"
echo ""
echo "Deck is still running. Kill with: pkill Deck"
