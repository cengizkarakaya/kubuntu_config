#!/usr/bin/env bash
set -uo pipefail
echo 'Read-only UEFI/dual boot diagnostics'
[[ -d /sys/firmware/efi ]] && echo 'Boot mode: UEFI' || echo 'Boot mode: legacy BIOS'
if command -v lsblk >/dev/null; then lsblk -o NAME,SIZE,MODEL,FSTYPE,LABEL,UUID,MOUNTPOINTS; fi
if command -v efibootmgr >/dev/null; then sudo efibootmgr -v; fi
if command -v os-prober >/dev/null; then sudo os-prober; fi
echo 'No grub-install, update-grub, efibootmgr -o or partition command executed.'
