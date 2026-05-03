#!/usr/bin/env bash
# Builds SymbolBrowser into a proper macOS .app bundle with LSUIElement=true
# (so it appears only in the menu bar, not in the Dock).
#
# Output: ./SymbolBrowser.app
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIG="${1:-release}"

echo "Building SymbolBrowser in $CONFIG configuration..."
swift build -c "$CONFIG" --product SymbolBrowser

BIN_DIR=".build/$CONFIG"
APP="SymbolBrowser.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

# Bundle the executable.
cp "$BIN_DIR/SymbolBrowser" "$APP/Contents/MacOS/SymbolBrowser"

# Bundle the per-set resource bundles into Contents/Resources/. SwiftPM's
# auto-generated `Bundle.module` accessor searches Bundle.main.resourceURL
# (== Contents/Resources for an .app) and Bundle.main.bundleURL (== the .app
# itself). Putting the bundles in MacOS/ would make Bundle.module fall through
# to the wrong bundle and Image(name:bundle:) lookups would silently fail.
cp -R "$BIN_DIR/"*CornucopiaSymbols*.bundle "$APP/Contents/Resources/" 2>/dev/null || true
cp -R "$BIN_DIR/"*CornucopiaSymbols*.resources "$APP/Contents/Resources/" 2>/dev/null || true

# `swift build` ships .xcassets as raw directories — SwiftUI's Image(name:bundle:)
# can only find named assets in a compiled Assets.car. Compile each per-set
# catalog with actool and replace the raw directory with the .car file.
echo "Compiling asset catalogs with actool..."
shopt -s nullglob
for bundle in "$APP/Contents/Resources/"*CornucopiaSymbols*.bundle "$APP/Contents/Resources/"*CornucopiaSymbols*.resources; do
    [ -d "$bundle" ] || continue
    xcassets_dir=$(find "$bundle" -name '*.xcassets' -type d -maxdepth 2 | head -1)
    [ -n "$xcassets_dir" ] || continue
    set_name=$(basename "$bundle" | sed -E 's/^[^_]+_CornucopiaSymbols([^.]+)\..*/\1/')
    compile_out=$(mktemp -d)
    xcrun actool "$xcassets_dir" \
        --platform macosx \
        --minimum-deployment-target 13.0 \
        --compile "$compile_out" \
        --output-format human-readable-text \
        > /dev/null
    rm -rf "$xcassets_dir"
    mv "$compile_out/Assets.car" "$bundle/Assets.car"
    rm -rf "$compile_out"
    car_size=$(du -sh "$bundle/Assets.car" | cut -f1)
    echo "  $set_name: $car_size"
done
shopt -u nullglob

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>             <string>SymbolBrowser</string>
    <key>CFBundleIdentifier</key>             <string>de.vanille.CornucopiaSymbols.SymbolBrowser</string>
    <key>CFBundleName</key>                   <string>SymbolBrowser</string>
    <key>CFBundleDisplayName</key>            <string>Symbol Browser</string>
    <key>CFBundleShortVersionString</key>     <string>0.1.0</string>
    <key>CFBundleVersion</key>                <string>1</string>
    <key>CFBundlePackageType</key>            <string>APPL</string>
    <key>LSMinimumSystemVersion</key>         <string>13.0</string>
    <key>LSUIElement</key>                    <true/>
    <key>NSHighResolutionCapable</key>        <true/>
</dict>
</plist>
PLIST

echo "Built $APP. Launch with: open ./$APP"
