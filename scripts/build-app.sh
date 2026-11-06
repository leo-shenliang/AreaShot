#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${OUTPUT_APP:-$ROOT/build/AreaShot.app}"

if [[ "${UNIVERSAL:-0}" == "1" ]]; then
    swift build -c release --package-path "$ROOT" --arch arm64 --arch x86_64
    BIN_DIR="$ROOT/.build/out/Products/Release"
else
    swift build -c release --package-path "$ROOT"
    BIN_DIR="$(swift build -c release --package-path "$ROOT" --show-bin-path)"
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/AreaShot" "$APP/Contents/MacOS/AreaShot"
cp "$ROOT/Support/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Support/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

# A stable signing identity keeps the TCC screen-recording grant across rebuilds.
# Ad-hoc signatures are keyed by cdhash, which changes on every build.
# Pass CODESIGN_IDENTITY=- to force an ad-hoc signature for distribution.
IDENTITY="${CODESIGN_IDENTITY:-AreaShot Dev}"
if [[ "$IDENTITY" == "-" ]]; then
    codesign --force --sign - --identifier com.example.areashot "$APP"
elif security find-identity -p codesigning 2>/dev/null | grep -q "\"$IDENTITY\""; then
    codesign --force --sign "$IDENTITY" --identifier com.example.areashot "$APP"
else
    echo "warning: signing identity '$IDENTITY' not found; falling back to ad-hoc"
    echo "         screen recording permission will need to be re-granted after rebuilds"
    codesign --force --sign - --identifier com.example.areashot "$APP"
fi

echo "Built: $APP"
echo "Run:   open \"$APP\""
