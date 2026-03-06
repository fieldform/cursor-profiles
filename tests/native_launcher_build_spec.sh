#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

SWIFTC_BIN="${SWIFTC_BIN:-}"
MACOS_SDK_PATH="${MACOS_SDK_PATH:-}"
if [[ -z "$SWIFTC_BIN" ]] && command -v xcrun >/dev/null 2>&1; then
  SWIFTC_BIN="$(xcrun --find swiftc 2>/dev/null || true)"
fi
if [[ -z "$MACOS_SDK_PATH" ]] && command -v xcrun >/dev/null 2>&1; then
  MACOS_SDK_PATH="$(xcrun --show-sdk-path --sdk macosx 2>/dev/null || true)"
fi

[[ -n "$SWIFTC_BIN" && -x "$SWIFTC_BIN" ]] || {
  echo "FAIL: swiftc not found" >&2
  exit 1
}
[[ -n "$MACOS_SDK_PATH" && -d "$MACOS_SDK_PATH" ]] || {
  echo "FAIL: macOS SDK not found" >&2
  exit 1
}

SDKROOT="$MACOS_SDK_PATH" "$SWIFTC_BIN" \
  -O \
  -framework AppKit \
  -framework Foundation \
  "$REPO_ROOT/native-launcher/Launcher.swift" \
  -o "$TMP_DIR/Launcher"

[[ -x "$TMP_DIR/Launcher" ]] || {
  echo "FAIL: compiled launcher binary missing" >&2
  exit 1
}

echo "PASS"
