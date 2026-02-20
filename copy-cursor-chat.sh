#!/bin/bash
# Copy Cursor chat history between profiles or from default Cursor data.
# Usage: copy-cursor-chat.sh <source_path> <source_profile> <target_profile> [target_path]
#        copy-cursor-chat.sh --list [profile] [--match substring]
# Source profile can be 'default' for main Cursor data (no profile launcher).
# Close Cursor before running to avoid DB corruption.

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$REPO_ROOT/config.sh" ]] && source "$REPO_ROOT/config.sh"
PROFILES="${PROFILES:-Personal Work}"
CURSOR_PROFILES="$REPO_ROOT/cursor-profiles"
if [[ "$(uname)" == Darwin ]]; then
  CURSOR_DEFAULT_WS="${HOME}/Library/Application Support/Cursor/User/workspaceStorage"
else
  CURSOR_DEFAULT_WS="${XDG_CONFIG_HOME:-$HOME/.config}/Cursor/User/workspaceStorage"
fi

usage() {
  echo "Usage: $0 <source_repo_path> <source_profile> <target_profile> [target_repo_path]"
  echo "       $0 --list [profile] [--match substring]"
  echo ""
  echo "Copy: source_profile and target_profile = $PROFILES, or source = 'default'"
  echo "List: --list <profile> or --list default; optional --match <substring>"
  echo ""
  echo "Example: $0 ~/myproject Personal Work"
  echo "Example: $0 'vscode-remote://...nixos-config' default Personal"
  echo "Example: $0 --list default --match nixos"
  exit 1
}

# --list [profile] [--match substring]
if [[ "$1" == "--list" ]]; then
  shift
  LIST_PROFILE="Personal"
  MATCH=""
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--match" ]]; then
      shift
      MATCH="${1:-}"
      shift
    else
      LIST_PROFILE="$1"
      shift
    fi
  done
  if [[ "$LIST_PROFILE" == "default" ]]; then
    LIST_WS="$CURSOR_DEFAULT_WS"
  else
    LIST_WS="$CURSOR_PROFILES/$LIST_PROFILE/config/User/workspaceStorage"
  fi
  if [[ ! -d "$LIST_WS" ]]; then
    echo "Workspace storage not found: $LIST_WS"
    exit 1
  fi
  echo "Workspaces in '$LIST_PROFILE':"
  echo ""
  for dir in "$LIST_WS"/*/; do
    wj="${dir}workspace.json"
    [[ ! -f "$wj" ]] && continue
    folder="$(sed -n 's/.*"folder"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$wj")"
    workspace="$(sed -n 's/.*"workspace"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$wj")"
    path=""
    if [[ -n "$folder" ]]; then
      path="$(echo "$folder" | sed 's|^file://||;s|%20| |g;s|%2F|/|g')"
    elif [[ -n "$workspace" ]]; then
      path="$(echo "$workspace" | sed 's|^file://||;s|%20| |g;s|%2F|/|g')"
    fi
    [[ -z "$path" ]] && continue
    if [[ -n "$MATCH" ]]; then
      echo "$path" | grep -qi "$MATCH" || continue
    fi
    echo "  $path"
    echo "    → use: $0 \"$path\" $LIST_PROFILE <target_profile>"
    echo ""
  done
  exit 0
fi

if [[ $# -lt 3 ]]; then
  usage
fi

resolve_path() {
  local r="${1/#\~/$HOME}"
  [[ -d "$r" ]] && r="$(cd "$r" && pwd)"
  echo "$r"
}
REPO_RAW="$1"
REPO_ABS="$(resolve_path "$REPO_RAW")"
SOURCE_PROFILE="$2"
TARGET_PROFILE="$3"
TARGET_REPO_RAW="${4:-}"
if [[ -n "$TARGET_REPO_RAW" ]]; then
  TARGET_REPO_ABS="$(resolve_path "$TARGET_REPO_RAW")"
else
  TARGET_REPO_ABS="$REPO_ABS"
fi

for p in $PROFILES; do
  [[ "$TARGET_PROFILE" == "$p" ]] && target_ok=1
done
[[ "$SOURCE_PROFILE" == "default" ]] && source_ok=1
for p in $PROFILES; do
  [[ "$SOURCE_PROFILE" == "$p" ]] && source_ok=1
done
if [[ -z "$source_ok" ]]; then
  echo "Source profile must be one of: $PROFILES or 'default'"
  usage
fi
if [[ -z "$target_ok" ]]; then
  echo "Target profile must be one of: $PROFILES"
  usage
fi
if [[ "$SOURCE_PROFILE" == "$TARGET_PROFILE" ]]; then
  echo "Source and target profile must differ."
  usage
fi

if [[ "$SOURCE_PROFILE" == "default" ]]; then
  SOURCE_WS="$CURSOR_DEFAULT_WS"
else
  SOURCE_WS="$CURSOR_PROFILES/$SOURCE_PROFILE/config/User/workspaceStorage"
fi
TARGET_WS="$CURSOR_PROFILES/$TARGET_PROFILE/config/User/workspaceStorage"

if [[ ! -d "$SOURCE_WS" ]]; then
  echo "Source workspace storage not found: $SOURCE_WS"
  exit 1
fi
if [[ ! -d "$TARGET_WS" ]]; then
  echo "Target workspace storage not found: $TARGET_WS"
  echo "Run setup-cursor-profiles.sh and open that folder once in the target profile."
  exit 1
fi

decode_path() { echo "$1" | sed 's|^file://||;s|%20| |g;s|%2F|/|g'; }
normalize_uri() { echo "$1" | sed 's/+/%2B/g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }
find_uuid_for_path() {
  local ws_dir="$1"
  local path_abs="$2"
  local path_abs_norm
  path_abs_norm="$(normalize_uri "$path_abs")"
  for dir in "$ws_dir"/*/; do
    wj="${dir}workspace.json"
    [[ ! -f "$wj" ]] && continue
    folder="$(sed -n 's/.*"folder"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$wj")"
    workspace="$(sed -n 's/.*"workspace"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$wj")"
    path=""
    [[ -n "$folder" ]] && path="$(decode_path "$folder")"
    [[ -z "$path" && -n "$workspace" ]] && path="$(decode_path "$workspace")"
    [[ -z "$path" ]] && continue
    p="${path%/}"
    p_norm="$(normalize_uri "$p")"
    if [[ "$p_norm" == "$path_abs_norm" ]]; then
      echo "$(basename "$dir")"
      return
    fi
  done
}

SOURCE_UUID="$(find_uuid_for_path "$SOURCE_WS" "$REPO_ABS")"
if [[ -z "$SOURCE_UUID" ]]; then
  echo "No workspace found in profile '$SOURCE_PROFILE'. Run: $0 --list $SOURCE_PROFILE --match <substring>"
  exit 1
fi

TARGET_UUID="$(find_uuid_for_path "$TARGET_WS" "$TARGET_REPO_ABS")"
if [[ -z "$TARGET_UUID" ]]; then
  echo "No workspace found in profile '$TARGET_PROFILE'. Open that folder once in Cursor (target profile), then run again."
  exit 1
fi

SOURCE_DIR="$SOURCE_WS/$SOURCE_UUID"
TARGET_DIR="$TARGET_WS/$TARGET_UUID"
SAME_PATH=false
[[ "$REPO_ABS" == "$TARGET_REPO_ABS" ]] && SAME_PATH=true

echo "Source: $SOURCE_PROFILE  $REPO_ABS  (uuid $SOURCE_UUID)"
echo "Target: $TARGET_PROFILE  $TARGET_REPO_ABS  (uuid $TARGET_UUID)"
echo ""

if [[ -d "$TARGET_DIR" && -f "$TARGET_DIR/state.vscdb" ]]; then
  echo "Backing up target state.vscdb..."
  cp -a "$TARGET_DIR/state.vscdb" "$TARGET_DIR/state.vscdb.bak.$(date +%Y%m%d%H%M%S)"
fi

mkdir -p "$TARGET_DIR"
if [[ "$SAME_PATH" == "true" ]]; then
  cp -a "$SOURCE_DIR/workspace.json" "$TARGET_DIR/"
fi
cp -a "$SOURCE_DIR/state.vscdb" "$TARGET_DIR/" 2>/dev/null || true
[[ -f "$SOURCE_DIR/state.vscdb.backup" ]] && cp -a "$SOURCE_DIR/state.vscdb.backup" "$TARGET_DIR/" || true
[[ -d "$SOURCE_DIR/images" ]] && cp -a "$SOURCE_DIR/images" "$TARGET_DIR/" || true

echo "Done. Quit Cursor, then reopen the repo in profile $TARGET_PROFILE to see chat history."
