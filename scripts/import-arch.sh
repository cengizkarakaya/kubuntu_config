#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# Pinned reference; portable configurations are copied rather than dynamically linked across repos.
SRC="https://raw.githubusercontent.com/cengizkarakaya/Arch_Config/56c882afbd385a905b419193aa72520a688d56ea"
MAP=(
 "alacritty/.config/alacritty/alacritty.toml"
 "bat/.config/bat/config"
 "bottom/.config/bottom/bottom.toml"
 "git/.config/git/config"
 "helix/.config/helix/config.toml"
 "helix/.config/helix/languages.toml"
 "readline/.inputrc"
 "starship/.config/starship.toml"
 "yazi/.config/yazi/init.lua"
 "yazi/.config/yazi/keymap.toml"
 "yazi/.config/yazi/package.toml"
 "yazi/.config/yazi/theme.toml"
 "yazi/.config/yazi/yazi.toml"
 "zathura/.config/zathura/zathurarc"
 "zellij/.config/zellij/config.kdl"
)
mkdir -p "$ROOT/dotfiles"
for item in "${MAP[@]}"; do
 target="$ROOT/dotfiles/$item"; mkdir -p "$(dirname "$target")"
 if [[ ! -e "$target" ]]; then
  curl -fsSL --retry 3 "$SRC/$item" -o "$target.tmp"
  mv "$target.tmp" "$target"
 fi
done
# Yazi paths sometimes change across distributions; use command rather than hard-coded path
sed -i 's@/usr/bin/helix@hx@g' "$ROOT/dotfiles/yazi/.config/yazi/yazi.toml"
# Git config delta should only be installed when git-delta is present.
if ! command -v delta >/dev/null 2>&1; then
 echo "NOTE: git-delta not available; Git delta pager file will not be Stowed."
fi
# fixed Arch-specific logo in fastfetch deliberately not imported.
