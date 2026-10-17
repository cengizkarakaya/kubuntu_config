#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# Remove ONLY dangling symlinks pointing to files retired from THIS repository.
# Preserve regular files, symlinks targeting other trees and user-installed add-ons.
for leaf in package.toml init.lua theme.toml; do
  link="$HOME/.config/yazi/$leaf"
  retired="$ROOT/dotfiles/yazi/.config/yazi/$leaf"
  if [[ -L "$link" && "$(readlink -m -- "$link")" == "$retired" ]]; then
    rm -- "$link"
    echo "[INFO] Removed obsolete repository-managed symlink: $link"
  fi
done
echo '[OK] No user files or application extensions removed'
