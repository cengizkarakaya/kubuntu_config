#!/usr/bin/env bash
set -Eeuo pipefail
# Only safe, supported, app-scoped defaults. No wholesale ~/.config replacement.
if command -v kwriteconfig6 >/dev/null; then
 kwriteconfig6 --file kdeglobals --group General --key ColorScheme BreezeDark
 kwriteconfig6 --file kdeglobals --group General --key AccentColor '136,192,208'
 kwriteconfig6 --file kwinrc --group Desktops --key Number 10
 kwriteconfig6 --file kwinrc --group Windows --key FocusPolicy ClickToFocus
 echo "Saved KDE defaults; settings may require new session."
else
 echo "kwriteconfig6 unavailable; Plasma settings deferred."
fi
# Screen layout, panel, effects and global shortcuts stay KDE-managed.
# Polonium installation is conditional and must be verified on target Plasma / Wayland session.
