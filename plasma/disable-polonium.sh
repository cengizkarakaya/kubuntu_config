#!/usr/bin/env bash
set -Eeuo pipefail

# Undo only the legacy user-installed Polonium tiler. Keep KWin shortcuts,
# monitors, Nord appearance, other scripts, and NVIDIA settings untouched.
command -v kwriteconfig6 >/dev/null || {
  echo '[FAIL] kwriteconfig6 is required' >&2
  exit 1
}

backup_dir="$HOME/.local/state/kubuntu-config/backups"
mkdir -p "$backup_dir"
if [[ -f "$HOME/.config/kwinrc" ]]; then
  backup="$backup_dir/kwinrc-before-native-kwin-$(date +%Y%m%d-%H%M%S)-$$.bak"
  cp -p -- "$HOME/.config/kwinrc" "$backup"
  echo "[INFO] Backed up kwinrc: $backup"
fi

kwriteconfig6 --file kwinrc --group Plugins --key poloniumEnabled false
installed="${XDG_DATA_HOME:-$HOME/.local/share}/kwin/scripts/polonium"
if [[ -d "$installed" ]]; then
  command -v kpackagetool6 >/dev/null || {
    echo '[FAIL] Polonium exists, but kpackagetool6 is unavailable' >&2
    exit 1
  }
  kpackagetool6 -t KWin/Script -r polonium
  [[ ! -d "$installed" ]] || { echo '[FAIL] Polonium still installed' >&2; exit 1; }
  echo '[OK] Uninstalled user-local Polonium'
else
  echo '[OK] User-local Polonium absent'
fi
echo '[OK] Native KWin selected. Sign out and in to refresh the session.'
