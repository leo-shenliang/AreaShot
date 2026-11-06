#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$ROOT/Support/Info.plist")"
DIST="$ROOT/dist"
DMG="$DIST/AreaShot-$VERSION-universal.dmg"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/areashot-dmg.XXXXXX")"

cleanup() {
    rm -rf "$STAGE"
}
trap cleanup EXIT

SIGN_ID="${CODESIGN_IDENTITY:-}"
if [[ -z "$SIGN_ID" ]]; then
    SIGN_ID="-"
fi

OUTPUT_APP="$STAGE/AreaShot.app" UNIVERSAL=1 CODESIGN_IDENTITY="$SIGN_ID" \
    "$ROOT/scripts/build-app.sh"

codesign --verify --deep --strict "$STAGE/AreaShot.app"
lipo -info "$STAGE/AreaShot.app/Contents/MacOS/AreaShot"

ln -s /Applications "$STAGE/Applications"
cat > "$STAGE/安装说明.txt" <<EOF
AreaShot $VERSION

安装
1. 将 AreaShot 拖入右侧的 Applications 文件夹。
2. 首次打开时，系统可能提示“无法验证开发者”。请右键点击 AreaShot，
   选择“打开”，再确认“打开”。如果系统只显示“完成”，请前往
   “系统设置 > 隐私与安全性”，在底部点击“仍要打开”。
3. 也可以打开“终端”，执行：
   xattr -dr com.apple.quarantine /Applications/AreaShot.app

使用
- 应用常驻菜单栏，没有 Dock 图标。
- Option + Shift + A：区域截图
- Option + Shift + S：全屏截图
- 首次截图时，请在“系统设置 > 隐私与安全性 > 屏幕录制”中允许 AreaShot，
  然后退出并重新启动应用。

说明
本应用使用 ad-hoc 签名，未使用 Apple Developer ID 公证，因此首次打开需要
上述手动确认。应用不包含联网功能。
EOF

mkdir -p "$DIST"
rm -f "$DMG" "$DMG.sha256"
hdiutil create -volname "AreaShot $VERSION" -srcfolder "$STAGE" -format UDZO -ov "$DMG"
hdiutil verify "$DMG" >/dev/null

MOUNT_POINT="$(hdiutil attach -nobrowse -readonly "$DMG" | tail -1 | awk -F '\t' '{print $3}')"
ls -la "$MOUNT_POINT"
hdiutil detach "$MOUNT_POINT" >/dev/null

shasum -a 256 "$DMG" | tee "$DMG.sha256"
echo
echo "DMG: $DMG"
