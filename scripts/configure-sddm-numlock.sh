#!/usr/bin/env bash
set -Eeuo pipefail

# Configure SDDM's X11 and KWin/Wayland greeters, without restarting the
# display manager or modifying the active user's keyboard/desktop settings.
(( EUID != 0 )) || { echo '[FAIL] Run as a regular user, not root' >&2; exit 2; }
for cmd in sudo kwriteconfig6 kreadconfig6 install id; do
  command -v "$cmd" >/dev/null || { echo "[FAIL] Missing $cmd" >&2; exit 1; }
done
id -u sddm >/dev/null 2>&1 || {
  echo '[FAIL] SDDM system account not found' >&2
  exit 1
}

# kwriteconfig6 changes only the indicated INI key and preserves other keys.
sudo kwriteconfig6 --file /etc/sddm.conf --group General --key Numlock on
sudo install -d -m 755 -o sddm -g sddm /var/lib/sddm/.config
sudo -u sddm env XDG_CONFIG_HOME=/var/lib/sddm/.config \
  kwriteconfig6 --file kcminputrc --group Keyboard --key NumLock 0

# Check persisted values; verification here is distinct from a live login test.
x11="$(sudo kreadconfig6 --file /etc/sddm.conf --group General --key Numlock)"
wayland="$(sudo -u sddm env XDG_CONFIG_HOME=/var/lib/sddm/.config \
  kreadconfig6 --file kcminputrc --group Keyboard --key NumLock)"
[[ "$x11" == on && "$wayland" == 0 ]] || {
  echo "[FAIL] SDDM Num Lock verification: General=$x11 Keyboard=$wayland" >&2
  exit 1
}
echo '[OK] SDDM Num Lock configured for X11 and KWin/Wayland greeters'
echo '[INFO] Settings take effect at the next normal SDDM login; no restart performed.'
