#!/usr/bin/env bash
set -Eeuo pipefail
manifest="${1:?Usage: install-apt.sh packages/apt.txt}"
[[ -r "$manifest" ]] || { echo "[FAIL] Unreadable manifest: $manifest" >&2; exit 2; }
command -v apt-cache >/dev/null || { echo '[FAIL] apt-cache not installed' >&2; exit 1; }
mapfile -t pkgs < <(sed 's/#.*$//; s/^[[:space:]]*//; s/[[:space:]]*$//; /^$/d' "$manifest")
(("${#pkgs[@]}" > 0)) || { echo '[FAIL] Empty APT manifest' >&2; exit 1; }
report="$HOME/.local/state/kubuntu-config/apt-unavailable.txt"
mkdir -p "$(dirname "$report")"
missing=()
available=()
for pkg in "${pkgs[@]}"; do
  if [[ ! "$pkg" =~ ^[a-z0-9][a-z0-9+.-]*$ ]]; then
    echo "[FAIL] Invalid package name: $pkg" >&2; exit 2
  fi
  if ! apt-cache show "$pkg" >/dev/null 2>&1; then
    missing+=("$pkg [not found in configured APT sources]")
  else
    available+=("$pkg")
  fi
done
if (("${#available[@]}" > 0)); then
  # No optional/recommended application extensions; dependency packages remain allowed.
  if ! sudo apt-get install -y --no-install-recommends "${available[@]}"; then
    echo '[WARN] Bulk APT transaction failed. Trying individual packages to identify failures.'
    for pkg in "${available[@]}"; do
      if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -qx 'install ok installed'; then
        if ! sudo apt-get install -y --no-install-recommends "$pkg"; then missing+=("$pkg [APT installation failed]"); fi
      fi
    done
  fi
fi
for pkg in "${available[@]}"; do
  if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -qx 'install ok installed'; then
    if [[ ! " ${missing[*]} " == *" $pkg ["* ]]; then missing+=("$pkg [not installed]"); fi
  fi
done
if (("${#missing[@]}" > 0)); then
  printf '%s\n' "${missing[@]}" | tee "$report" >&2
  echo "[FAIL] APT manifest incomplete; report: $report" >&2
  exit 1
fi
rm -f "$report"
echo "[OK] ${#available[@]} APT packages installed and verified"
