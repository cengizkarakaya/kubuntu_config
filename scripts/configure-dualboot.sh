#!/usr/bin/env bash
set -Eeuo pipefail
# Explicit opt-in Windows discovery: never runs on bootstrap.
# No bootloader installation, EFI mutation, formatting or partition writing.
apply=0
case "${1:-}" in --apply) apply=1 ;; --dry-run|'') ;; *) echo 'Usage: configure-dualboot.sh [--dry-run|--apply]' >&2; exit 2 ;; esac
[[ -d /sys/firmware/efi ]] || { echo '[FAIL] UEFI required' >&2; exit 1; }
command -v update-grub >/dev/null || { echo '[FAIL] update-grub missing; use UEFI boot menu' >&2; exit 1; }
command -v os-prober >/dev/null || { echo '[FAIL] os-prober missing; install manually before rechecking' >&2; exit 1; }
echo 'Read-only probing of existing Windows installation:'
found="$(sudo os-prober)"
printf '%s\n' "$found"
grep -iqE 'windows|microsoft' <<< "$found" || { echo '[FAIL] No Windows detected; nothing changed.' >&2; exit 1; }
dest=/etc/default/grub.d/60-kubuntu-windows.cfg
echo "Would write: $dest"
if ((apply==0)); then echo 'DRY RUN complete: no config changed.'; exit 0; fi
echo 'Confirm EFI backups and Windows drive. Type WINDOWS to proceed:'
read -r confirmation
[[ "$confirmation" == WINDOWS ]] || { echo 'Cancelled'; exit 1; }
tmp="$(mktemp)"
trap 'rm -f -- "$tmp"' EXIT
printf '%s\n' 'GRUB_DISABLE_OS_PROBER=false' > "$tmp"
sudo install -d -m755 /etc/default/grub.d
previous=0
if sudo test -e "$dest"; then
  previous=1
  backup="$HOME/.local/state/kubuntu-config/backups/grub-windows-$(date +%Y%m%d-%H%M%S)-$$.cfg"
  mkdir -p "$(dirname "$backup")"
  sudo cat "$dest" > "$backup"
  chmod 600 "$backup"
  echo "[INFO] Previous configuration backed up to $backup"
fi
sudo install -m644 "$tmp" "$dest"
if ! sudo update-grub; then
  echo '[FAIL] update-grub failed, rolling back configuration' >&2
  if ((previous)); then
    sudo install -m644 "$backup" "$dest"
  else
    sudo rm -f "$dest"
  fi
  sudo update-grub || echo '[WARN] GRUB still needs manual review after rollback' >&2
  exit 1
fi
echo '[OK] Windows GRUB probing enabled; confirm entries at the next reboot.'
