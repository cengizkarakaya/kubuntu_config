#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd -- "$(dirname -- "$0")" && pwd)"
PASS=0; WARN=0; FAIL=0
ok(){ printf 'PASS  %-19s %s\n' "$1" "$2"; ((PASS+=1)); }
warn(){ printf 'WARN  %-19s %s\n' "$1" "$2"; ((WARN+=1)); }
fail(){ printf 'FAIL  %-19s %s\n' "$1" "$2"; ((FAIL+=1)); }
has(){ command -v "$1" >/dev/null 2>&1; }
dpkg_installed(){ dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -qx 'install ok installed'; }
echo '=== Kubuntu_Config verification (checks do not mutate system) ==='
source /etc/os-release
[[ "$ID" == ubuntu ]] && ok distro "$PRETTY_NAME" || fail distro 'Ubuntu required'
if has plasmashell; then ok desktop 'Plasma detected'; else fail desktop 'Plasma missing'; fi
for cmd in brave-browser code git stow alacritty bat fzf rg zoxide starship dolphin spectacle kwriteconfig6 kreadconfig6 flatpak; do
  if has "$cmd"; then ok command "$cmd"; else fail command "$cmd"; fi
done
for cmd in hx yazi zellij btm eza fd fdfind gh mpv; do
  if has "$cmd"; then ok command "$cmd"; else warn command "$cmd"; fi
done
# Manifest-check instead of relying on guessed executable casing.
while IFS= read -r pkg; do
  [[ -n "$pkg" && "$pkg" != \#* ]] || continue
  if dpkg_installed "$pkg"; then ok apt "$pkg"; else warn apt "$pkg missing/unavailable"; fi
done < <(sed 's/#.*$//; /^$/d' "$ROOT/packages/apt.txt")
for id in org.localsend.localsend net.cozic.joplin_desktop org.zotero.Zotero com.orcaslicer.OrcaSlicer; do
  if has flatpak && flatpak info --user "$id" >/dev/null 2>&1; then
    ok flatpak "$id"
  else warn flatpak "$id missing"; fi
done
if has fc-list && fc-list : family | grep -Fqi 'FiraCode Nerd Font'; then
  ok font 'FiraCode Nerd Font'
else fail font 'FiraCode Nerd Font missing'; fi
if has fc-list && fc-list : family | grep -Fqi 'Fira Code'; then
  ok font 'Fira Code'
else warn font 'Fira Code apt package missing'; fi
[[ -f "$HOME/.local/share/color-schemes/KubuntuNord.colors" ]] && ok theme KubuntuNord || fail theme 'KubuntuNord.colors missing'
[[ -f "$HOME/.local/share/themes/Nordic/index.theme" ]] && ok theme 'Nordic GTK' || warn theme 'Nordic GTK missing'
if [[ -f "$HOME/.local/share/icons/Nordzy-dark/index.theme" ]]; then ok theme "Nordzy-dark icons"; else warn theme "Nordzy-dark icons missing"; fi
if has kreadconfig6; then
  val="$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null)"
  [[ "$val" == KubuntuNord ]] && ok kde colorscheme || warn kde "ColorScheme=$val"
  val="$(kreadconfig6 --file kwinrc --group Desktops --key Number 2>/dev/null)"
  [[ "$val" == 10 ]] && ok kde '10 virtual desktops' || warn kde "Number=$val"
  val="$(kreadconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled 2>/dev/null)"
  [[ "$val" == true ]] && ok kde 'Kröhnkite requested enabled' || fail kde "Kröhnkite enabled=$val"
  val="$(kreadconfig6 --file kwinrc --group Script-krohnkite --key tileLayoutGap 2>/dev/null)"
  [[ "$val" == 5 ]] && ok kde 'Kröhnkite 5px gap' || warn kde "tileLayoutGap=$val"
  val="$(kreadconfig6 --file kglobalshortcutsrc --group kwin --key 'Window Close' 2>/dev/null)"
  [[ "$val" == *'Meta+Q'* ]] && ok shortcut 'Meta+Q configured' || warn shortcut 'Meta+Q not in KWin shortcut config'
fi
if has kpackagetool6 && kpackagetool6 -t KWin/Script -s krohnkite >/dev/null 2>&1; then
  ok tiling 'Kröhnkite installed'
else fail tiling 'Kröhnkite KWin6 script missing'; fi
# Stow links: verify each vendored file resolves to exactly its repo counterpart.
for module in alacritty bat bottom fastfetch git helix readline starship yazi zathura zellij; do
  root="$ROOT/dotfiles/$module"
  [[ -d "$root" ]] || { warn stow "$module folder missing"; continue; }
  while IFS= read -r -d '' item; do
    rel="${item#"$root"/}"; link="$HOME/$rel"
    if [[ -L "$link" && "$(readlink -f -- "$link")" == "$(readlink -f -- "$item")" ]]; then
      ok symlink "$module: $rel"
    else warn symlink "$module: $rel"; fi
  done < <(find "$root" -type f -print0)
done
for service in sddm NetworkManager; do
  if systemctl is-active --quiet "$service"; then ok service "$service"; else warn service "$service not active"; fi
done
if systemctl is-active --quiet libvirtd.socket || systemctl is-active --quiet virtqemud.socket || systemctl is-active --quiet libvirtd; then
  ok service 'libvirt socket/daemon'
else warn service 'libvirt socket inactive'; fi
if has xdg-mime; then
  mime="$(xdg-mime query default x-scheme-handler/https 2>/dev/null)"
  [[ "$mime" == *brave* ]] && ok default-app "https=$mime" || warn default-app "https=$mime"
  mime="$(xdg-mime query default inode/directory 2>/dev/null)"
  [[ "$mime" == *dolphin* ]] && ok default-app "files=$mime" || warn default-app "files=$mime"
fi
if has nvidia-smi && nvidia-smi -L >/dev/null 2>&1; then ok graphics 'NVIDIA works'; else warn graphics 'NVIDIA not confirmed (driver managed by Ubuntu)'; fi
[[ "${XDG_SESSION_TYPE:-}" == wayland ]] && ok session Wayland || warn session 'Not running under Wayland'
if [[ -f "$HOME/.local/state/kubuntu-config/apt-unavailable.txt" ]]; then
  warn packages 'APT failures recorded in ~/.local/state/kubuntu-config/apt-unavailable.txt'
fi
echo '=== Add-on inventory is NOT proof of installation ==='
if [[ -r "$ROOT/applications/addons.tsv" ]]; then
  awk -F '\t' 'BEGIN {n=0} $0 !~ /^#/ && NF >= 4 {n++; a[$4]++} END {printf "Total extension requests: %d\n",n; for (s in a) printf "  %s: %d\n",s,a[s]}' "$ROOT/applications/addons.tsv"
fi
warn extensions 'Many add-ons require explicit app manager steps; see applications/README.md'
warn keys 'Confirm active KGlobalAccel/Krohnkite bindings via KDE GUI after re-login'
printf '\nSUMMARY: PASS=%d WARN=%d FAIL=%d\n' "$PASS" "$WARN" "$FAIL"
(( FAIL == 0 ))
