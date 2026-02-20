#!/bin/bash
# Convert a 1024×1024 PNG to macOS .icns (no ImageMagick).
# Usage: png-to-icns.sh <name>   → reads cursor-profiles/icons/<name>.png, creates <name>.icns

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICONS_DIR="$REPO_ROOT/cursor-profiles/icons"
name="$1"
if [[ -z "$name" ]]; then
  echo "Usage: $0 <name>   (e.g. Personal, Work)"
  exit 1
fi
src="$ICONS_DIR/${name}.png"
if [[ ! -f "$src" ]]; then
  echo "Missing: $src (use a 1024×1024 PNG)"
  exit 1
fi
iconset="$ICONS_DIR/${name}.iconset"
rm -rf "$iconset"
mkdir -p "$iconset"
for size in 16 32 128 256 512; do
  sips -z $size $size -s format png "$src" --out "$iconset/icon_${size}x${size}.png"
done
for size in 16 32 128 256 512; do
  d=$((size * 2))
  sips -z $d $d -s format png "$src" --out "$iconset/icon_${size}x${size}@2x.png"
done
iconutil -c icns "$iconset" -o "$ICONS_DIR/${name}.icns"
rm -rf "$iconset"
echo "Created $ICONS_DIR/${name}.icns. Run ./setup-cursor-profiles.sh to apply."
