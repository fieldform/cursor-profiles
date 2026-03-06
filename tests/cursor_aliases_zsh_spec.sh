#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

test_with_profiles_override() {
  local zdotdir result

  zdotdir="$(mktemp -d)"
  cat > "$zdotdir/.zshrc" <<EOF
export PROFILES="Spec"
export CURSOR_PROFILES_REPO_ROOT="$REPO_ROOT"
source "$REPO_ROOT/cursor-aliases.sh"
EOF

  result="$(HOME="$HOME" ZDOTDIR="$zdotdir" zsh -ic 'whence -w cursor-spec 2>/dev/null || true')"
  rm -rf "$zdotdir"

  [[ "$result" == "cursor-spec: function" ]] || {
    echo "FAIL: zsh should define cursor-spec from PROFILES" >&2
    exit 1
  }
}

test_with_repo_config() {
  local zdotdir result

  zdotdir="$(mktemp -d)"
  cat > "$zdotdir/.zshrc" <<EOF
export CURSOR_PROFILES_REPO_ROOT="$REPO_ROOT"
source "$REPO_ROOT/cursor-aliases.sh"
EOF

  result="$(HOME="$HOME" ZDOTDIR="$zdotdir" zsh -ic 'whence -w cursor-spireworks 2>/dev/null || true')"
  rm -rf "$zdotdir"

  [[ "$result" == "cursor-spireworks: function" ]] || {
    echo "FAIL: zsh should load profile functions from config.sh" >&2
    exit 1
  }
}

test_with_profiles_override
test_with_repo_config
echo "PASS"
