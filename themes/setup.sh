#!/usr/bin/env bash
set -Eeuo pipefail
# Preserve the Nord palette without fetching and executing unreviewed theme installers.
if command -v kwriteconfig6 >/dev/null; then
 kwriteconfig6 --file kdeglobals --group General --key ColorScheme BreezeDark
 kwriteconfig6 --file kdeglobals --group General --key AccentColor '136,192,208'
fi
echo "KDE Breeze Dark + Nord cyan accent set."
echo "Full Nordic GTK/Nordzy icons/cursors: see themes/NORD.md; manual vetted theme installation required."
