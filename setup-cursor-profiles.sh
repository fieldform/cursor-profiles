#!/bin/bash
# Create Cursor profile dirs and optional GUI launcher apps.
# Edit config.sh to change profile names, then run this script.
# See: https://forum.cursor.com/t/seamless-account-switching-in-cursor/58411/13

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_OVERRIDE="${PROFILES-}"
[[ -f "$REPO_ROOT/config.sh" ]] && source "$REPO_ROOT/config.sh"
PROFILES="${PROFILES_OVERRIDE:-${PROFILES:-Personal Work}}"
CURSOR_PROFILES_REPO="${CURSOR_PROFILES_REPO:-$REPO_ROOT/cursor-profiles}"
CURSOR_LAUNCHERS="${CURSOR_LAUNCHERS:-${HOME}/Applications/Cursor}"
CURSOR_APP="${CURSOR_APP:-/Applications/Cursor.app}"
CURSOR_BIN="${CURSOR_APP}/Contents/MacOS/Cursor"
LAUNCHER_SOURCE="${LAUNCHER_SOURCE:-$REPO_ROOT/native-launcher/Launcher.swift}"
SWIFTC_BIN="${SWIFTC_BIN:-}"
MACOS_SDK_PATH="${MACOS_SDK_PATH:-}"
unset PROFILES_OVERRIDE

if [[ ! -x "$CURSOR_BIN" ]]; then
  echo "⚠️  Cursor not found at $CURSOR_APP. Install Cursor first."
  exit 1
fi

if [[ -z "$SWIFTC_BIN" ]] && command -v xcrun >/dev/null 2>&1; then
  SWIFTC_BIN="$(xcrun --find swiftc 2>/dev/null || true)"
fi

if [[ -z "$MACOS_SDK_PATH" ]] && command -v xcrun >/dev/null 2>&1; then
  MACOS_SDK_PATH="$(xcrun --show-sdk-path --sdk macosx 2>/dev/null || true)"
fi

if [[ ! -f "$LAUNCHER_SOURCE" ]]; then
  echo "⚠️  Native launcher source not found at $LAUNCHER_SOURCE."
  exit 1
fi

if [[ -z "$SWIFTC_BIN" || ! -x "$SWIFTC_BIN" ]]; then
  echo "⚠️  Swift compiler not found. Install Xcode or Command Line Tools first."
  exit 1
fi

if [[ -z "$MACOS_SDK_PATH" || ! -d "$MACOS_SDK_PATH" ]]; then
  echo "⚠️  macOS SDK not found. Install Xcode or Command Line Tools first."
  exit 1
fi

echo "🛠️  Cursor profiles (in repo: $CURSOR_PROFILES_REPO)"
echo "    Profiles: $PROFILES"
echo ""

for profile in $PROFILES; do
  mkdir -p "$CURSOR_PROFILES_REPO/$profile/config/extensions"
  echo "   ✓ $CURSOR_PROFILES_REPO/$profile/config"
done

build_launcher_binary() {
  local output_path="$1"

  SDKROOT="$MACOS_SDK_PATH" "$SWIFTC_BIN" \
    -O \
    -framework AppKit \
    -framework Foundation \
    "$LAUNCHER_SOURCE" \
    -o "$output_path"
}

tmp_launcher_binary="$(mktemp "$REPO_ROOT/.launcher.XXXXXX")"
trap 'rm -f "$tmp_launcher_binary"' EXIT
build_launcher_binary "$tmp_launcher_binary"

make_launcher() {
  local profile="$1"
  local app_name="Cursor ${profile}"
  local app_dir="$CURSOR_LAUNCHERS/${app_name}.app"
  local user_data_dir="$CURSOR_PROFILES_REPO/$profile/config"
  local extensions_dir="$user_data_dir/extensions"
  local bundle_id="com.cursor.$(echo "$profile" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"

  mkdir -p "$app_dir/Contents/MacOS"
  mkdir -p "$app_dir/Contents/Resources"

  cat > "$app_dir/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Launcher</string>
    <key>CFBundleDisplayName</key>
    <string>${app_name}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${bundle_id}</string>
    <key>CFBundleName</key>
    <string>${app_name}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Folder</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Default</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.folder</string>
            </array>
        </dict>
    </array>
    <key>CursorBinaryPath</key>
    <string>${CURSOR_BIN}</string>
    <key>CursorUserDataDir</key>
    <string>${user_data_dir}</string>
    <key>CursorExtensionsDir</key>
    <string>${extensions_dir}</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

  cp "$tmp_launcher_binary" "$app_dir/Contents/MacOS/Launcher"
  chmod +x "$app_dir/Contents/MacOS/Launcher"

  local icon_src="$CURSOR_PROFILES_REPO/icons/${profile}.icns"
  if [[ -f "$icon_src" ]]; then
    cp "$icon_src" "$app_dir/Contents/Resources/AppIcon.icns"
  fi
  echo "   ✓ $app_dir"
}

mkdir -p "$CURSOR_LAUNCHERS"
for profile in $PROFILES; do
  make_launcher "$profile"
done

echo ""
echo "✅ Done. Source cursor-aliases.sh in your shell, then use: $(echo $PROFILES | sed 's/ / | /g')"
echo "   Icons: add <Name>.icns to cursor-profiles/icons/ and run this script again."
