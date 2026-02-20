# Cursor profile launchers. Source from .bashrc / zshrc.
# Uses the launcher .app bundles so Dock shows correct name and icon.
# Pass a path or "." to open that folder: cursor-work .  or  cursor-personal ~/projects/foo

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
[[ -f "$REPO_ROOT/config.sh" ]] && source "$REPO_ROOT/config.sh"
PROFILES="${PROFILES:-Personal Work}"
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

# Generic: cursor-profile <ProfileName> [path]
cursor-profile() {
  local profile="$1"
  shift
  local resolved=()
  while IFS= read -r -d '' x; do resolved+=( "$x" ); done < <(_cursor_resolve_args "$@")
  open -a "$_cursor_apps/Cursor ${profile}.app" --args "${resolved[@]}"
}

# One function per profile (so you get cursor-personal, cursor-work, etc.)
for _p in $PROFILES; do
  _fn="cursor-$(echo "$_p" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"
  eval "$_fn() { cursor-profile \"$_p\" \"\$@\"; }"
done
unset _p _fn
