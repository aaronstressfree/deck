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

# Download latest release via GitHub API (works without gh CLI)
echo "Downloading latest build..."
RELEASE_JSON=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest")
DOWNLOAD_URL=$(echo "$RELEASE_JSON" | grep "browser_download_url" | grep -i "deck.*zip" | head -1 | cut -d '"' -f 4)

if [ -z "$DOWNLOAD_URL" ]; then
    # Try gh CLI as fallback
    if command -v gh &>/dev/null; then
        gh release download --repo "$REPO" --pattern "Deck*.zip" --dir "$TMP_DIR" 2>/dev/null
    fi
else
    echo "Downloading from $DOWNLOAD_URL"
    curl -sL "$DOWNLOAD_URL" -o "$TMP_DIR/Deck.zip"
fi

# Find the zip
ZIPFILE=$(find "$TMP_DIR" -name "*.zip" -maxdepth 1 | head -1)
if [ -z "$ZIPFILE" ]; then
    echo "Error: Could not download Deck. Check https://github.com/$REPO/releases"
    exit 1
fi

# Unzip
echo "Extracting..."
unzip -qo "$ZIPFILE" -d "$TMP_DIR"

# Find the .app (might be nested)
APP_SRC=$(find "$TMP_DIR" -name "Deck.app" -maxdepth 2 | head -1)
if [ -z "$APP_SRC" ]; then
    echo "Error: Deck.app not found in archive."
    exit 1
fi

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
cp -R "$APP_SRC" "$INSTALL_PATH"

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
