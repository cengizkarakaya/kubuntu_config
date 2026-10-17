#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export DEBIAN_FRONTEND=noninteractive
if [[ $EUID -eq 0 ]]; then echo "Run as normal user (sudo is called when necessary)." >&2; exit 1; fi
source /etc/os-release
if [[ ${ID:-} != ubuntu ]] || ! command -v apt-get >/dev/null; then echo "Ubuntu/Kubuntu only"; exit 1; fi
if [[ "${XDG_CURRENT_DESKTOP:-}" != *KDE* && "${DESKTOP_SESSION:-}" != *plasma* ]]; then
 echo "WARNING: Plasma desktop session not detected; KDE user settings may not apply."
fi
if [[ ${1:-} == --help ]]; then echo "Usage: bash bootstrap.sh [--core-only]"; exit 0; fi
CORE_ONLY=false; [[ ${1:-} == --core-only ]] && CORE_ONLY=true
echo "==> Kubuntu baseline $VERSION_ID"
sudo -v
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg git
# Official Brave signed APT source, no pipe-to-shell installation.
sudo install -d -m 755 /usr/share/keyrings
curl --fail --location --retry 3 https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg -o /tmp/brave-browser-archive-keyring.gpg
sudo install -m 644 /tmp/brave-browser-archive-keyring.gpg /usr/share/keyrings/brave-browser-archive-keyring.gpg
rm -f /tmp/brave-browser-archive-keyring.gpg
curl --fail --location --retry 3 https://brave-browser-apt-release.s3.brave.com/brave-browser.sources -o /tmp/brave-browser.sources
sudo install -m 644 /tmp/brave-browser.sources /etc/apt/sources.list.d/brave-browser-release.sources
rm -f /tmp/brave-browser.sources
sudo apt-get update
sudo apt-get install -y brave-browser
echo "Brave installed early."
if "$CORE_ONLY"; then exit 0; fi
FAILED=()
while IFS= read -r pkg; do
 [[ -z "$pkg" || "$pkg" == \#* ]] && continue
 if apt-cache show "$pkg" >/dev/null 2>&1; then
   if ! sudo apt-get install -y "$pkg"; then FAILED+=("$pkg"); fi
 else FAILED+=("$pkg [not in current repos]"); fi
done < "$ROOT/packages/apt.txt"
mkdir -p "$HOME/.local/bin" "$HOME/.config"
# Portable files: import from authoritative Arch source using pinned commit
bash "$ROOT/scripts/import-arch.sh"
bash "$ROOT/scripts/stow-dotfiles.sh"
bash "$ROOT/plasma/setup.sh"
bash "$ROOT/themes/setup.sh"
if command -v flatpak >/dev/null 2>&1; then
 sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
 while read -r app _; do
  [[ -z "$app" || "$app" == \#* ]] && continue
  if ! flatpak install --user -y flathub "$app"; then FAILED+=("Flatpak: $app"); fi
 done < "$ROOT/packages/flatpak.tsv"
fi
ln -sfn "$ROOT/scripts/sysup" "$HOME/.local/bin/sysup"
echo
echo "==> Package installation warnings:"
if (("${#FAILED[@]}")); then printf ' - %s\n' "${FAILED[@]}"; else echo " none"; fi
echo "==> Manual addons: applications/addons.tsv (not silently assumed installed)"
echo "==> Run ./verify.sh and review plasma/shortcuts.md"
echo "==> NVIDIA: ubuntu-drivers devices; review before installing anything."
echo "==> Log out and log in to apply desktop changes."
