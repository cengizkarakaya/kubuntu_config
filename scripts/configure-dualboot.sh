#!/usr/bin/env bash
set -Eeuo pipefail
# Opt-in GRUB Windows discovery AFTER Windows is installed, UEFI only.
# No partition, EFI boot-order, ESP or kernel modifications.
apply=0
case "${1:-}" in --apply) apply=1 ;; --dry-run|'') ;; *) echo 'Usage: configure-dualboot.sh [--apply]'; exit 2 ;; esac
[[ -d /sys/firmware/efi ]] || { echo 'UEFI required'; exit 1; }
command -v update-grub >/dev/null || { echo 'GRUB not installed; use UEFI firmware boot menu'; exit 1; }
command -v os-prober >/dev/null || { echo 'Install os-prober manually: sudo apt install os-prober'; exit 1; }
found="$(sudo os-prober || true)"
printf 'Detected systems:\n%s\n' "$found"
if ! grep -iqE 'windows|microsoft' <<< "$found"; then
  echo 'Windows not found. No changes made.'; exit 1
fi
echo 'Would create: /etc/default/grub.d/60-kubuntu-windows.cfg'
if ((apply==0)); then echo 'DRY RUN. Use --apply after inspection.'; exit 0; fi
printf 'Type WINDOWS to enable GRUB OS probing: '
read -r confirmation
[[ "$confirmation" == WINDOWS ]] || exit 1
sudo install -d -m755 /etc/default/grub.d
dest=/etc/default/grub.d/60-kubuntu-windows.cfg
if [[ -e "$dest" ]]; then sudo cp -a "$dest" "$dest.backup-$(date +%Y%m%d%H%M%S)"; fi
echo 'GRUB_DISABLE_OS_PROBER=false' | sudo tee "$dest" >/dev/null
sudo update-grub
echo 'Review boot menu at next reboot.'
