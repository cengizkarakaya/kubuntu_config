#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
while IFS=$'\t' read -r id name; do
  [[ -z "$id" || "$id" == \#* ]] && continue
  flatpak info --user "$id" >/dev/null 2>&1 && continue
  flatpak install --user -y flathub "$id" || echo "[WARN] Flatpak unavailable: $id"
done < "$ROOT/packages/flatpak.tsv"
