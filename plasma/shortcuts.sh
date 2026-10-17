#!/usr/bin/env bash
set -Eeuo pipefail
command -v kwriteconfig6 >/dev/null || { echo '[FAIL] kwriteconfig6 missing' >&2; exit 1; }
src="$HOME/.config/kglobalshortcutsrc"
if [[ -f "$src" ]]; then
  backup_dir="$HOME/.local/state/kubuntu-config/backups"
  mkdir -p "$backup_dir"
  cp -p -- "$src" "$backup_dir/kglobalshortcutsrc-$(date +%Y%m%d-%H%M%S)-$$"
fi
setkey() {
  kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "$1" "$2"
}
setkey 'Window Close' 'Meta+Q,Alt+F4,Close Window'
setkey 'Window Fullscreen' 'Meta+F,none,Make Window Fullscreen'
for i in {1..10}; do
  n="$i"; [[ "$i" == 10 ]] && n=0
  setkey "Switch to Desktop $i" "Meta+$n,none,Switch to Desktop $i"
  setkey "Window to Desktop $i" "Meta+Shift+$n,none,Window to Desktop $i"
done
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/kubuntu-alacritty.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Kubuntu Alacritty
Exec=alacritty
Terminal=false
StartupNotify=false
X-KDE-GlobalAccel-CommandShortcut=true
Icon=Alacritty
Categories=System;TerminalEmulator;
EOF
cat > "$HOME/.local/share/applications/kubuntu-power.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Kubuntu Power Menu
Exec=$HOME/.local/bin/kubuntu-power-menu
Terminal=false
StartupNotify=false
X-KDE-GlobalAccel-CommandShortcut=true
Icon=system-shutdown
Categories=System;
EOF
install -Dm755 "$(dirname -- "${BASH_SOURCE[0]}")/../scripts/kubuntu-power-menu" "$HOME/.local/bin/kubuntu-power-menu"
if command -v kbuildsycoca6 >/dev/null; then kbuildsycoca6 >/dev/null 2>&1 || echo '[WARN] kbuildsycoca6 refresh failed'; fi
# Plasma 6 global shortcuts are session-owned; these edits are persistent hints.
# Never restart the live kglobalaccel/KWin daemon or claim hotkeys activated now.
appkey() {
  kwriteconfig6 --file kglobalshortcutsrc --group services --group "$1" --key _launch "$2,none,$3"
}
appkey kubuntu-alacritty.desktop 'Meta+Return' 'Kubuntu Alacritty'
appkey brave-browser.desktop 'Meta+B' 'Brave Browser'
appkey org.kde.dolphin.desktop 'Meta+E' 'Dolphin'
appkey kubuntu-power.desktop 'Meta+M' 'Kubuntu Power Menu'
echo '[OK] Shortcut files written; log out/in and verify live registrations in KDE System Settings > Keyboard > Shortcuts.'
echo 'Polonium native keys: Meta+H/J/K/L focus, Meta+Shift+H/J/K/L move, Meta+Ctrl+H/J/K/L resize.'
echo '[WARN] KDE may ignore file-only app shortcuts; bind in System Settings if they are not active.'
