#!/usr/bin/env bash
set -Eeuo pipefail
command -v kwriteconfig6 >/dev/null || exit 1
# Backup only the one KDE shortcut file before targeted edits.
src="$HOME/.config/kglobalshortcutsrc"
if [[ -f "$src" ]]; then
  dir="$HOME/.local/state/kubuntu-config/backups"; mkdir -p "$dir"
  cp -p "$src" "$dir/kglobalshortcutsrc-$(date +%Y%m%d-%H%M%S)"
fi
# Native KWin action identifiers. KDE may reject keys with global conflicts;
# review in System Settings > Keyboard > Shortcuts after relogin.
setkey() {
  kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "$1" "$2"
}
setkey 'Window Close' 'Meta+Q,Alt+F4,Close Window'
setkey 'Window Fullscreen' 'Meta+F,none,Make Window Fullscreen'
for i in $(seq 1 10); do
  key="$i"; [[ "$i" == 10 ]] && key=0
  setkey "Switch to Desktop $i" "Meta+$key,none,Switch to Desktop $i"
  setkey "Window to Desktop $i" "Meta+Shift+$key,none,Window to Desktop $i"
done
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/kubuntu-alacritty.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Kubuntu Alacritty
Exec=alacritty
Terminal=false
Icon=Alacritty
Categories=System;TerminalEmulator;
EOF
cat > "$HOME/.local/share/applications/kubuntu-power.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Kubuntu Power Menu
Exec=kubuntu-power-menu
Terminal=false
Icon=system-shutdown
Categories=System;
EOF
install -Dm755 "$(dirname -- "$0")/../scripts/kubuntu-power-menu" "$HOME/.local/bin/kubuntu-power-menu"
command -v kbuildsycoca6 >/dev/null && kbuildsycoca6 >/dev/null 2>&1 || true
# Plasma services shortcuts are managed by KGlobalAccel. KDE session needs logout.
appkey() {
  kwriteconfig6 --file kglobalshortcutsrc --group services --group "$1" --key _launch "$2,none,$3"
}
appkey kubuntu-alacritty.desktop 'Meta+Return' 'Kubuntu Alacritty'
appkey brave-browser.desktop 'Meta+B' 'Brave Browser'
appkey org.kde.dolphin.desktop 'Meta+E' 'Dolphin'
appkey kubuntu-power.desktop 'Meta+M' 'Kubuntu Power Menu'
# KRunner uses Meta+Space natively on many Plasma 6 setups. Do not overwrite
# existing XKB layout switch or other shortcuts without user inspection.
echo 'KDE shortcut entries written; log out/in and inspect conflicts in KDE Shortcuts.'
echo 'Kröhnkite handles Meta+H/J/K/L and Meta+Shift+H/J/K/L using its own QML actions.'
echo 'Resize uses Meta+Ctrl+H/J/K/L; Hyprland modal Meta+R cannot be ported exactly.'
