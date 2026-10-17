#!/usr/bin/env bash
set -Eeuo pipefail
command -v kwriteconfig6 >/dev/null || { echo 'Plasma 6 tools missing'; exit 1; }
# Small, KDE-supported kconfig mutations. No global ~/.config copy, display ID guesses or panel hacks.
kwriteconfig6 --file kwinrc --group Desktops --key Number 10
kwriteconfig6 --file kwinrc --group Windows --key FocusPolicy ClickToFocus
kwriteconfig6 --file kxkbrc --group Layout --key Use true
kwriteconfig6 --file kxkbrc --group Layout --key LayoutList tr
kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 0.75
kwriteconfig6 --file ksmserverrc --group General --key loginMode emptySession
echo 'Saved KDE preferences. KScreen keeps monitor layout; no display identity guessed.'
