#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CORE_ONLY=0
SKIP_PLASMA=0
for arg in "$@"; do
  case "$arg" in
    --core-only) CORE_ONLY=1 ;;
    --skip-plasma) SKIP_PLASMA=1 ;;
    -h|--help) printf 'Usage: bash bootstrap.sh [--core-only] [--skip-plasma]\n'; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$arg" >&2; exit 2 ;;
  esac
done
(( EUID != 0 )) || { echo 'Run as a regular user, NEVER with sudo/root.' >&2; exit 2; }
[[ -n "${HOME:-}" && -d "$HOME" ]] || { echo 'HOME is not valid' >&2; exit 2; }
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
command -v flock >/dev/null || { echo 'util-linux/flock is required' >&2; exit 2; }
STATE="$HOME/.local/state/kubuntu-config"
mkdir -p "$STATE"
exec 9>"$STATE/bootstrap.lock"
flock -n 9 || { echo 'Another bootstrap instance is running' >&2; exit 1; }
LOG="$STATE/bootstrap-$(date +%Y%m%d-%H%M%S)-$$.log"
exec > >(tee -a "$LOG") 2>&1
CURRENT_STAGE='preflight'
trap 'rc=$?; echo "[FAIL] Stage: $CURRENT_STAGE, exit: $rc, line: $LINENO" >&2; echo "See $LOG" >&2' ERR
source /etc/os-release
[[ "${ID:-}" == ubuntu ]] || { echo 'Only Ubuntu-based Kubuntu is supported' >&2; exit 2; }
dpkg --compare-versions "${VERSION_ID:-0}" ge 26.04 || { echo 'Requires Kubuntu 26.04 or newer' >&2; exit 2; }
command -v plasmashell >/dev/null || { echo 'KDE Plasma desktop is required' >&2; exit 2; }
if [[ "${XDG_SESSION_TYPE:-}" != wayland && "$SKIP_PLASMA" == 0 && "$CORE_ONLY" == 0 ]]; then
  echo '[FAIL] Polonium supports Wayland only. Log into Plasma (Wayland) or use --skip-plasma.' >&2
  exit 1
fi
available_kb="$(df -Pk "$HOME" | awk 'NR==2 {print $4}')"
if [[ "$CORE_ONLY" == 0 && "$available_kb" =~ ^[0-9]+$ ]] && ((available_kb < 8 * 1024 * 1024)); then
  echo '[FAIL] At least 8 GiB of free disk space is required for the full setup.' >&2; exit 1
fi
echo "Kubuntu ${VERSION_ID}; session ${XDG_SESSION_TYPE:-unknown}; logfile: $LOG"
sudo -v
stage() {
  CURRENT_STAGE="$1"
  shift
  echo
  echo "==> $CURRENT_STAGE"
  "$@"
  echo "[OK] $CURRENT_STAGE"
}
stage 'APT prerequisites and cache' bash -c 'sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg git'
stage 'Brave browser' bash "$ROOT/scripts/install-brave.sh"
command -v brave-browser >/dev/null || { echo '[FAIL] Brave was not installed' >&2; exit 1; }
if ((CORE_ONLY)); then echo '[OK] Core-only finished. Run bash bootstrap.sh to continue.'; exit 0; fi
stage 'VS Code' bash "$ROOT/scripts/install-vscode.sh"
stage 'Official Yazi stable repository' bash "$ROOT/scripts/setup-yazi-apt.sh"
stage 'APT package manifest' bash "$ROOT/scripts/install-apt.sh" "$ROOT/packages/apt.txt"
stage 'Rust toolchain' bash "$ROOT/scripts/install-rust.sh"
stage 'Herdr pinned stable binary' bash "$ROOT/scripts/install-herdr.sh"
stage 'libvirt setup' bash "$ROOT/scripts/setup-libvirt.sh"
stage 'Flatpak applications' bash "$ROOT/scripts/install-flatpaks.sh"
stage 'Portable dotfiles' bash "$ROOT/scripts/stow-dotfiles.sh"
stage 'Yazi search helper' install -Dm755 "$ROOT/scripts/yazi-rg" "$HOME/.local/bin/yazi-rg"
stage 'Pinned Arch Yazi plugins and Nord flavor' bash "$ROOT/scripts/install-yazi-plugins.sh"
stage 'Shell integration' bash "$ROOT/scripts/setup-shell.sh"
stage 'Default applications' bash "$ROOT/scripts/setup-defaults.sh"
stage 'Nord appearance' bash "$ROOT/themes/setup.sh"
if ((SKIP_PLASMA == 0)); then
  stage 'Plasma settings' bash "$ROOT/plasma/setup.sh"
  stage 'Polonium (pinned stable release)' bash "$ROOT/plasma/install-polonium.sh"
  stage 'Global shortcut configuration' bash "$ROOT/plasma/shortcuts.sh"
fi
stage 'User maintenance commands' install -Dm755 "$ROOT/scripts/sysup" "$HOME/.local/bin/sysup"
stage 'Latest-version audit (repository candidates, Flathub and GitHub)' bash "$ROOT/scripts/version-audit.sh"
install -Dm755 "$ROOT/verify.sh" "$HOME/.local/bin/kubuntu-verify"
CURRENT_STAGE='verification'
if ((SKIP_PLASMA)); then
  bash "$ROOT/verify.sh" --skip-plasma
else
  bash "$ROOT/verify.sh"
fi
echo '[OK] Installation inventory verified. Sign out and in; test actual KWin shortcuts and apps.'
echo 'No NVIDIA drivers, firmware, disk partitions, EFI or GRUB were modified.'
