#!/bin/zsh
# Builds MenuBarCalendar.app into ./build. Pass --install to copy it to /Applications.
set -euo pipefail
cd "${0:A:h}"

swift build -c release --product MenuBarCalendar 2>&1 | grep -v "search path .* not found" || true
bin="$(swift build -c release --show-bin-path)/MenuBarCalendar"
[[ -x "$bin" ]] || { echo "build failed" >&2; exit 1; }

app=build/MenuBarCalendar.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp "$bin" "$app/Contents/MacOS/MenuBarCalendar"
cp Support/Info.plist "$app/Contents/Info.plist"
codesign --force --sign - "$app"
echo "Built $app"

if [[ "${1:-}" == "--install" ]]; then
  pkill -x MenuBarCalendar 2>/dev/null || true
  rm -rf /Applications/MenuBarCalendar.app
  cp -R "$app" /Applications/
  open /Applications/MenuBarCalendar.app
  echo "Installed /Applications/MenuBarCalendar.app"
fi
