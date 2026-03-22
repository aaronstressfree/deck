#!/bin/bash
set -e

cd "$(dirname "$0")/.."

# Build the binary
swift build 2>&1

# Create app bundle structure
APP_DIR=".build/Deck.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp .build/debug/Deck "$APP_DIR/Contents/MacOS/Deck"

# Copy SwiftTerm resources if present
if [ -d ".build/debug/SwiftTerm_SwiftTerm.bundle" ]; then
    cp -r .build/debug/SwiftTerm_SwiftTerm.bundle "$APP_DIR/Contents/Resources/"
fi

# Create Info.plist — no sandbox, full file/network access
cat > "$APP_DIR/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Deck</string>
    <key>CFBundleDisplayName</key>
    <string>Deck</string>
    <key>CFBundleIdentifier</key>
    <string>com.deck.app</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>Deck</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
    <key>NSDesktopFolderUsageDescription</key>
    <string>Deck needs access to your Desktop to run terminal sessions in any directory.</string>
    <key>NSDocumentsFolderUsageDescription</key>
    <string>Deck needs access to Documents to run terminal sessions in any directory.</string>
    <key>NSDownloadsFolderUsageDescription</key>
    <string>Deck needs access to Downloads to run terminal sessions in any directory.</string>
    <key>NSRemovableVolumesUsageDescription</key>
    <string>Deck needs access to external volumes to run terminal sessions in any directory.</string>
    <key>NSNetworkVolumesUsageDescription</key>
    <string>Deck needs access to network volumes to run terminal sessions in any directory.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Deck uses Apple Events for automation and testing.</string>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>com.deck.app.theme</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>deck</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST

# Create entitlements — disable sandbox, allow network for terminal app
cat > "$APP_DIR/Contents/entitlements.plist" << 'ENTITLEMENTS'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.inherit</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
</dict>
</plist>
ENTITLEMENTS

# Re-sign the entire app bundle with entitlements
codesign --force --deep --sign - --entitlements "$APP_DIR/Contents/entitlements.plist" "$APP_DIR" 2>&1 || echo "Warning: codesign failed"

echo "Built: $APP_DIR"
echo "Run with: open $APP_DIR"
