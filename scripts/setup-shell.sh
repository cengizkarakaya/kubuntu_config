#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
mkdir -p "$HOME/.config/kubuntu-config"
install -m644 "$ROOT/shell/interactive.bash" "$HOME/.config/kubuntu-config/interactive.bash"
rc="$HOME/.bashrc"; touch "$rc"
entry='[ -r "$HOME/.config/kubuntu-config/interactive.bash" ] && source "$HOME/.config/kubuntu-config/interactive.bash"'
grep -Fxq "$entry" "$rc" || printf '\n# Kubuntu_Config terminal additions\n%s\n' "$entry" >> "$rc"
