#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

CONFIG="${1:-debug}"

echo "=== Building MacPulse ($CONFIG) ==="
if [ "$CONFIG" = "release" ]; then
    swift build -c release
    BIN="$PROJECT_DIR/.build/x86_64-apple-macosx/release/MacPulse"
    if [ ! -f "$BIN" ]; then
        BIN="$PROJECT_DIR/.build/release/MacPulse"
    fi
else
    swift build
    BIN="$PROJECT_DIR/.build/x86_64-apple-macosx/debug/MacPulse"
    if [ ! -f "$BIN" ]; then
        BIN="$PROJECT_DIR/.build/debug/MacPulse"
    fi
fi

if [ ! -f "$BIN" ]; then
    echo "Error: Binary not found at $BIN"
    exit 1
fi

APP_BUNDLE="$PROJECT_DIR/MacPulse.app"
echo "=== Packaging $APP_BUNDLE from $BIN ==="
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN" "$APP_BUNDLE/Contents/MacOS/MacPulse"
chmod +x "$APP_BUNDLE/Contents/MacOS/MacPulse"

cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "=== Signing $APP_BUNDLE ==="
codesign --force --deep --sign - "$APP_BUNDLE"

echo "=== Verifying Code Signature ==="
codesign -v -vvv "$APP_BUNDLE"

echo "=== Build Succeeded! MacPulse.app is ready at $APP_BUNDLE ==="
