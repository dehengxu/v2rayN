#!/bin/bash
set -e

# 配置
ARCH="osx-arm64" # 当前是 M1/M2/M3 ...
APP_NAME="v2rayN"
PUBLISH_DIR="publish/$ARCH"
APP_BUNDLE="$APP_NAME.app"
DMG_NAME="$APP_NAME-$ARCH.dmg"
VERSION="7.0.0" # 可以根据需要修改

echo "🧹 清理旧文件..."
rm -rf "$PUBLISH_DIR" "$APP_BUNDLE" "$DMG_NAME"

echo "🏗️  正在编译 $APP_NAME ($ARCH)..."
dotnet publish v2rayN/v2rayN.Desktop/v2rayN.Desktop.csproj \
    -c Release \
    -r $ARCH \
    --self-contained true \
    -o "$PUBLISH_DIR"

echo "📦 构建 .app 结构..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 复制发布文件
cp -a "$PUBLISH_DIR/"* "$APP_BUNDLE/Contents/MacOS/"

# 处理图标
if [ -f "$APP_BUNDLE/Contents/MacOS/v2rayN.icns" ]; then
    cp "$APP_BUNDLE/Contents/MacOS/v2rayN.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
else
    echo "⚠️  警告: 未找到图标文件 v2rayN.icns"
fi

# 创建 Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.2dust.v2rayN</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
</dict>
</plist>
EOF

# 清理不必要的配置文件标记 (防止 macOS 隔离机制问题)
# xattr -cr "$APP_BUNDLE" 替代方案，兼容性更好
find "$APP_BUNDLE" -exec xattr -c {} \; 2>/dev/null || true

echo "💿 创建 DMG 镜像..."
# 使用 hdiutil 创建 dmg
hdiutil create -volname "$APP_NAME Installer" -srcfolder "$APP_BUNDLE" -ov -format UDZO "$DMG_NAME"

echo "✅ 完成! DMG 文件位于: $DMG_NAME"
