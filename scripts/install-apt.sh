#!/usr/bin/env bash
set -Eeuo pipefail
manifest="$1"
mapfile -t pkgs < <(sed 's/#.*$//; s/^[[:space:]]*//; s/[[:space:]]*$//; /^$/d' "$manifest")
missing=()
for pkg in "${pkgs[@]}"; do
  if ! apt-cache show "$pkg" >/dev/null 2>&1; then
    missing+=("$pkg"); continue
  fi
  if ! sudo apt-get install -y "$pkg"; then missing+=("$pkg [installation failed]"); fi
done
report="$HOME/.local/state/kubuntu-config/apt-unavailable.txt"
if (("${#missing[@]}" > 0)); then
  printf '%s\n' "${missing[@]}" | tee "$report"
  echo '[WARN] Some APT packages missing; see the report.'
else rm -f "$report"; fi
