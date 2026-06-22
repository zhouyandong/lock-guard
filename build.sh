#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="LockGuard"
DEPLOYMENT_TARGET="12.0"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "=== LockGuard Build Script ==="
echo "Project: $PROJECT_DIR"
echo "macOS Deployment Target: $DEPLOYMENT_TARGET"
echo ""

# 1. Clean
echo "[1/4] Cleaning..."
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 2. Compile Swift sources
echo "[2/4] Compiling Swift..."
SOURCES=(
    "$PROJECT_DIR/$APP_NAME/main.swift"
    "$PROJECT_DIR/$APP_NAME/AppDelegate.swift"
    "$PROJECT_DIR/$APP_NAME/StatusBarController.swift"
)

swiftc \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    -target arm64-apple-macosx$DEPLOYMENT_TARGET \
    -framework Cocoa \
    -framework IOKit \
    -framework ServiceManagement \
    "${SOURCES[@]}"

echo "   Binary compiled: $APP_BUNDLE/Contents/MacOS/$APP_NAME"

# 3. Copy Info.plist
echo "[3/4] Copying Info.plist..."
cp "$PROJECT_DIR/$APP_NAME/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# 4. Copy app icon
echo "[4/4] Copying app icon..."
if [ -f "$PROJECT_DIR/$APP_NAME/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/$APP_NAME/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
    echo "   Icon copied"
else
    echo "   ⚠️ No AppIcon.icns found, run generate_icon.py first"
fi

echo ""
echo "=== Build Complete ==="
echo "App: $APP_BUNDLE"
echo ""
echo "用法:"
echo "  open $APP_BUNDLE                     (运行)"
echo "  cp -R $APP_BUNDLE /Applications/     (安装到应用程序)"
