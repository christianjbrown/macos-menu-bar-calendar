#!/bin/zsh
# Builds a universal, sandboxed MenuBarCalendar for the Mac App Store and signs it there.
#
# Usage: scripts/app-store.sh            # writes build/app-store/MenuBarCalendar.pkg
#        scripts/app-store.sh --upload   # uploads the build to App Store Connect instead
#
# Settings come from app-store.env (copy app-store.env.example) or the environment:
#   BUNDLE_ID     the App ID registered for the app in your developer account
#   TEAM_ID       your Apple developer team
#   BUILD_NUMBER  optional; defaults to the number of commits, so it rises with every merge
#
# Xcode does the signing: it makes the distribution certificate and provisioning profile it
# needs, so Xcode must be signed in to the developer account (Xcode, Settings, Accounts).
set -euo pipefail
cd "${0:A:h}/.."

[[ -f app-store.env ]] && source app-store.env
: "${BUNDLE_ID:?set BUNDLE_ID in app-store.env}"
: "${TEAM_ID:?set TEAM_ID in app-store.env}"
BUILD_NUMBER="${BUILD_NUMBER:-$(git rev-list --count HEAD)}"

readonly app_name=MenuBarCalendar
readonly archive="build/$app_name.xcarchive"
readonly export_dir=build/app-store
readonly export_options=build/ExportOptions.plist
readonly plistbuddy=/usr/libexec/PlistBuddy

destination=export
[[ "${1:-}" == "--upload" ]] && destination=upload

# Intel and Apple silicon in one binary. The icon tool only runs here, so it stays native.
swift build -c release --product "$app_name" --arch arm64 --arch x86_64 2>&1 | grep -v "search path .* not found" || true
swift build -c release --product AppIconTool 2>&1 | grep -v "search path .* not found" || true
universal_bin="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/$app_name"
icon_tool="$(swift build -c release --show-bin-path)/AppIconTool"
[[ -x "$universal_bin" && -x "$icon_tool" ]] || { echo "build failed" >&2; exit 1; }

rm -rf "$archive" "$export_dir"
app="$archive/Products/Applications/$app_name.app"
mkdir -p "${app:h}"
scripts/assemble-app.sh "$universal_bin" "$icon_tool" "$app"

info="$app/Contents/Info.plist"
"$plistbuddy" -c "Set :CFBundleIdentifier $BUNDLE_ID" "$info"
"$plistbuddy" -c "Set :CFBundleVersion $BUILD_NUMBER" "$info"

# App Store Connect checks which Xcode and SDK made the build. Xcode writes these keys
# itself; a Swift package build does not, so they are added from the toolchain that ran.
xcode_version="$(xcodebuild -version | awk 'NR==1 {print $2}')"
xcode_build="$(xcodebuild -version | awk 'NR==2 {print $3}')"
sdk_version="$(xcrun --sdk macosx --show-sdk-version)"
sdk_build="$(xcrun --sdk macosx --show-sdk-build-version)"
typeset -A toolchain_keys=(
  DTCompiler com.apple.compilers.llvm.clang.1_0
  DTPlatformName macosx
  DTPlatformVersion "$sdk_version"
  DTPlatformBuild "$sdk_build"
  DTSDKName "macosx$sdk_version"
  DTSDKBuild "$sdk_build"
  DTXcode "$(printf '%d%d%d' ${(s:.:)xcode_version} 0 0 | cut -c1-4)"
  DTXcodeBuild "$xcode_build"
  BuildMachineOSBuild "$(sw_vers -buildVersion)"
)
for key value in "${(@kv)toolchain_keys}"; do
  "$plistbuddy" -c "Add :$key string $value" "$info"
done

# Signed here only to carry the entitlements; the export re-signs it for distribution.
codesign --force --options runtime --entitlements Support/MenuBarCalendar.entitlements --sign - "$app"

short_version="$("$plistbuddy" -c "Print :CFBundleShortVersionString" "$info")"
cat > "$archive/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>ApplicationProperties</key>
	<dict>
		<key>ApplicationPath</key><string>Applications/$app_name.app</string>
		<key>Architectures</key><array><string>arm64</string><string>x86_64</string></array>
		<key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
		<key>CFBundleShortVersionString</key><string>$short_version</string>
		<key>CFBundleVersion</key><string>$BUILD_NUMBER</string>
		<key>Team</key><string>$TEAM_ID</string>
	</dict>
	<key>ArchiveVersion</key><integer>2</integer>
	<key>CreationDate</key><date>$(date -u +%Y-%m-%dT%H:%M:%SZ)</date>
	<key>Name</key><string>$app_name</string>
	<key>SchemeName</key><string>$app_name</string>
</dict>
</plist>
PLIST

cat > "$export_options" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key><string>app-store-connect</string>
	<key>destination</key><string>$destination</string>
	<key>teamID</key><string>$TEAM_ID</string>
	<key>signingStyle</key><string>automatic</string>
	<key>manageAppVersionAndBuildNumber</key><false/>
</dict>
</plist>
PLIST

xcodebuild -exportArchive -archivePath "$archive" -exportPath "$export_dir" \
  -exportOptionsPlist "$export_options" -allowProvisioningUpdates

if [[ "$destination" == upload ]]; then
  echo "Uploaded $short_version ($BUILD_NUMBER) to App Store Connect"
else
  echo "Built $export_dir/$app_name.pkg, version $short_version ($BUILD_NUMBER)"
fi
