#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/dotfiles"
failed=()
for module in alacritty bat bottom fastfetch git helix herdr readline starship yazi; do
  [[ -d "$module" ]] || { failed+=("$module [not provided]"); continue; }
  if ! stow --no-folding -n --restow -t "$HOME" "$module" >/dev/null 2>&1; then
    failed+=("$module [HOME collision; never overwrite]"); continue
  fi
  if ! stow --no-folding --restow -t "$HOME" "$module"; then
    failed+=("$module [stow operation failed]")
  fi
done
if (("${#failed[@]}")); then
  printf '[FAIL] Unmanaged Stow collisions / failures; nothing was overwritten:\n' >&2
  printf ' - %s\n' "${failed[@]}" >&2
  exit 1
fi
echo '[OK] Dotfiles symlinked via Stow'
