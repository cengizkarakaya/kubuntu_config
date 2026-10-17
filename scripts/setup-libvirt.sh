#!/usr/bin/env bash
set -Eeuo pipefail
# Do not modify IOMMU/kernel, network bridges, or host firewall.
if getent group libvirt >/dev/null; then
  if ! id -nG "$USER" | tr ' ' '\n' | grep -qx libvirt; then
    sudo usermod -aG libvirt "$USER"
    echo 'libvirt group added; sign out/in before using virt-manager.'
  fi
fi
if systemctl list-unit-files libvirtd.socket --no-legend 2>/dev/null | grep -q '^libvirtd.socket'; then
  sudo systemctl enable --now libvirtd.socket
elif systemctl list-unit-files virtqemud.socket --no-legend 2>/dev/null | grep -q '^virtqemud.socket'; then
  sudo systemctl enable --now virtqemud.socket
else
  echo '[WARN] No libvirt socket unit detected; check installation.'
fi
