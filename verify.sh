#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SKIP_PLASMA=0
for arg in "$@"; do
  case "$arg" in --skip-plasma) SKIP_PLASMA=1 ;; *) echo "Unknown argument: $arg" >&2; exit 2 ;; esac
done
PASS=0 WARN=0 FAIL=0
ok()   { printf 'PASS  %-22s %s\n' "$1" "$2"; ((PASS+=1)); }
warn() { printf 'WARN  %-22s %s\n' "$1" "$2"; ((WARN+=1)); }
fail() { printf 'FAIL  %-22s %s\n' "$1" "$2"; ((FAIL+=1)); }
has() { command -v "$1" >/dev/null 2>&1; }
installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -qx 'install ok installed'; }
echo '=== Kubuntu_Config checks (READ-ONLY; no hardware or account changes) ==='
source /etc/os-release
[[ "${ID:-}" == ubuntu ]] && ok distro "$PRETTY_NAME" || fail distro 'Ubuntu/Kubuntu required'
has plasmashell && ok desktop 'KDE Plasma detected' || fail desktop 'KDE Plasma not found'
if [[ "${XDG_SESSION_TYPE:-}" == wayland ]]; then
  ok session 'Wayland'
elif ((SKIP_PLASMA)); then
  warn session 'Wayland absent; Polonium deliberately skipped'
else
  fail session 'Polonium requires Plasma Wayland'
fi
for cmd in brave-browser code git stow alacritty bat fzf rg zoxide starship dolphin spectacle kwriteconfig6 kreadconfig6 flatpak; do
  if has "$cmd"; then ok command "$cmd"; else fail command "$cmd"; fi
done
for cmd in hx yazi zellij btm eza fd fdfind gh mpv; do
  has "$cmd" && ok command "$cmd" || fail command "$cmd"
done
for cmd in rustup rustc cargo; do
  has "$cmd" && ok rust "$cmd" || fail rust "$cmd missing"
done
if has rustup; then
  rustup toolchain list 2>/dev/null | grep -Eq '^stable' && ok rust 'stable toolchain' || fail rust 'stable toolchain missing'
fi
if has node; then
  node_major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null)"
  [[ "$node_major" =~ ^[0-9]+$ ]] && ((node_major>=20)) && ok node "Node.js major $node_major" || fail node 'Node.js >=20 required for Polonium builds'
else fail node 'node missing'; fi
missing_apt=0
while IFS= read -r pkg; do
  [[ -n "$pkg" && "$pkg" != \#* ]] || continue
  if installed "$pkg"; then ok apt "$pkg"; else fail apt "$pkg absent"; ((missing_apt+=1)); fi
done < <(sed 's/#.*$//; s/^[[:space:]]*//; s/[[:space:]]*$//; /^$/d' "$ROOT/packages/apt.txt")
echo "APT manifest missing: $missing_apt"
while IFS=$'\t' read -r id name; do
  [[ -n "$id" && "$id" != \#* ]] || continue
  if has flatpak && flatpak info --user "$id" >/dev/null 2>&1; then
    ok flatpak "$id"
  else fail flatpak "$id absent"; fi
done < "$ROOT/packages/flatpak.tsv"
if has fc-list && fc-list : family | grep -Fqi 'FiraCode Nerd Font'; then
  ok font 'FiraCode Nerd Font'
else fail font 'FiraCode Nerd Font missing'; fi
[[ -s "$HOME/.local/share/color-schemes/KubuntuNord.colors" ]] && ok theme 'KubuntuNord' || fail theme 'Nord KDE palette missing'
[[ -s "$HOME/.local/share/themes/Nordic/index.theme" && -s "$HOME/.local/share/themes/Nordic/gtk-3.0/gtk.css" ]] && ok theme 'Nordic GTK' || fail theme 'Nordic GTK missing'
[[ -s "$HOME/.local/share/icons/Nordzy-dark/index.theme" ]] && ok theme 'Nordzy-dark icons' || fail theme 'Nordzy-dark icons missing'
if has kreadconfig6; then
  val="$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null)"
  [[ "$val" == KubuntuNord ]] && ok kde 'Nord palette selected' || fail kde "ColorScheme=$val"
  if ((SKIP_PLASMA==0)); then
    val="$(kreadconfig6 --file kwinrc --group Desktops --key Number 2>/dev/null)"
    [[ "$val" == 10 ]] && ok kde '10 virtual desktops' || fail kde "Virtual desktops=$val"
    val="$(kreadconfig6 --file kwinrc --group Plugins --key poloniumEnabled 2>/dev/null)"
    [[ "$val" == true ]] && ok kde 'Polonium requested enabled' || fail kde "Polonium enabled=$val"
    val="$(kreadconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled 2>/dev/null)"
    [[ "$val" != true ]] && ok kde 'Kröhnkite disabled' || fail kde 'Kröhnkite enabled concurrently!'
    desktopfile="$HOME/.config/kglobalshortcutsrc"
    if [[ -f "$desktopfile" ]]; then ok shortcut 'KDE shortcut config present' && warn shortcut 'Actual shortcut activation requires relogin/manual GUI check'; else fail shortcut 'KDE shortcut config absent'; fi
  fi
fi
if ((SKIP_PLASMA==0)); then
  pkg="${XDG_DATA_HOME:-$HOME/.local/share}/kwin/scripts/polonium/metadata.json"
  if [[ -r "$pkg" ]] && grep -Eq '"Version"[[:space:]]*:[[:space:]]*"1\.2\.1"' "$pkg"; then
    ok tiling 'Polonium 1.2.1 metadata found'
  else fail tiling 'Polonium 1.2.1 not installed in user KWin directory'; fi
  if [[ -e "${XDG_DATA_HOME:-$HOME/.local/share}/kwin/scripts/krohnkite" ]]; then
    fail tiling 'Old Kröhnkite package remains in user directory'
  fi
fi
for module in alacritty bat bottom fastfetch git helix readline starship yazi zellij; do
  root="$ROOT/dotfiles/$module"
  [[ -d "$root" ]] || { fail stow "$module folder missing"; continue; }
  while IFS= read -r -d '' item; do
    rel="${item#"$root"/}"
    link="$HOME/$rel"
    if [[ -L "$link" && "$(readlink -f -- "$link")" == "$(readlink -f -- "$item")" ]]; then
      ok symlink "$module: $rel"
    else fail symlink "$module: $rel"; fi
  done < <(find "$root" -type f -print0)
done
# Guard against accidentally reintroducing optional plugins into repo manifests.
for obsolete in applications/addons.tsv applications/vscode-extensions.txt scripts/install-vscode-extensions.sh scripts/install-yazi-plugins.sh dotfiles/yazi/.config/yazi/package.toml dotfiles/yazi/.config/yazi/init.lua dotfiles/yazi/.config/yazi/theme.toml plasma/install-krohnkite.sh; do
  [[ ! -e "$ROOT/$obsolete" ]] && ok no-addons "$obsolete absent" || fail no-addons "$obsolete should not be shipped"
done
if grep -Eiq '(^|[[:space:]])plugin([[:space:].]|$)' "$ROOT/dotfiles/yazi/.config/yazi/yazi.toml" "$ROOT/dotfiles/yazi/.config/yazi/keymap.toml"; then
  fail no-addons 'Yazi references plugin commands'
else ok no-addons 'Yazi uses built-in actions only'; fi
if has nvidia-smi && nvidia-smi -L >/dev/null 2>&1; then
  ok graphics 'NVIDIA driver responds; application GPU functions NOT tested'
else warn graphics 'NVIDIA driver/GPU not confirmed; Ubuntu controls driver installation'; fi
for service in sddm NetworkManager; do
  systemctl is-active --quiet "$service" && ok service "$service active" || warn service "$service inactive"
done
if systemctl is-active --quiet libvirtd.socket || systemctl is-active --quiet virtqemud.socket || systemctl is-active --quiet libvirtd; then
  ok service 'libvirt active'
else warn service 'libvirt service/socket inactive'; fi
if [[ -f "$HOME/.local/state/kubuntu-config/apt-unavailable.txt" ]]; then
  fail packages 'Unresolved APT package report exists'
fi
if has xdg-mime; then
  mime="$(xdg-mime query default x-scheme-handler/https 2>/dev/null)"
  [[ "$mime" == *brave* ]] && ok default-app "HTTPS $mime" || warn default-app "HTTPS $mime"
fi
echo '=== Note: verification cannot prove in-app GPU acceleration, shortcut activation or GUI stability. ==='
printf '\nSUMMARY PASS=%d WARN=%d FAIL=%d\n' "$PASS" "$WARN" "$FAIL"
((FAIL==0))
