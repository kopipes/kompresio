#!/usr/bin/env bash
# build.sh — Build Kompresio.app from Swift sources
set -e

APP_NAME="Kompresio"
BUNDLE_ID="com.bob.kompresio"
BUILD_DIR="$(pwd)/.build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "==> Cleaning build dir"
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS" "$RESOURCES"

echo "==> Compiling Swift sources"
swiftc \
    -O \
    -target arm64-apple-macosx14.0 \
    -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
    -strict-concurrency=minimal \
    -framework Cocoa \
    -framework AppKit \
    -framework ImageIO \
    -framework UniformTypeIdentifiers \
    -framework SwiftUI \
    Sources/main.swift \
    Sources/AppDelegate.swift \
    Sources/StatusBarController.swift \
    Sources/Presets.swift \
    Sources/ImageProcessor.swift \
    Sources/ContentView.swift \
    -o "$MACOS/$APP_NAME"

echo "==> Copying resources"
cp Resources/Info.plist "$CONTENTS/Info.plist"

echo "==> Ad-hoc signing"
codesign --force --deep --sign - "$APP_DIR"

echo ""
echo "Build successful!"
echo "App bundle: $APP_DIR"
echo ""
echo "To run: open '$APP_DIR'"
echo "To install: cp -r '$APP_DIR' /Applications/"
