# Cursor Profiles

Separate Cursor settings and accounts per profile (e.g. Personal vs Work). Each profile gets its own config directory and optional macOS launcher app with a distinct name and icon.

Based on [Seamless account switching in Cursor](https://forum.cursor.com/t/seamless-account-switching-in-cursor/58411/13).

## Quick start

1. **Clone this repo** (or copy the folder) somewhere, e.g. `~/cursor-profiles`.
2. **Edit profile names** in `config.sh` if you want (default: `Personal`, `Work`).
3. **Run setup** (macOS):
   ```bash
   cd ~/cursor-profiles
   ./setup-cursor-profiles.sh
   ```
   This creates profile config dirs and launcher apps in `~/Applications/Cursor/` (e.g. "Cursor Personal.app", "Cursor Work.app").
4. **Source the aliases** in your shell so you can run `cursor-personal`, `cursor-work`, etc.:
   ```bash
   # In ~/.zshrc or ~/.bashrc add (adjust path to where you cloned):
   [ -f ~/cursor-profiles/cursor-aliases.sh ] && . ~/cursor-profiles/cursor-aliases.sh
   ```

## Usage

- **CLI:** `cursor-personal`, `cursor-work` (or whatever names you set in `config.sh`). Pass a path to open that folder: `cursor-work .` or `cursor-personal ~/projects/myapp`.
- **Launchers:** Use the apps in `~/Applications/Cursor/` from Spotlight or the Dock; each opens Cursor with that profile’s data dir.

## Icons

Launcher apps use profile-specific icons if present: put `<ProfileName>.icns` in `cursor-profiles/icons/` (e.g. `Personal.icns`, `Work.icns`), then run `./setup-cursor-profiles.sh` again.

- **From a PNG:** Put a 1024×1024 PNG in `cursor-profiles/icons/<Name>.png`, then run `./png-to-icns.sh <Name>` (macOS only).
- **Simple letter icons:** Run `./create-cursor-profile-icons.sh` (requires ImageMagick). It creates basic letter icons; edit the script to change letters/colours.

## Migrating chat history

Chat is stored per-workspace. To copy history from one profile to another (or from default Cursor into a profile):

```bash
./copy-cursor-chat.sh <source_path> <source_profile> <target_profile> [target_path]
```

- Use **`default`** as source to copy from the main Cursor data path (when you weren’t using profile launchers).
- List workspaces to get exact paths: `./copy-cursor-chat.sh --list default --match nixos`
- Close Cursor before running. If the target profile uses a different Cursor account, the UI may hang on "Loading Chat…"; use the chat panel "…" → Clear All Chats to reset.

See the script’s `--list` output for exact paths.

## Layout

- `config.sh` — profile names (edit and re-run setup).
- `setup-cursor-profiles.sh` — creates profile dirs and launcher apps.
- `copy-cursor-chat.sh` — copy workspace chat between profiles or from default.
- `cursor-aliases.sh` — shell helpers; source from `.zshrc`/`.bashrc`.
- `cursor-profiles/` — profile config dirs (created by setup) and `icons/`.
- `create-cursor-profile-icons.sh`, `png-to-icns.sh` — optional icon helpers.

## License

Use and adapt as you like. No warranty.
