#!/bin/bash
# Deck installer/updater
# Usage: curl -sL https://raw.githubusercontent.com/aaronstressfree/deck/main/scripts/install.sh | bash

set -e

REPO="aaronstressfree/deck"
APP_NAME="Deck.app"
INSTALL_DIR="/Applications"
INSTALL_PATH="$INSTALL_DIR/$APP_NAME"
TMP_DIR=$(mktemp -d)

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "🃏 Deck installer"
echo ""

# Check if updating or fresh install
if [ -d "$INSTALL_PATH" ]; then
    CURRENT=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INSTALL_PATH/Contents/Info.plist" 2>/dev/null || echo "unknown")
    echo "Current version: $CURRENT"
    echo "Updating..."
else
    echo "Installing..."
fi

# Download latest release
echo "Downloading latest build..."
if ! gh release download latest --repo "$REPO" --pattern "Deck.zip" --dir "$TMP_DIR" 2>/dev/null; then
    # Fallback: try curl with GitHub API
    DOWNLOAD_URL=$(curl -sL "https://api.github.com/repos/$REPO/releases/tags/latest" | grep "browser_download_url.*Deck.zip" | head -1 | cut -d '"' -f 4)
    if [ -z "$DOWNLOAD_URL" ]; then
        echo "Error: No release found. Push to main first to trigger a build."
        exit 1
    fi
    curl -sL "$DOWNLOAD_URL" -o "$TMP_DIR/Deck.zip"
fi

# Unzip
echo "Extracting..."
unzip -qo "$TMP_DIR/Deck.zip" -d "$TMP_DIR"

# Quit running instance
if pgrep -x Deck > /dev/null 2>&1; then
    echo "Quitting running Deck..."
    osascript -e 'tell application "Deck" to quit' 2>/dev/null || true
    sleep 1
    pkill -x Deck 2>/dev/null || true
    sleep 1
fi

# Install
echo "Installing to $INSTALL_PATH..."
rm -rf "$INSTALL_PATH"
cp -R "$TMP_DIR/Deck.app" "$INSTALL_PATH"

# Clear quarantine flag
xattr -cr "$INSTALL_PATH" 2>/dev/null || true

# Get new version
NEW_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INSTALL_PATH/Contents/Info.plist" 2>/dev/null || echo "?")
NEW_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INSTALL_PATH/Contents/Info.plist" 2>/dev/null || echo "?")

echo ""
echo "✅ Deck v${NEW_VERSION} (build ${NEW_BUILD}) installed to $INSTALL_PATH"
echo ""
echo "Launch with: open -a Deck"
echo "Update later: re-run this script"
