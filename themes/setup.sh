#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$HOME/.local/share/color-schemes" "$HOME/.local/share/fonts/FiraCodeNerd" "$HOME/.local/share/themes"
install -m644 "$ROOT/themes/KubuntuNord.colors" "$HOME/.local/share/color-schemes/KubuntuNord.colors"
# Always resolve the latest STABLE Nerd Font release, with published SHA-256.
# Preserve Nord look and the FiraCode Nerd Font family.
font_dir="$HOME/.local/share/fonts/FiraCodeNerd"
IFS=$'\t' read -r tag url digest < <(bash "$ROOT/scripts/latest-release.sh" ryanoasis/nerd-fonts FiraCode.tar.xz)
[[ -n "${tag:-}" && -n "${url:-}" && -n "${digest:-}" ]] || {
  echo '[FAIL] Could not resolve newest stable FiraCode Nerd Font release' >&2; exit 1;
}
stamp="$font_dir/.kubuntu-config-version"
if [[ "$(cat "$stamp" 2>/dev/null || true)" != "$tag" ]] ||
   ! find "$font_dir" -name '*.ttf' -print -quit | grep -q .; then
  tmp="$(mktemp -d)"
  trap 'rm -rf -- "$tmp"' EXIT
  curl --proto '=https' --tlsv1.2 -fL --retry 3 --connect-timeout 15 \
    "$url" -o "$tmp/FiraCode.tar.xz"
  printf '%s  %s\n' "$digest" "$tmp/FiraCode.tar.xz" | sha256sum -c -
  mkdir -p "$tmp/fonts"
  tar -xJf "$tmp/FiraCode.tar.xz" -C "$tmp/fonts" --no-same-owner --wildcards '*.ttf'
  find "$tmp/fonts" -name '*.ttf' -print -quit | grep -q . || {
    echo '[FAIL] Nerd Font archive has no TrueType fonts' >&2; exit 1;
  }
  mkdir -p "$font_dir"
  cp -a "$tmp/fonts/." "$font_dir/"
  printf '%s\n' "$tag" > "$stamp"
  fc-cache -f "$font_dir"
  rm -rf -- "$tmp"
  trap - EXIT
  echo "[OK] Latest stable FiraCode Nerd Font $tag"
fi
# Pinned GTK theme source. Install into a staging dir, then move into place.
target="$HOME/.local/share/themes/Nordic"
if [[ ! -s "$target/index.theme" || ! -s "$target/gtk-3.0/gtk.css" ]]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf -- "$tmp"' EXIT
  git clone -q 'https://github.com/EliverLara/Nordic.git' "$tmp/nordic"
  rev='be5bda37ba01139650e34238336e58e065d2f406'
  git -C "$tmp/nordic" checkout -q --detach "$rev"
  [[ "$(git -C "$tmp/nordic" rev-parse HEAD)" == "$rev" ]] || {
    echo '[FAIL] Nordic revision mismatch' >&2; exit 1;
  }
  mkdir -p "$tmp/stage"
  git -C "$tmp/nordic" archive HEAD | tar -x -C "$tmp/stage"
  [[ -s "$tmp/stage/index.theme" && -s "$tmp/stage/gtk-3.0/gtk.css" ]] || {
    echo '[FAIL] Nordic theme archive incomplete' >&2; exit 1;
  }
  mkdir -p "$target"
  cp -a "$tmp/stage/." "$target/"
  rm -rf -- "$tmp"
  trap - EXIT
fi
if command -v kwriteconfig6 >/dev/null; then
  kwriteconfig6 --file kdeglobals --group General --key ColorScheme KubuntuNord
  kwriteconfig6 --file kdeglobals --group General --key AccentColor '136,192,208'
  kwriteconfig6 --file kdeglobals --group General --key font 'FiraCode Nerd Font,12,-1,5,50,0,0,0,0,0'
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
bash "$ROOT/themes/install-nordzy-icons.sh"
echo '[OK] Nord color scheme, Nerd Font, GTK theme and icon theme installed'
