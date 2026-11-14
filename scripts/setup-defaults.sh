#!/usr/bin/env bash
set -Eeuo pipefail
# Prefer the user's current Firefox browser rather than resetting defaults to Brave.
# Different Ubuntu package channels export different Firefox desktop IDs.
browser=''
for candidate in firefox.desktop firefox_firefox.desktop org.mozilla.firefox.desktop; do
  for dir in "$HOME/.local/share/applications" /usr/share/applications /var/lib/snapd/desktop/applications /usr/local/share/applications; do
    if [[ -f "$dir/$candidate" ]]; then browser="$candidate"; break 2; fi
  done
done
if [[ -n "$browser" ]]; then
  if command -v xdg-mime >/dev/null; then
    for mime in x-scheme-handler/http x-scheme-handler/https text/html; do
      xdg-mime default "$browser" "$mime" || true
    done
  fi
  if command -v kwriteconfig6 >/dev/null; then
    kwriteconfig6 --file kdeglobals --group General --key BrowserApplication "$browser"
  fi
  echo "[OK] Firefox is the preferred browser ($browser)"
else
  echo '[WARN] Firefox desktop entry not found; browser default left unchanged.' >&2
fi
if command -v xdg-mime >/dev/null; then
  xdg-mime default org.kde.dolphin.desktop inode/directory || true
  xdg-mime default org.kde.okular.desktop application/pdf || true
  xdg-mime default vlc.desktop video/mp4 || true
fi
if command -v kwriteconfig6 >/dev/null; then
  kwriteconfig6 --file kdeglobals --group General --key TerminalApplication alacritty
fi
