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
  if ! sudo apt-get install -y --no-install-recommends --no-remove "${available[@]}"; then
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
    missing+=("$pkg [not installed]")
    continue
  fi
  candidate="$(apt-cache policy "$pkg" | awk '$1=="Candidate:" {print $2; exit}')"
  current="$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || true)"
  if [[ -z "$candidate" || "$candidate" == "(none)" || -z "$current" ]]; then
    missing+=("$pkg [unable to determine installed/candidate version]")
  elif dpkg --compare-versions "$current" lt "$candidate"; then
    missing+=("$pkg [installed $current, repository candidate $candidate]")
  fi
done
if (("${#missing[@]}" > 0)); then
  printf '%s\n' "${missing[@]}" | tee "$report" >&2
  echo "[FAIL] APT manifest incomplete; report: $report" >&2
  exit 1
fi
rm -f "$report"
echo "[OK] ${#available[@]} APT packages installed and verified"
