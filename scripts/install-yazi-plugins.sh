#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
for cmd in yazi ya git rg fzf zoxide; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "[FAIL] Required for Arch Yazi workflow: $cmd" >&2; exit 1; }
done
# Kubuntu's 'bat' package installs the executable under the name 'batcat'.
if ! command -v bat >/dev/null 2>&1 && ! command -v batcat >/dev/null 2>&1; then
  echo '[FAIL] Yazi search preview requires bat or batcat (APT package: bat)' >&2
  exit 1
fi
src="$ROOT/dotfiles/yazi/.config/yazi/package.toml"
installed_manifest="$HOME/.config/yazi/package.toml"
[[ -s "$src" ]] || { echo '[FAIL] Pinned Arch Yazi plugin manifest missing' >&2; exit 1; }
[[ -L "$installed_manifest" && "$(readlink -f -- "$installed_manifest")" == "$(readlink -f -- "$src")" ]] || {
  echo '[FAIL] Yazi manifest is not Stow-linked to this repository; fix collision safely' >&2; exit 1;
}
# A pinned package.toml installs the Arch plugin + flavor revisions, not latest HEAD.
ya pkg install
while IFS= read -r name; do
  [[ -d "$HOME/.config/yazi/plugins/$name.yazi" ]] || {
    echo "[FAIL] Yazi plugin not installed: $name" >&2; exit 1;
  }
done < <(sed -n 's/^use = "yazi-rs\/plugins:\([^"]*\)"/\1/p' "$src")
[[ -d "$HOME/.config/yazi/flavors/nord.yazi" ]] || {
  echo '[FAIL] Yazi Nord flavor not installed' >&2; exit 1;
}
[[ -x "$HOME/.local/bin/yazi-rg" ]] || { echo '[FAIL] Yazi rg/fzf helper missing' >&2; exit 1; }
echo '[OK] Pinned Arch Yazi plugins, Nord flavor and search helper installed'
