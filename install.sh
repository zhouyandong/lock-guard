#!/bin/bash
set -euo pipefail

APP_NAME="LockGuard"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)/LockGuard"
INSTALL_DIR="/Applications"

echo "═══════════════════════════════════"
echo "  LockGuard - 安装脚本"
echo "═══════════════════════════════════"
echo ""

# Check Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
    echo "❌ 需要 Xcode Command Line Tools，正在安装..."
    xcode-select --install
    echo "请等待安装完成后再运行此脚本。"
    exit 1
fi

# Kill existing LockGuard
if pkill -f "LockGuard.app/Contents/MacOS/LockGuard" 2>/dev/null; then
    echo "✅ 已停止旧版 LockGuard"
else
    echo "ℹ️  没有运行中的 LockGuard"
fi

# Build
echo ""
echo "🔨 编译中..."
BUILD_DIR="$SRC_DIR/../build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/Resources"

swiftc \
    -o "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME" \
    -target arm64-apple-macosx12.0 \
    -framework Cocoa \
    -framework IOKit \
    -framework ServiceManagement \
    "$SRC_DIR/main.swift" \
    "$SRC_DIR/AppDelegate.swift" \
    "$SRC_DIR/StatusBarController.swift"

cp "$SRC_DIR/Info.plist" "$BUILD_DIR/$APP_NAME.app/Contents/Info.plist"

# Copy app icon
if [ -f "$SRC_DIR/Resources/AppIcon.icns" ]; then
    cp "$SRC_DIR/Resources/AppIcon.icns" "$BUILD_DIR/$APP_NAME.app/Contents/Resources/"
fi

# Ad-hoc sign
codesign --sign - --force --deep "$BUILD_DIR/$APP_NAME.app" 2>/dev/null || true

echo "✅ 编译完成"

# Install
echo ""
echo "📦 安装到 $INSTALL_DIR ..."
rm -rf "$INSTALL_DIR/$APP_NAME.app"
cp -R "$BUILD_DIR/$APP_NAME.app" "$INSTALL_DIR/"

# Remove quarantine attribute (bypasses Gatekeeper for unsigned apps)
xattr -d com.apple.quarantine "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || true
xattr -cr "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || true

echo "✅ 安装完成"

# Launch
echo ""
echo "🚀 启动 LockGuard..."
open "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || \
    "$INSTALL_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME" &

echo ""
echo "═══════════════════════════════════"
echo "  LockGuard 已就绪！"
echo ""
echo "  菜单栏右侧会显示 🛡️ 盾牌图标"
echo "  锁屏后自动阻止系统休眠"
echo "  解锁后自动恢复"
echo ""
echo "  如需开机自启："
echo "  右键菜单栏图标 → 开机自启动"
echo "═══════════════════════════════════"
