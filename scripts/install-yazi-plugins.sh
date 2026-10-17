#!/usr/bin/env bash
set -Eeuo pipefail
command -v yazi >/dev/null || { echo '[WARN] Yazi package missing'; exit 1; }
command -v ya >/dev/null || { echo '[WARN] Yazi package manager ya missing'; exit 1; }
[[ -f "$HOME/.config/yazi/package.toml" ]] || { echo '[WARN] Yazi package.toml missing (Stow not yet run)'; exit 1; }
ya pkg install
