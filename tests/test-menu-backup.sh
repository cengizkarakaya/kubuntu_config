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
