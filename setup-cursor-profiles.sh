#!/bin/bash
# Create Cursor profile dirs and optional GUI launcher apps.
# Edit config.sh to change profile names, then run this script.
# See: https://forum.cursor.com/t/seamless-account-switching-in-cursor/58411/13

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$REPO_ROOT/config.sh" ]] && source "$REPO_ROOT/config.sh"
PROFILES="${PROFILES:-Personal Work}"
CURSOR_PROFILES_REPO="$REPO_ROOT/cursor-profiles"
CURSOR_LAUNCHERS="${HOME}/Applications/Cursor"
CURSOR_APP="/Applications/Cursor.app"
CURSOR_BIN="${CURSOR_APP}/Contents/MacOS/Cursor"

if [[ ! -x "$CURSOR_BIN" ]]; then
  echo "⚠️  Cursor not found at $CURSOR_APP. Install Cursor first."
  exit 1
fi

echo "🛠️  Cursor profiles (in repo: $CURSOR_PROFILES_REPO)"
echo "    Profiles: $PROFILES"
echo ""

for profile in $PROFILES; do
  mkdir -p "$CURSOR_PROFILES_REPO/$profile/config/extensions"
  echo "   ✓ $CURSOR_PROFILES_REPO/$profile/config"
done

make_launcher() {
  local profile="$1"
  local app_name="Cursor ${profile}"
  local app_dir="$CURSOR_LAUNCHERS/${app_name}.app"
  local user_data_dir="$CURSOR_PROFILES_REPO/$profile/config"
  local extensions_dir="$user_data_dir/extensions"

  mkdir -p "$app_dir/Contents/MacOS"
  mkdir -p "$app_dir/Contents/Resources"

  cat > "$app_dir/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Launcher</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.cursor.$(echo "$profile" | tr '[:upper:]' '[:lower:]' | tr -d ' ')</string>
    <key>CFBundleName</key>
    <string>${app_name}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

  cat > "$app_dir/Contents/MacOS/Launcher" << LAUNCHER
#!/bin/bash
# Run Cursor as child so this .app stays the process owner (better restore-after-reboot).
# No stdio redirection so remote/SSH sessions don't hang on disconnected pipes.
"$CURSOR_BIN" \\
  --user-data-dir="$user_data_dir" \\
  --extensions-dir="$extensions_dir" \\
  --new-window \\
  "\$@"
LAUNCHER
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
