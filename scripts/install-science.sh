#!/usr/bin/env bash
# Opt-in Ubuntu APT science profile. Dry-run by default; never remove packages.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="$ROOT/packages/science-apt.txt"
mode="${1:---plan}"
case "$mode" in
  --plan|--install) ;;
  *) printf 'Usage: bash %s --plan | --install\n' "$0" >&2; exit 2 ;;
esac
(( EUID != 0 )) || { echo 'Run as regular user, not sudo/root.' >&2; exit 2; }
[[ -r "$manifest" ]] || { echo "Missing manifest: $manifest" >&2; exit 2; }
mapfile -t pkgs < <(sed 's/#.*//;s/^[[:space:]]*//;s/[[:space:]]*$//;/^$/d' "$manifest")
(("${#pkgs[@]}" > 0)) || { echo 'Empty science manifest' >&2; exit 2; }
if [[ " ${pkgs[*]} " == *" quantum-espresso-data "* ]]; then
  echo 'Unsafe: quantum-espresso-data conflicts with SSSP.' >&2; exit 2
fi
if [[ "$mode" == --install ]]; then
  echo '==> Updating signed APT metadata'
  sudo apt-get update
fi
missing=()
for pkg in "${pkgs[@]}"; do
  [[ "$pkg" =~ ^[a-z0-9][a-z0-9+.-]*$ ]] || { echo "Invalid package name: $pkg" >&2; exit 2; }
  candidate="$(apt-cache policy "$pkg" | awk '$1=="Candidate:" {print $2;exit}')"
  if [[ -z "$candidate" || "$candidate" == "(none)" ]]; then
    missing+=("$pkg")
  else
    printf 'Candidate %-30s %s\n' "$pkg" "$candidate"
  fi
done
if (("${#missing[@]}" > 0)); then
  printf '[FAIL] Missing candidates in configured repositories: %s\n' "${missing[*]}" >&2
  echo 'Do not add arbitrary PPAs or change distribution to work around this.' >&2
  exit 1
fi
echo '==> Simulating complete transaction (no removals allowed)'
if ! apt-get -s install --no-install-recommends --no-remove "${pkgs[@]}"; then
  echo '[FAIL] APT simulation failed; no package changes were made by this script.' >&2
  exit 1
fi
if [[ "$mode" == --plan ]]; then
  echo '[OK] Dry run only. To install: bash scripts/install-science.sh --install'
  exit 0
fi
echo '==> Installing signed APT packages without recommends/removals'
sudo apt-get install -y --no-install-recommends --no-remove "${pkgs[@]}"
for pkg in "${pkgs[@]}"; do
  dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -qx 'install ok installed' || {
    echo "[FAIL] Package not configured: $pkg" >&2; exit 1;
  }
done
echo '[OK] Science APT profile installed. GUI, numerical results and menu entries require real host tests.'
