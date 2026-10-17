#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")" && pwd)"
LOGDIR="$HOME/.local/state/kubuntu-config"; mkdir -p "$LOGDIR"
LOG="$LOGDIR/bootstrap-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1
trap 'echo "ERROR at line $LINENO; see bootstrap log" >&2' ERR
CORE_ONLY=0; SKIP_PLASMA=0
for arg in "$@"; do
  case "$arg" in
    --core-only) CORE_ONLY=1 ;;
    --skip-plasma) SKIP_PLASMA=1 ;;
    -h|--help) echo 'Usage: bash bootstrap.sh [--core-only] [--skip-plasma]'; exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done
(( EUID != 0 )) || { echo 'Run as a normal user, not root'; exit 2; }
source /etc/os-release
[[ "$ID" == ubuntu ]] || { echo 'Ubuntu/Kubuntu only'; exit 2; }
if ! command -v plasmashell >/dev/null && ! dpkg-query -W plasma-workspace >/dev/null 2>&1; then
  echo 'KDE Plasma is required'; exit 2
fi
echo "Kubuntu $VERSION_ID; log: $LOG"
sudo -v
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg git
# Open ChatGPT before the full creative-app installation.
bash "$ROOT/scripts/install-brave.sh"
command -v brave-browser >/dev/null || { echo 'Brave is missing'; exit 1; }
echo '[OK] Brave installed. Can start ChatGPT now.'
(( CORE_ONLY == 0 )) || exit 0
bash "$ROOT/scripts/install-vscode.sh"
bash "$ROOT/scripts/install-apt.sh" "$ROOT/packages/apt.txt"
bash "$ROOT/scripts/install-rust.sh"
bash "$ROOT/scripts/setup-libvirt.sh" || echo "[WARN] Libvirt requires manual attention"
bash "$ROOT/scripts/install-flatpaks.sh"
bash "$ROOT/scripts/stow-dotfiles.sh" || echo '[WARN] Review Stow collisions before retrying'
bash "$ROOT/scripts/install-yazi-plugins.sh" || echo "[WARN] Yazi plugin setup incomplete"
bash "$ROOT/scripts/setup-shell.sh"
bash "$ROOT/scripts/setup-defaults.sh"
bash "$ROOT/themes/setup.sh"
if (( SKIP_PLASMA == 0 )); then
  bash "$ROOT/plasma/setup.sh"
  bash "$ROOT/plasma/install-krohnkite.sh" || echo '[WARN] Krohnkite requires attention'
  bash "$ROOT/plasma/shortcuts.sh" || echo '[WARN] KDE shortcut review needed'
fi
install -Dm755 "$ROOT/scripts/sysup" "$HOME/.local/bin/sysup"
install -Dm755 "$ROOT/verify.sh" "$HOME/.local/bin/kubuntu-verify"
echo 'DONE. Review applications/addons.tsv; run bash verify.sh, then sign out/in.'
echo 'No NVIDIA driver, firmware, EFI, GRUB, partitions or kernel were changed.'
