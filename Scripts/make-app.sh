#!/bin/bash
# Assembles dist/LutFx.app from the LutFxApp SwiftPM product.
#   Scripts/make-app.sh            # arm64 release build
#   Scripts/make-app.sh universal  # arm64 + x86_64
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0")

if [[ "${1:-}" == "universal" ]]; then
    swift build -c release --product LutFxApp --arch arm64 --arch x86_64
    BIN=.build/out/Products/Release/LutFxApp
else
    swift build -c release --product LutFxApp
    BIN=$(swift build -c release --product LutFxApp --show-bin-path)/LutFxApp
fi

APP=dist/LutFx.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/LutFx"
cp Assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key><string>LutFx</string>
	<key>CFBundleDisplayName</key><string>LutFx</string>
	<key>CFBundleIdentifier</key><string>com.avis001.lutfx</string>
	<key>CFBundleExecutable</key><string>LutFx</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleIconFile</key><string>AppIcon</string>
	<key>CFBundleShortVersionString</key><string>${VERSION}</string>
	<key>CFBundleVersion</key><string>${VERSION}</string>
	<key>LSMinimumSystemVersion</key><string>13.0</string>
	<key>LSApplicationCategoryType</key><string>public.app-category.video</string>
	<key>NSHighResolutionCapable</key><true/>
	<key>NSHumanReadableCopyright</key><string>© 2026 Sivasankar K — MIT License</string>
</dict>
</plist>
PLIST

printf 'APPL????' > "$APP/Contents/PkgInfo"

# Ad-hoc signature (replace with Developer ID for public distribution)
codesign --force --sign - "$APP"

echo "Built $APP (version $VERSION)"
