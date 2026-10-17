#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
mkdir -p "$HOME/.local/share/color-schemes" "$HOME/.local/share/fonts/FiraCodeNerd" "$HOME/.local/share/themes"
install -m644 "$ROOT/themes/KubuntuNord.colors" "$HOME/.local/share/color-schemes/KubuntuNord.colors"
# Pinned upstream Nerd Fonts artifact with published SHA256, never sudo or execute downloaded code.
font_dir="$HOME/.local/share/fonts/FiraCodeNerd"
if ! find "$font_dir" -name '*.ttf' -print -quit | grep -q .; then
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  curl -fsSL --retry 3 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/FiraCode.tar.xz' -o "$tmp/FiraCode.tar.xz"
  echo '68e3bd6164864b8b514605bc34e3a87ac401c8c48682fcce6478c70263340207  '"$tmp/FiraCode.tar.xz" | sha256sum -c -
  tar -xJf "$tmp/FiraCode.tar.xz" -C "$font_dir" --no-same-owner --wildcards '*.ttf'
  fc-cache -f "$font_dir"
fi
# Vendored revision of Nordic GTK theme; never execute third-party install.sh.
if [[ ! -f "$HOME/.local/share/themes/Nordic/index.theme" ]]; then
  tmp2="$(mktemp -d)"; trap 'rm -rf "$tmp2"' EXIT
  git clone -q https://github.com/EliverLara/Nordic.git "$tmp2/nordic"
  git -C "$tmp2/nordic" checkout -q be5bda37ba01139650e34238336e58e065d2f406
  [[ "$(git -C "$tmp2/nordic" rev-parse HEAD)" == be5bda37ba01139650e34238336e58e065d2f406 ]] || exit 1
  mkdir -p "$HOME/.local/share/themes/Nordic"
  git -C "$tmp2/nordic" archive HEAD | tar -x -C "$HOME/.local/share/themes/Nordic"
fi
if command -v kwriteconfig6 >/dev/null; then
  kwriteconfig6 --file kdeglobals --group General --key ColorScheme KubuntuNord
  kwriteconfig6 --file kdeglobals --group General --key AccentColor '136,192,208'
  kwriteconfig6 --file kdeglobals --group General --key font 'FiraCode Nerd Font,10,-1,5,50,0,0,0,0,0'
  kwriteconfig6 --file kdeglobals --group General --key fixed 'FiraCode Nerd Font Mono,10,-1,5,50,0,0,0,0,0'
fi
command -v plasma-apply-colorscheme >/dev/null && plasma-apply-colorscheme KubuntuNord || true
if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface gtk-theme Nordic || true
  gsettings set org.gnome.desktop.interface icon-theme Nordzy-dark || true
  gsettings set org.gnome.desktop.interface font-name 'FiraCode Nerd Font 10' || true
  gsettings set org.gnome.desktop.interface monospace-font-name 'FiraCode Nerd Font Mono 10' || true
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
fi
bash "$ROOT/themes/install-nordzy-icons.sh" || echo '[WARN] Nordzy icons could not be installed; retained KDE fallback'
echo 'Nord palette, Nerd Font, Nordic GTK and Nordzy icons (if successful) are configured; Nordzy cursor remains optional.'
