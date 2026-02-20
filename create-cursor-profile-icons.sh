#!/bin/bash
# Generate simple letter .icns icons for Cursor profile launchers.
# Requires: ImageMagick (brew install imagemagick), macOS iconutil.
# Edit the make_icon calls below to set letter and colour per profile.

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$REPO_ROOT/config.sh" ]] && source "$REPO_ROOT/config.sh"
PROFILES="${PROFILES:-Personal Work}"
ICONS_DIR="$REPO_ROOT/cursor-profiles/icons"
SIZE=1024

if ! command -v convert &>/dev/null; then
  echo "ImageMagick required: brew install imagemagick"
  exit 1
fi

mkdir -p "$ICONS_DIR"
cd "$ICONS_DIR"

make_icon() {
  local name="$1"
  local letter="$2"
  local bg="$3"
  local iconset="${name}.iconset"
  rm -rf "$iconset"
  mkdir -p "$iconset"
  for logical in 16 32 128 256 512; do
    convert -size ${logical}x${logical} "xc:$bg" -gravity center -pointsize $((logical * 5 / 8)) -fill white -font Helvetica-Bold -annotate 0 "$letter" "$iconset/icon_${logical}x${logical}.png"
  done
  for logical in 16 32 128 256 512; do
    pixel=$((logical * 2))
    convert -size ${pixel}x${pixel} "xc:$bg" -gravity center -pointsize $((pixel * 5 / 8)) -fill white -font Helvetica-Bold -annotate 0 "$letter" "$iconset/icon_${logical}x${logical}@2x.png"
  done
  iconutil -c icns "$iconset" -o "$ICONS_DIR/${name}.icns"
  rm -rf "$iconset"
  echo "   ✓ $ICONS_DIR/${name}.icns"
}

# Letter and background hex colour per profile (edit as needed)
# Example: Personal = P blue, Spireworks = S green, Durst = D orange
for profile in $PROFILES; do
  case "$profile" in
    Personal)   make_icon "$profile" "P" "#2563eb" ;;
    Spireworks) make_icon "$profile" "S" "#059669" ;;
    Durst)      make_icon "$profile" "D" "#ea580c" ;;
    *)          make_icon "$profile" "$(echo "$profile" | cut -c1)" "#64748b" ;;
  esac
done

echo ""
echo "Run ./setup-cursor-profiles.sh to apply icons to launcher apps."
