#!/usr/bin/env bash
# Offline private capture and portability; never stages or publishes to GitHub.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
export HOME="$tmp/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
mkdir -p "$XDG_CONFIG_HOME/menus" "$XDG_DATA_HOME/applications" "$XDG_DATA_HOME/desktop-directories"
printf '[Desktop Entry]\nType=Application\nName=Science Test\nExec=%s/.local/bin/tool\nTryExec=%s/.local/bin/tool\nIcon=%s/icon.png\nPath=%s/work\n' "$HOME" "$HOME" "$HOME" "$HOME" > "$XDG_DATA_HOME/applications/science-test.desktop"
printf '<Menu><Name>Applications</Name></Menu>\n' > "$XDG_CONFIG_HOME/menus/applications-kmenuedit.menu"
printf '[Desktop Entry]\nType=Directory\nName=Science\n' > "$XDG_DATA_HOME/desktop-directories/Science.directory"
bash "$ROOT/scripts/menu-backup.sh" --capture > "$tmp/out"
state="$XDG_STATE_HOME/kubuntu-config"
snap="$state/menu-current"
test -f "$snap/.local/share/applications/science-test.desktop"
test -f "$snap/.local/share/desktop-directories/Science.directory"
test -f "$snap/.config/menus/applications-kmenuedit.menu"
grep -q 'This is NOT on GitHub' "$tmp/out"
test "$(stat -c %a "$snap")" = 700
if bash "$ROOT/scripts/menu-backup.sh" --stage-repo > "$tmp/stage" 2>&1; then
  echo '[FAIL] Public staging accepted'; exit 1
fi
grep -q 'Public staging is disabled' "$tmp/stage"
if XDG_STATE_HOME="$ROOT" bash "$ROOT/scripts/menu-backup.sh" --capture > "$tmp/inside" 2>&1; then
  echo '[FAIL] In-repo private capture accepted'; exit 1
fi
bash "$ROOT/scripts/menu-backup.sh" --prepare-private
portable="$state/menu-portable"
raw="$portable/.local/share/applications/science-test.desktop"
test "$(stat -c %a "$portable")" = 700
grep -Fq 'Exec=@HOME@/.local/bin/tool' "$raw"
grep -Fq 'TryExec=@HOME@/.local/bin/tool' "$raw"
grep -Fq "Exec=$HOME/.local/bin/tool" "$snap/.local/share/applications/science-test.desktop"
newhome="$tmp/new-user"
newstate="$newhome/.state"
mkdir -p "$newstate/kubuntu-config"
cp -a "$portable" "$newstate/kubuntu-config/menu-portable"
HOME="$newhome" XDG_STATE_HOME="$newstate" XDG_CONFIG_HOME="$newhome/.config" XDG_DATA_HOME="$newhome/.local/share" bash "$ROOT/scripts/menu-backup.sh" --plan-restore > "$tmp/plan"
grep -Fq "@HOME@ -> $newhome" "$tmp/plan"
test ! -e "$newhome/.local"
test ! -e "$newhome/.config"
# Exercise restore rendering directly; wrapper requires a TTY.
dest="$newhome/.local/share/applications/science-test.desktop"
mkdir -p "$(dirname "$dest")"
printf 'original\n' > "$dest"
python3 "$ROOT/scripts/menu-snapshot.py" restore "$portable" "$newhome" --backup "$tmp/backup"
grep -Fq "Exec=$newhome/.local/bin/tool" "$dest"
grep -Fq "TryExec=$newhome/.local/bin/tool" "$dest"
grep -Fq "Icon=$newhome/icon.png" "$dest"
grep -Fq "Path=$newhome/work" "$dest"
grep -Fxq original "$tmp/backup/.local/share/applications/science-test.desktop"
python3 "$ROOT/scripts/menu-snapshot.py" plan "$portable" "$newhome" > "$tmp/again"
grep -Fxq 'Changed/needed: 0' "$tmp/again"
rm "$dest"
ln -s "$tmp/out" "$dest"
if python3 "$ROOT/scripts/menu-snapshot.py" restore "$portable" "$newhome" --backup "$tmp/backup" > /dev/null 2>&1; then
  echo '[FAIL] Symlink restore was accepted' >&2; exit 1
fi
test ! -e "$ROOT/backups/application-launcher/snapshot"
echo '[PASS] Private capture and preparation, no public staging, portable rendering, read-only preview, conflict backup, idempotency and symlink rejection'
