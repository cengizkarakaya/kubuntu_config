#!/usr/bin/env bash
# User-scoped Gaia Sky Flatpak: optional Astronomy profile, not part of bootstrap.
set -Eeuo pipefail

mode="${1:---plan}"
case "$mode" in
  --plan|--install) ;;
  *) printf 'Usage: bash %s --plan | --install\n' "$0" >&2; exit 2 ;;
esac
(( EUID != 0 )) || { echo '[FAIL] Run without sudo.' >&2; exit 2; }
command -v flatpak >/dev/null || {
  echo '[FAIL] flatpak not found. Install/restore it first.' >&2; exit 1;
}
id=space.gaiasky.GaiaSky

if [[ "$mode" == --plan ]]; then
  echo 'Gaia Sky will be installed/updated from signed Flathub, for the current user only.'
  echo 'This DOES NOT install Celestia or OpenSpace or alter NVIDIA drivers.'
  echo 'The upstream version can be newer than the version presently on Flathub.'
  flatpak info --user "$id" 2>/dev/null || true
  flatpak remote-info --user flathub "$id" 2>/dev/null || true
  echo 'To install: bash scripts/install-astronomy-gaia.sh --install'
  exit 0
fi

flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user --noninteractive -y flathub "$id"
flatpak update --user --noninteractive -y "$id"
local_sha="$(flatpak info --user --show-commit "$id")"
remote_sha="$(flatpak remote-info --user --show-commit flathub "$id")"
if [[ -z "$local_sha" || "$local_sha" != "$remote_sha" ]]; then
  echo '[FAIL] Installed Gaia Sky commit does not match current Flathub stable.' >&2
  exit 1
fi
flatpak info --user "$id" | sed -n '1,12p'
echo '[OK] Gaia Sky installed. Integrate it into Astronomy with:'
echo '     python3 scripts/install-astronomy-launchers.py --check'
echo '     python3 scripts/install-astronomy-launchers.py --install'
