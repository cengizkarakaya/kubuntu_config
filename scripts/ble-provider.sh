#!/usr/bin/env bash
# Read-only validation of the existing user-local ble.sh provider.
# 0: plausible local script; 1: absent; 2: broken local override.
# Never source or execute this untracked script in an installer or audit.
ble_local_status() {
  local path="$HOME/.local/share/blesh/ble.sh"
  [[ -e "$path" || -L "$path" ]] || return 1
  [[ -f "$path" && -s "$path" && -r "$path" ]] || return 2
  grep -F 'BLE_VERSION' "$path" >/dev/null || return 2
  bash -n "$path" >/dev/null 2>&1 || return 2
}
