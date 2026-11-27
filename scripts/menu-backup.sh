#!/usr/bin/env bash
# KDE Application Launcher: private capture, portable copy, preview and restore.
# Does not touch installed programs, KWin, KScreen, panels or NVIDIA settings.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
STATE="$(realpath -m -- "${XDG_STATE_HOME:-$HOME/.local/state}/kubuntu-config")"
PRIVATE="$STATE/menu-current"
PORTABLE="$STATE/menu-portable"
mode="${1:---help}"
(( EUID != 0 )) || { echo 'Never run as root.' >&2; exit 2; }
umask 077
HELPER="$ROOT/scripts/menu-snapshot.py"

# Even a custom XDG state path must never put private data in a Git checkout.
case "$STATE/" in "$ROOT/"*) echo '[FAIL] Private state must be outside the repository.' >&2; exit 2 ;; esac
ancestor="$STATE"
while [[ "$ancestor" != / ]]; do
  if [[ -e "$ancestor/.git" || -L "$ancestor/.git" ]]; then
    echo '[FAIL] Private state must be outside Git worktrees.' >&2; exit 2
  fi
  ancestor="$(dirname -- "$ancestor")"
done

private_dir() {
  local dir="$1" perms
  [[ -d "$dir" && ! -L "$dir" && "$(stat -c %u -- "$dir")" == "$EUID" ]] || return 1
  perms="$(stat -c %a -- "$dir")"
  (( (8#$perms & 077) == 0 ))
}

copy_menu_files() {
  local origin="$1" dest="$2" logical="$3" file relative listing
  [[ -d "$origin" ]] || return 0
  listing="$(mktemp "$dest/.files.XXXXXXXX")"
  # Do not mask a failed find in process substitution.
  find "$origin" -type f \( -name '*.desktop' -o -name '*.directory' -o -name '*.menu' \) -print0 > "$listing"
  while IFS= read -r -d '' file; do
    relative="$logical/${file#"$origin/"}"
    mkdir -p "$dest/$(dirname -- "$relative")"
    cp -p -- "$file" "$dest/$relative"
  done < "$listing"
  rm -- "$listing"
}

publish_private() {
  local target="$1" previous="$2" archive
  if [[ -e "$target" || -L "$target" ]]; then
    private_dir "$target" || { echo '[FAIL] Existing snapshot is not a private directory.' >&2; exit 1; }
    archive="$STATE/$previous-$(date +%Y%m%d-%H%M%S)-$$"
    mv -T -- "$target" "$archive"
    printf 'Previous private snapshot: %s\n' "$archive"
  fi
  mv -T -- "$tmp" "$target"
  trap - EXIT
}

case "$mode" in
  --capture)
    mkdir -p "$STATE"
    tmp="$(mktemp -d "$STATE/.menu-current.XXXXXXXX")"
    trap 'rm -rf -- "$tmp"' EXIT
    copy_menu_files "${XDG_DATA_HOME:-$HOME/.local/share}/applications" "$tmp" .local/share/applications
    copy_menu_files "${XDG_DATA_HOME:-$HOME/.local/share}/desktop-directories" "$tmp" .local/share/desktop-directories
    copy_menu_files "${XDG_CONFIG_HOME:-$HOME/.config}/menus" "$tmp" .config/menus
    publish_private "$PRIVATE" menu-previous
    echo "Private capture: $PRIVATE"
    echo 'This is NOT on GitHub. Use --prepare-private for a portable local copy.'
    ;;
  --prepare-private)
    private_dir "$PRIVATE" || { echo '[FAIL] Capture first; source must be a private directory.' >&2; exit 1; }
    tmp="$(mktemp -d "$STATE/.menu-portable.XXXXXXXX")"
    trap 'rm -rf -- "$tmp"' EXIT
    cp -a "$PRIVATE/." "$tmp/"
    python3 "$HELPER" template "$tmp" "$HOME"
    publish_private "$PORTABLE" menu-portable-previous
    echo "Private portable snapshot: $PORTABLE"
    echo 'Review and back up outside Git. @HOME@ is portability, not anonymization.'
    ;;
  --stage-repo)
    echo '[FAIL] Public staging is disabled. Use --prepare-private instead.' >&2
    exit 2
    ;;
  --plan-restore|--restore)
    private_dir "$PORTABLE" || {
      echo '[FAIL] No private portable menu snapshot. Prepare or recover it from your private backup.' >&2
      exit 1
    }
    if [[ "${XDG_CONFIG_HOME:-$HOME/.config}" != "$HOME/.config" ||
          "${XDG_DATA_HOME:-$HOME/.local/share}" != "$HOME/.local/share" ]]; then
      echo '[FAIL] Custom XDG restore destinations require manual review.' >&2
      exit 2
    fi
    if [[ "$mode" == --plan-restore ]]; then
      python3 "$HELPER" plan "$PORTABLE" "$HOME"
    else
      [[ -t 0 ]] || { echo '[FAIL] Restore requires interactive confirmation.' >&2; exit 1; }
      python3 "$HELPER" plan "$PORTABLE" "$HOME"
      echo 'Restoring reviewed private KDE launcher files; conflicts will be backed up first.'
      read -r -p 'Type RESTORE to proceed: ' confirmation
      [[ "$confirmation" == RESTORE ]] || { echo 'Cancelled'; exit 1; }
      backup="$(mktemp -d "$STATE/menu-restore-before.XXXXXXXX")"
      python3 "$HELPER" restore "$PORTABLE" "$HOME" --backup "$backup"
      echo "Original conflicts backed up: $backup"
      if command -v kbuildsycoca6 >/dev/null; then
        kbuildsycoca6 --noincremental || echo '[WARN] Menu cache refresh failed.' >&2
      fi
      echo 'Log out/in if KDE still shows old categories. Verify launchers on this machine.'
    fi
    ;;
  *)
    echo 'Usage: bash scripts/menu-backup.sh --capture | --prepare-private | --plan-restore | --restore'
    echo 'Snapshots remain private; restoration requires typed confirmation.'
    ;;
esac
