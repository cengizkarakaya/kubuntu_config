#!/usr/bin/env bash
# Installed root-owned in /usr/local/libexec; used by the systemd oneshot unit.
set -Eeuo pipefail
(( EUID == 0 )) || { echo '[FAIL] root required' >&2; exit 2; }
action="${1:-}"
config=/etc/kubuntu-config/netalertx-api-guard.nft
table=kubuntu_netalertx_api_guard
case "$action" in
  apply)
    command -v nft >/dev/null 2>&1 || { echo '[FAIL] nft missing' >&2; exit 1; }
    [[ -r "$config" ]] || { echo "[FAIL] Missing root-owned config: $config" >&2; exit 1; }
    if nft list table inet "$table" >/dev/null 2>&1; then
      # Never overwrite a pre-existing table unless it has our exact intended rule.
      output="$(nft list table inet "$table")"
      [[ "$output" == *'iifname != "lo" tcp dport 20212'* ]] || {
        echo '[FAIL] Existing NetAlertX table differs; refusing replacement' >&2; exit 1;
      }
      echo '[OK] NetAlertX API guard already active'
      exit 0
    fi
    nft -c -f "$config" || { echo '[FAIL] Invalid nft rule config' >&2; exit 1; }
    nft -f "$config"
    output="$(nft list table inet "$table")"
    [[ "$output" == *'iifname != "lo" tcp dport 20212'* ]] || {
      echo '[FAIL] NetAlertX API guard did not verify' >&2; exit 1;
    }
    echo '[OK] NetAlertX API port 20212 blocked on non-loopback interfaces'
    ;;
  remove)
    if nft list table inet "$table" >/dev/null 2>&1; then
      nft delete table inet "$table"
      echo '[OK] Removed only the NetAlertX API guard table'
    fi
    ;;
  *) echo 'Usage: api-guard-root.sh apply|remove' >&2; exit 2 ;;
esac
