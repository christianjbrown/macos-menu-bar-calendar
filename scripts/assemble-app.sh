#!/bin/zsh
# Puts MenuBarCalendar.app together from built products.
# Usage: scripts/assemble-app.sh <app binary> <AppIconTool binary> <output .app>
# Signing is left to the caller: build.sh signs ad hoc, app-store.sh signs for the App Store.
set -euo pipefail
cd "${0:A:h}/.."

binary="$1"
icon_tool="$2"
app="$3"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$binary" "$app/Contents/MacOS/MenuBarCalendar"
cp Support/Info.plist "$app/Contents/Info.plist"

# The app icon is drawn from the menu bar icon's vector shapes at every size macOS asks for.
"$icon_tool" "$work/AppIcon.iconset"
iconutil -c icns "$work/AppIcon.iconset" -o "$app/Contents/Resources/AppIcon.icns"
# The calendar shape comes from Bootstrap Icons, whose MIT licence travels with the app.
cp -R Support/Licenses "$app/Contents/Resources/"
