#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
command -v flatpak >/dev/null || { echo '[FAIL] flatpak command missing' >&2; exit 1; }
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
failures=()
while IFS=$'\t' read -r id name; do
  [[ -n "$id" && "$id" != \#* ]] || continue
  if [[ ! "$id" =~ ^[A-Za-z0-9_.-]+$ ]]; then echo "Invalid Flatpak app ID: $id" >&2; exit 2; fi
  if ! flatpak info --user "$id" >/dev/null 2>&1; then
    flatpak install --user --noninteractive -y flathub "$id" || failures+=("$id: install failed")
  fi
  # Even an already-installed app must be upgraded to the latest stable commit.
  flatpak update --user --noninteractive -y "$id" || failures+=("$id: update failed")
  if ! flatpak info --user "$id" >/dev/null 2>&1; then
    failures+=("$id: not installed")
    continue
  fi
  # Explicitly verify the installed commit against Flathub's current default.
  local_sha="$(flatpak info --user --show-commit "$id" 2>/dev/null || true)"
  remote_sha="$(flatpak remote-info --user --show-commit flathub "$id" 2>/dev/null || true)"
  if [[ -z "$local_sha" || -z "$remote_sha" || "$local_sha" != "$remote_sha" ]]; then
    failures+=("$id: installed commit differs from current Flathub stable, or remote lookup failed")
  fi
done < "$ROOT/packages/flatpak.tsv"
if (("${#failures[@]}")); then
  printf '[FAIL] Flatpak applications incomplete:\n' >&2
  printf ' - %s\n' "${failures[@]}" >&2
  exit 1
fi
echo '[OK] All Flatpak applications installed'
