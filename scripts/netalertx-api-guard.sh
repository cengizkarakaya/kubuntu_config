#!/usr/bin/env bash
# Opt-in, persistent narrow nftables protection without activating UFW.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ACTION="${1:-plan}"
[[ $# -le 1 ]] || { echo 'Usage: bash scripts/netalertx-api-guard.sh [plan|enable|check|disable]' >&2; exit 2; }
case "$ACTION" in plan|enable|check|disable) ;; *) echo "[FAIL] Unknown action: $ACTION" >&2; exit 2;; esac
(( EUID != 0 )) || { echo '[FAIL] Run as regular user, not with sudo' >&2; exit 2; }
TABLE=kubuntu_netalertx_api_guard
case "$ACTION" in
  plan)
    cat <<'PLAN'
Optional NetAlertX API firewall guard (host nftables):
  - Drops incoming TCP/20212 on non-loopback interfaces, including Wi-Fi.
  - Preserves localhost access; nginx UI 127.0.0.1:20211 unchanged.
  - Does not enable UFW or nftables.service, flush the system ruleset,
    touch Docker/ROS/SSH or modify default-drop firewall policy.
  - Installs a root-owned rule file, helper, and systemd oneshot unit.
  - Service applies the narrow rule at boot, before Docker starts.
  - Only an explicit 'enable' command changes this host.
PLAN
    echo "nft binary: $(command -v nft || echo 'missing: install nftables APT package before enabling')"
    echo 'Enable: bash scripts/netalertx-api-guard.sh enable'
    exit 0
    ;;
esac
if [[ "$ACTION" == enable ]]; then
  command -v nft >/dev/null 2>&1 || {
    echo '[FAIL] nft binary missing. Install signed Ubuntu package: sudo apt install nftables' >&2; exit 1;
  }
  for f in api-guard.nft api-guard-root.sh netalertx-api-guard.service; do
    [[ -r "$ROOT/network/netalertx/$f" ]] || { echo "[FAIL] Missing source: $f" >&2; exit 1; }
  done
  # Do not give a root service permission to run the user-writable checkout.
  sudo install -o root -g root -m 0644 -D "$ROOT/network/netalertx/api-guard.nft" /etc/kubuntu-config/netalertx-api-guard.nft
  sudo install -o root -g root -m 0755 -D "$ROOT/network/netalertx/api-guard-root.sh" /usr/local/libexec/kubuntu-netalertx-api-guard
  sudo install -o root -g root -m 0644 -D "$ROOT/network/netalertx/netalertx-api-guard.service" /etc/systemd/system/netalertx-api-guard.service
  sudo systemctl daemon-reload
  sudo systemctl enable --now netalertx-api-guard.service
  # Re-apply after upgraded root-owned files (idempotent when unchanged).
  sudo /usr/local/libexec/kubuntu-netalertx-api-guard apply
  echo '[OK] Persistent API ingress guard enabled'
fi
if [[ "$ACTION" == disable ]]; then
  sudo systemctl disable --now netalertx-api-guard.service
  echo '[OK] NetAlertX API firewall unit disabled. No other rules changed.'
fi
if [[ "$ACTION" == enable || "$ACTION" == check ]]; then
  if ! command -v nft >/dev/null 2>&1; then echo '[FAIL] nft missing' >&2; exit 1; fi
  echo '==> systemd state'
  systemctl is-enabled netalertx-api-guard.service
  systemctl is-active netalertx-api-guard.service
  echo '==> current host rule'
  sudo nft list table inet "$TABLE"
fi
