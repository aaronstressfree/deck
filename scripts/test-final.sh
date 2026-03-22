#!/bin/bash
# Final comprehensive test for Deck
set -e
cd "$(dirname "$0")/.."

SCREENSHOT_DIR="/tmp/deck-final"
rm -rf "$SCREENSHOT_DIR"
mkdir -p "$SCREENSHOT_DIR"

echo "=== Building Deck ==="
bash scripts/build-app.sh 2>&1 | tail -3

echo "=== Fresh launch ==="
pkill Deck 2>/dev/null || true
sleep 1
rm -f ~/Library/Application\ Support/Deck/state.json
open .build/Deck.app
sleep 4

focus() {
    osascript -e 'tell application "System Events" to tell process "Deck" to set frontmost to true' 2>/dev/null
    sleep 0.5
}

shot() {
    screencapture -x "$SCREENSHOT_DIR/$1.png"
    echo "  captured: $1"
}

key() {
    focus
    osascript -e "tell application \"System Events\" to tell process \"Deck\" to keystroke \"$1\" using $2" 2>/dev/null
    sleep "$3"
}

echo "--- 1. Landing screen ---"
focus
shot "01-landing-fresh"

echo "--- 2. Create Claude session ---"
key "c" "{command down, shift down}" 3
shot "02-claude-session"

echo "--- 3. Create Shell session ---"
key "n" "command down" 3
shot "03-shell-session"

echo "--- 4. Switch to session 1 ---"
key "1" "command down" 1
shot "04-switch-session"

echo "--- 5. Browser pane on ---"
key "b" "command down" 2
shot "05-browser-open"

echo "--- 6. Browser pane off ---"
key "b" "command down" 1
shot "06-browser-closed"

echo "--- 7. Sidebar off ---"
key "l" "{command down, shift down}" 1
shot "07-no-sidebar"

echo "--- 8. Sidebar on ---"
key "l" "{command down, shift down}" 1
shot "08-sidebar-back"

echo "--- 9. Settings ---"
key "," "command down" 2
shot "09-settings"

echo "--- 10. Close settings ---"
key "w" "command down" 1

echo "--- 11. Close all sessions to landing ---"
key "w" "command down" 1
sleep 0.5
key "w" "command down" 2
shot "11-back-to-landing"

echo ""
echo "=== Final screenshots ==="
ls -1 "$SCREENSHOT_DIR/"
echo ""
echo "Done. Deck still running."
