#!/usr/bin/env bash
set -Eeuo pipefail
if command -v xdg-mime >/dev/null; then
  for mime in x-scheme-handler/http x-scheme-handler/https text/html; do
    xdg-mime default brave-browser.desktop "$mime" || true
  done
  xdg-mime default org.kde.dolphin.desktop inode/directory || true
  xdg-mime default org.kde.okular.desktop application/pdf || true
  xdg-mime default vlc.desktop video/mp4 || true
fi
if command -v kwriteconfig6 >/dev/null; then
  kwriteconfig6 --file kdeglobals --group General --key BrowserApplication brave-browser.desktop
  kwriteconfig6 --file kdeglobals --group General --key TerminalApplication alacritty
fi
