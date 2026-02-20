# Cursor Profiles

Separate Cursor settings and accounts per profile (e.g. Personal vs Work). Each profile gets its own config directory and optional macOS launcher app with a distinct name and icon.

Based on [Seamless account switching in Cursor](https://forum.cursor.com/t/seamless-account-switching-in-cursor/58411/13).

## Quick start

1. **Clone this repo** (or copy the folder) somewhere, e.g. `~/cursor-profiles`.
2. **Edit profile names** in `config.sh` if you want. Default example: `Personal`, `Spireworks`, `Durst` (with matching P/S/D icons included).
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

- **CLI:** `cursor-personal`, `cursor-spireworks`, `cursor-durst` (or whatever names you set in `config.sh`). Pass a path to open that folder: `cursor-spireworks .` or `cursor-personal ~/projects/myapp`.
- **Launchers:** Use the apps in `~/Applications/Cursor/` from Spotlight or the Dock; each opens Cursor with that profile’s data dir.

## Icons

This repo includes example icons for Personal (P, blue), Spireworks (S, green), and Durst (D, orange) in `cursor-profiles/icons/` (`.icns` + source `.png`). Run `./setup-cursor-profiles.sh` to apply them to the launcher apps.

- **Your own icons:** Put `<ProfileName>.icns` in `cursor-profiles/icons/`, or a 1024×1024 `<Name>.png` and run `./png-to-icns.sh <Name>` (macOS only).
- **Regenerate letter icons:** Run `./create-cursor-profile-icons.sh` (requires ImageMagick). Edit the script to change letters/colours per profile.

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
