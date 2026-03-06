# Cursor profile launchers. Source from .bashrc / zshrc.
# Uses the launcher .app bundles so Dock shows correct name and icon.
# Pass a path or "." to open that folder: cursor-work .  or  cursor-personal ~/projects/foo

_cursor_script_path() {
  if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    printf '%s\n' "${BASH_SOURCE[0]}"
  elif [[ -n "${ZSH_VERSION:-}" ]]; then
    printf '%s\n' "$PWD"
  else
    printf '%s\n' "$0"
  fi
}

REPO_ROOT="${CURSOR_PROFILES_REPO_ROOT:-$(cd "$(dirname "$(_cursor_script_path)")" 2>/dev/null && pwd)}"
if [[ ! -f "$REPO_ROOT/config.sh" ]]; then
  for _cursor_candidate in "$HOME/cursor-profiles" "$HOME/opensource/cursor-profiles"; do
    if [[ -f "$_cursor_candidate/config.sh" ]]; then
      REPO_ROOT="$_cursor_candidate"
      break
    fi
  done
fi
PROFILES_OVERRIDE="${PROFILES-}"
[[ -f "$REPO_ROOT/config.sh" ]] && source "$REPO_ROOT/config.sh"
PROFILES="${PROFILES_OVERRIDE:-${PROFILES:-Personal Work}}"
_cursor_apps="${HOME}/Applications/Cursor"

_cursor_resolve_args() {
  local a r
  for a in "$@"; do
    if [[ "$a" == "." ]]; then
      r="$(pwd)"
    elif [[ "$a" != /* && "$a" != -* && "$a" != *://* ]]; then
      if [[ -e "$a" ]]; then
        r="$(cd -P "$(dirname "$a")" 2>/dev/null && pwd)/$(basename "$a")"
      else
        r="$a"
      fi
    else
      r="$a"
    fi
    printf '%s\0' "$r"
  done
}

_cursor_can_use_open_documents() {
  local a
  for a in "$@"; do
    [[ "$a" == /* && -e "$a" ]] || return 1
  done
}

# Generic: cursor-profile <ProfileName> [path]
cursor-profile() {
  local profile="$1"
  shift
  local resolved=()
  while IFS= read -r -d '' x; do resolved+=( "$x" ); done < <(_cursor_resolve_args "$@")
  if (( ${#resolved[@]} == 0 )); then
    open -a "$_cursor_apps/Cursor ${profile}.app"
  elif _cursor_can_use_open_documents "${resolved[@]}"; then
    open -n -a "$_cursor_apps/Cursor ${profile}.app" "${resolved[@]}"
  else
    open -n -a "$_cursor_apps/Cursor ${profile}.app" --args "${resolved[@]}"
  fi
}

_cursor_define_profile_functions() {
  local _p _fn

  eval "set -- $PROFILES"
  for _p in "$@"; do
    _fn="cursor-$(echo "$_p" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"
    eval "$_fn() { cursor-profile \"$_p\" \"\$@\"; }"
  done
}

# One function per profile (so you get cursor-personal, cursor-work, etc.)
_cursor_define_profile_functions
unset -f _cursor_define_profile_functions _cursor_script_path
unset PROFILES_OVERRIDE _cursor_candidate
