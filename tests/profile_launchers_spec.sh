#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  [[ "$actual" == "$expected" ]] || fail "$message (expected '$expected', got '$actual')"
}

test_setup_writes_folder_document_type() {
  local tmp_dir fake_cursor_app fake_cursor_bin launchers_dir profiles_dir plist plist_dump

  tmp_dir="$(mktemp -d)"
  fake_cursor_app="$tmp_dir/Cursor.app"
  fake_cursor_bin="$fake_cursor_app/Contents/MacOS/Cursor"
  launchers_dir="$tmp_dir/launchers"
  profiles_dir="$tmp_dir/profiles"

  mkdir -p "$(dirname "$fake_cursor_bin")"
  cat > "$fake_cursor_bin" <<'EOF'
#!/bin/bash
exit 0
EOF
  chmod +x "$fake_cursor_bin"

  HOME="$tmp_dir/home" \
  PROFILES="Spec" \
  CURSOR_APP="$fake_cursor_app" \
  CURSOR_LAUNCHERS="$launchers_dir" \
  CURSOR_PROFILES_REPO="$profiles_dir" \
    "$REPO_ROOT/setup-cursor-profiles.sh" >/dev/null

  plist="$launchers_dir/Cursor Spec.app/Contents/Info.plist"
  plist_dump="$(plutil -p "$plist")"

  [[ "$plist_dump" == *'"public.folder"'* ]] || fail "launcher plist should advertise folder support"

  rm -rf "$tmp_dir"
}

test_alias_uses_native_open_for_existing_paths() {
  local tmp_dir capture_file project_dir launcher_path

  tmp_dir="$(mktemp -d)"
  capture_file="$tmp_dir/open-args.txt"
  project_dir="$tmp_dir/project"
  launcher_path="$tmp_dir/apps/Cursor Spec.app"

  mkdir -p "$project_dir"
  mkdir -p "$launcher_path"

  # shellcheck disable=SC1091
  source "$REPO_ROOT/cursor-aliases.sh"
  _cursor_apps="$tmp_dir/apps"

  open() {
    printf '%s\n' "$@" > "$capture_file"
  }

  cursor-profile "Spec" "$project_dir"

  mapfile -t args < "$capture_file"

  assert_eq "${args[0]}" "-n" "existing paths should open a new profile app instance"
  assert_eq "${args[1]}" "-a" "existing paths should use open -a"
  assert_eq "${args[2]}" "$launcher_path" "existing paths should target the profile launcher"
  assert_eq "${args[3]}" "$project_dir" "existing paths should be passed as open documents"

  if [[ " ${args[*]} " == *" --args "* ]]; then
    fail "existing paths should not be passed via --args"
  fi

  rm -rf "$tmp_dir"
}

test_alias_keeps_cli_args_on_args_channel() {
  local tmp_dir capture_file launcher_path

  tmp_dir="$(mktemp -d)"
  capture_file="$tmp_dir/open-args.txt"
  launcher_path="$tmp_dir/apps/Cursor Spec.app"

  mkdir -p "$launcher_path"

  # shellcheck disable=SC1091
  source "$REPO_ROOT/cursor-aliases.sh"
  _cursor_apps="$tmp_dir/apps"

  open() {
    printf '%s\n' "$@" > "$capture_file"
  }

  cursor-profile "Spec" "--wait"

  mapfile -t args < "$capture_file"

  assert_eq "${args[0]}" "-n" "cli args should still open a new profile app instance"
  assert_eq "${args[1]}" "-a" "cli args should use open -a"
  assert_eq "${args[2]}" "$launcher_path" "cli args should target the profile launcher"
  assert_eq "${args[3]}" "--args" "cli args should stay on the args channel"
  assert_eq "${args[4]}" "--wait" "cli args should be forwarded unchanged"

  rm -rf "$tmp_dir"
}

test_setup_writes_folder_document_type
test_alias_uses_native_open_for_existing_paths
test_alias_keeps_cli_args_on_args_channel

echo "PASS"
