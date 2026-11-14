#!/usr/bin/env bash
# KDE Application Launcher: capture, explicitly publish, preview and safely restore.
# Does not touch installed programs, KWin, KScreen, panels or NVIDIA settings.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/kubuntu-config"
PRIVATE="$STATE/menu-current"
PUBLIC="$ROOT/backups/application-launcher/snapshot"
mode="${1:---help}"
(( EUID != 0 )) || { echo 'Never run as root.' >&2; exit 2; }
mkdir -p "$STATE"

copy_menu_files() {
  local origin="$1" dest="$2" file relative
  [[ -d "$origin" ]] || return 0
  while IFS= read -r -d '' file; do
    relative="${file#"$HOME/"}"
    mkdir -p "$dest/$(dirname -- "$relative")"
    cp -p -- "$file" "$dest/$relative"
  done < <(find "$origin" -type f \( -name '*.desktop' -o -name '*.directory' -o -name '*.menu' \) -print0)
}

case "$mode" in
  --capture)
    tmp="$(mktemp -d "$STATE/.menu-current.XXXXXXXX")"
    trap 'rm -rf -- "$tmp"' EXIT
    copy_menu_files "${XDG_DATA_HOME:-$HOME/.local/share}/applications" "$tmp"
    copy_menu_files "${XDG_DATA_HOME:-$HOME/.local/share}/desktop-directories" "$tmp"
    copy_menu_files "${XDG_CONFIG_HOME:-$HOME/.config}/menus" "$tmp"
    if [[ -d "$PRIVATE" ]]; then
      archive="$STATE/menu-previous-$(date +%Y%m%d-%H%M%S)-$$"
      mv -- "$PRIVATE" "$archive"
      printf 'Previous private capture: %s\n' "$archive"
    fi
    mv -- "$tmp" "$PRIVATE"
    trap - EXIT
    echo "Private capture: $PRIVATE"
    echo 'This is NOT on GitHub. Check .desktop Exec lines and .menu paths before --stage-repo.'
    ;;
  --stage-repo)
    [[ -d "$PRIVATE" ]] || { echo 'Run --capture first.' >&2; exit 1; }
    echo 'CAUTION: This GitHub repository is PUBLIC.'
    echo 'Desktop entries may contain private paths, URLs, command arguments, tokens or secrets.'
    if grep -RinEi '(password[=:]|access[_-]?token[=:]|api[_-]?key[=:]|authorization[=:]|client[_-]?secret[=:])' "$PRIVATE"; then
      echo '[FAIL] Potential secret detected. Remove it from the private capture before publishing.' >&2
      exit 1
    fi
    echo "Review files in: $PRIVATE"
    [[ -t 0 ]] || { echo '[FAIL] Public export requires interactive approval.' >&2; exit 1; }
    read -r -p 'Type PUBLISH to stage these files in the PUBLIC Git repository: ' confirmation
    [[ "$confirmation" == PUBLISH ]] || { echo 'Cancelled'; exit 1; }
    mkdir -p "$(dirname -- "$PUBLIC")"
    tmp="$(mktemp -d "$(dirname -- "$PUBLIC")/.snapshot.XXXXXXXX")"
    trap 'rm -rf -- "$tmp"' EXIT
    cp -a "$PRIVATE/." "$tmp/"
    if [[ -e "$PUBLIC" ]]; then
      mv -- "$PUBLIC" "$STATE/menu-staged-previous-$(date +%Y%m%d-%H%M%S)-$$"
    fi
    mv -- "$tmp" "$PUBLIC"
    trap - EXIT
    echo "Staged locally in repository: $PUBLIC"
    echo 'Not pushed. Review: git status --short && git diff --no-index /dev/null backups/application-launcher/snapshot/...'
    echo 'Only after reviewing ALL files: git add backups/application-launcher/snapshot && git commit && git push'
    ;;
  --plan-restore|--restore)
    [[ -d "$PUBLIC" ]] || {
      echo "No tracked menu snapshot: $PUBLIC" >&2
      echo 'Capture on the original Kubuntu desktop, stage and commit it before reinstalling.' >&2
      exit 1
    }
    if [[ "$mode" == --restore ]]; then
      [[ -t 0 ]] || { echo '[FAIL] Restore requires interactive confirmation.' >&2; exit 1; }
      echo 'Restoring user KDE launcher files; conflicts will be backed up first.'
      read -r -p 'Type RESTORE to proceed: ' confirmation
      [[ "$confirmation" == RESTORE ]] || { echo 'Cancelled'; exit 1; }
      backup="$STATE/menu-restore-before-$(date +%Y%m%d-%H%M%S)-$$"
      mkdir -p "$backup"
    fi
    count=0
    while IFS= read -r -d '' file; do
      relative="${file#"$PUBLIC/"}"
      case "$relative" in
        .local/share/applications/*.desktop|.local/share/desktop-directories/*.directory|.config/menus/*.menu) ;;
        *) echo "[SKIP] Unexpected path: $relative" >&2; continue ;;
      esac
      dest="$HOME/$relative"
      [[ ! -L "$dest" ]] || { echo "[SKIP] Symlink target: $dest"; continue; }
      if [[ -e "$dest" ]] && cmp -s "$file" "$dest"; then continue; fi
      if [[ "$mode" == --plan-restore ]]; then
        echo "[PLAN] $relative $( [[ -e "$dest" ]] && echo '(replace with backup)' || echo '(new)' )"
      else
        if [[ -e "$dest" ]]; then
          mkdir -p "$backup/$(dirname -- "$relative")"
          cp -p -- "$dest" "$backup/$relative"
        fi
        mkdir -p "$(dirname -- "$dest")"
        cp -p -- "$file" "$dest"
        echo "[RESTORED] $relative"
      fi
      ((count+=1))
    done < <(find "$PUBLIC" -type f \( -name '*.desktop' -o -name '*.directory' -o -name '*.menu' \) -print0)
    echo "Changed/needed: $count"
    if [[ "$mode" == --restore ]]; then
      [[ ! -d "$backup" ]] || echo "Original conflicts backed up: $backup"
      if command -v kbuildsycoca6 >/dev/null; then
        kbuildsycoca6 --noincremental || echo '[WARN] Menu cache refresh failed.' >&2
      fi
      echo 'Log out/in if KDE still shows old categories. Verify launchers on this machine.'
    fi
    ;;
  *)
    echo 'Usage: bash scripts/menu-backup.sh --capture | --stage-repo | --plan-restore | --restore'
    echo 'Capture is private by default. Publishing and restoration require typed confirmation.'
    ;;
esac
