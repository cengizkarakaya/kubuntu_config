#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PASS=0; WARN=0; FAIL=0
ok(){ printf 'PASS %-24s %s\n' "$1" "$2"; ((PASS+=1)); }
warn(){ printf 'WARN %-24s %s\n' "$1" "$2"; ((WARN+=1)); }
fail(){ printf 'FAIL %-24s %s\n' "$1" "$2"; ((FAIL+=1)); }
checkcmd(){ local c="$1"; if command -v "$c" >/dev/null 2>&1; then ok command "$c"; else fail command "$c missing"; fi; }
echo "Kubuntu Config verification"
for x in brave-browser git stow alacritty hx yazi zellij starship fzf zoxide rg dolphin kwriteconfig6 kwin_wayland flatpak; do
 case "$x" in hx) command -v hx >/dev/null || command -v helix >/dev/null && ok command helix || fail command helix;; *) checkcmd "$x";; esac
done
for x in krita gimp kicad blender kdenlive FreeCAD freecad thunderbird libreoffice vlc calibre strawberry inkscape handbrake keepassxc virt-manager qbittorrent meshlab; do
 case "$x" in
 FreeCAD|freecad) continue ;;
 *) if command -v "$x" >/dev/null 2>&1 || dpkg-query -W -f='${Status}' "$x" 2>/dev/null | grep -q 'install ok installed'; then ok app "$x"; else warn app "$x (alternate launcher/package may exist)"; fi ;;
 esac
done
for x in org.localsend.localsend net.cozic.joplin_desktop org.zotero.Zotero com.orcaslicer.OrcaSlicer; do
 if command -v flatpak >/dev/null && flatpak info --user "$x" >/dev/null 2>&1; then ok flatpak "$x"; else warn flatpak "$x missing"; fi
done
if fc-match 'FiraCode Nerd Font' | grep -qi 'FiraCode'; then ok font 'FiraCode Nerd Font (inspect actual family)'; else warn font 'FiraCode Nerd Font absent'; fi
if fc-match 'Fira Code' | grep -qi 'Fira'; then ok font 'Fira Code'; else warn font 'Fira Code absent'; fi
if [[ -e "$HOME/.config/alacritty/alacritty.toml" && -L "$HOME/.config/alacritty/alacritty.toml" ]]; then ok stow 'Alacritty symlink'; else warn stow 'Alacritty symlink missing'; fi
for p in "$HOME/.config/helix/config.toml" "$HOME/.config/starship.toml" "$HOME/.config/yazi/yazi.toml"; do if [[ -L "$p" ]]; then ok stow "$p"; else warn stow "$p not symlinked"; fi; done
if command -v kreadconfig6 >/dev/null; then
 v="$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null)"
 [[ "$v" == BreezeDark ]] && ok kde 'BreezeDark' || warn kde "ColorScheme=$v"
 v="$(kreadconfig6 --file kwinrc --group Desktops --key Number 2>/dev/null)"
 [[ "$v" == 10 ]] && ok kde '10 virtual desktops' || warn kde "virtual desktops=$v"
else warn kde 'kreadconfig6 missing'; fi
for s in sddm NetworkManager; do if systemctl is-active --quiet "$s"; then ok service "$s"; else warn service "$s not active"; fi; done
if systemctl is-active --quiet libvirtd || systemctl is-active --quiet virtqemud; then ok service 'libvirt'; else warn service 'libvirt (not active)'; fi
if command -v xdg-mime >/dev/null; then
 v="$(xdg-mime query default x-scheme-handler/https 2>/dev/null)"
 [[ "$v" == *brave* ]] && ok default-browser "$v" || warn default-browser "$v (expected Brave)"
fi
if command -v nvidia-smi >/dev/null && nvidia-smi -L >/dev/null 2>&1; then ok gpu 'NVIDIA operational'; else warn gpu 'NVIDIA driver not checked/operational'; fi
[[ "${XDG_SESSION_TYPE:-}" == wayland ]] && ok session Wayland || warn session "Not in Wayland session"
warn tiling 'Polonium install/enable and keyboard action mapping require manual verification'
warn addons 'See applications/addons.tsv; not automatically verified as installed'
warn nord 'Check Nordic GTK/Nordzy icons/cursor in System Settings'
printf '\nRESULT: PASS=%d WARN=%d FAIL=%d\n' "$PASS" "$WARN" "$FAIL"
((FAIL==0))
