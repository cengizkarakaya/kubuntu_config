#!/usr/bin/env bash
# Offline private capture; never stages or publishes anything to GitHub.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
export HOME="$tmp/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
mkdir -p "$XDG_CONFIG_HOME/menus" "$XDG_DATA_HOME/applications" "$XDG_DATA_HOME/desktop-directories"
printf '[Desktop Entry]\nType=Application\nName=Science Test\nExec=/bin/true\n' > "$XDG_DATA_HOME/applications/science-test.desktop"
printf '<Menu><Name>Applications</Name></Menu>\n' > "$XDG_CONFIG_HOME/menus/applications-kmenuedit.menu"
printf '[Desktop Entry]\nType=Directory\nName=Science\n' > "$XDG_DATA_HOME/desktop-directories/Science.directory"
bash "$ROOT/scripts/menu-backup.sh" --capture > "$tmp/out"
snap="$XDG_STATE_HOME/kubuntu-config/menu-current"
test -f "$snap/.local/share/applications/science-test.desktop"
test -f "$snap/.local/share/desktop-directories/Science.directory"
test -f "$snap/.config/menus/applications-kmenuedit.menu"
grep -q 'This is NOT on GitHub' "$tmp/out"
echo '[PASS] Menu snapshot private by default; no direct repository publish'

# Use a disposable repository copy; never stage the actual repository.
copy="$tmp/repo"
mkdir -p "$copy/scripts" "$copy/backups/application-launcher/snapshot/.local/share/applications"
cp "$ROOT/scripts/menu-backup.sh" "$ROOT/scripts/menu-snapshot.py" "$copy/scripts/"
public="$copy/backups/application-launcher/snapshot"
raw="$public/.local/share/applications/example.desktop"
printf '[Desktop Entry]\nExec=%s/.local/bin/tool\nTryExec=%s/.local/bin/tool\nIcon=%s/icon.png\nPath=%s/work\n' "$HOME" "$HOME" "$HOME" "$HOME" > "$raw"
python3 "$copy/scripts/menu-snapshot.py" template "$public" "$HOME"
grep -Fq 'Exec=@HOME@/.local/bin/tool' "$raw"
grep -Fq 'TryExec=@HOME@/.local/bin/tool' "$raw"
newhome="$tmp/new-user"
mkdir -p "$newhome"
HOME="$newhome" XDG_STATE_HOME="$newhome/.state" bash "$copy/scripts/menu-backup.sh" --plan-restore > "$tmp/plan"
grep -Fq "@HOME@ -> $newhome" "$tmp/plan"
test -z "$(find "$newhome" -mindepth 1 -print -quit)"
# Exercise the rendering implementation directly; shell restore still requires a TTY.
dest="$newhome/.local/share/applications/example.desktop"
mkdir -p "$(dirname "$dest")"
printf 'original\n' > "$dest"
python3 "$copy/scripts/menu-snapshot.py" restore "$public" "$newhome" --backup "$tmp/backup"
grep -Fq "Exec=$newhome/.local/bin/tool" "$dest"
grep -Fq "TryExec=$newhome/.local/bin/tool" "$dest"
grep -Fq "Icon=$newhome/icon.png" "$dest"
grep -Fq "Path=$newhome/work" "$dest"
grep -Fxq original "$tmp/backup/.local/share/applications/example.desktop"
python3 "$copy/scripts/menu-snapshot.py" plan "$public" "$newhome" > "$tmp/again"
grep -Fxq 'Changed/needed: 0' "$tmp/again"
rm "$dest"
ln -s "$tmp/out" "$dest"
if python3 "$copy/scripts/menu-snapshot.py" restore "$public" "$newhome" --backup "$tmp/backup" > /dev/null 2>&1; then
  echo '[FAIL] Symlink restore was accepted' >&2; exit 1
fi
grep -q 'This is NOT on GitHub' "$tmp/out"
if grep -rEn '/home/[A-Za-z0-9._-]+' "$ROOT/backups/application-launcher/snapshot"; then
  echo '[FAIL] Absolute home path remains in reviewed snapshot' >&2; exit 1
fi
echo '[PASS] Portable launcher rendering, read-only preview, conflict backup, idempotency and symlink rejection'
