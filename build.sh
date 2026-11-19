#!/bin/zsh
# Builds MenuBarCalendar.app into ./build. Pass --install to copy it to /Applications.
set -euo pipefail
cd "${0:A:h}"

for product in MenuBarCalendar AppIconTool; do
  swift build -c release --product "$product" 2>&1 | grep -v "search path .* not found" || true
done
bins="$(swift build -c release --show-bin-path)"
bin="$bins/MenuBarCalendar"
[[ -x "$bin" && -x "$bins/AppIconTool" ]] || { echo "build failed" >&2; exit 1; }

app=build/MenuBarCalendar.app
scripts/assemble-app.sh "$bin" "$bins/AppIconTool" "$app"
codesign --force --sign - "$app"
echo "Built $app"

if [[ "${1:-}" == "--install" ]]; then
  pkill -x MenuBarCalendar 2>/dev/null || true
  rm -rf /Applications/MenuBarCalendar.app
  cp -R "$app" /Applications/
  open /Applications/MenuBarCalendar.app
  echo "Installed /Applications/MenuBarCalendar.app"
fi
