#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
command -v stow >/dev/null || { echo "stow missing"; exit 1; }
cd "$ROOT/dotfiles"
for module in alacritty bat bottom helix readline starship yazi zathura zellij git; do
 [[ -d "$module" ]] || continue
 if [[ "$module" == git ]] && ! command -v delta >/dev/null 2>&1; then continue; fi
 # Never blindly overwrite user-owned files; conflicts are reported.
 if ! stow --no-folding -n -v -t "$HOME" "$module" >/dev/null 2>&1; then
   echo "CONFLICT: $module has existing files in HOME; back up/migrate manually."
   continue
 fi
 stow --no-folding -t "$HOME" "$module"
done
