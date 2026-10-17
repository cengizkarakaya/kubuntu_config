#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT/dotfiles"
failed=()
for module in alacritty bat bottom fastfetch git helix readline starship yazi zathura zellij; do
  [[ -d "$module" ]] || { failed+=("$module [not vendored]"); continue; }
  if ! stow --no-folding -n --restow -t "$HOME" "$module" >/dev/null 2>&1; then
    failed+=("$module [unmanaged HOME collision]"); continue
  fi
  stow --no-folding --restow -t "$HOME" "$module"
done
if (("${#failed[@]}" > 0)); then
  printf '[WARN] Stow conflicts; no files overwritten:\n'
  printf ' - %s\n' "${failed[@]}"
  exit 1
fi
