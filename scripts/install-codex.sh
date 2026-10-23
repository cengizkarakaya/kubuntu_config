#!/usr/bin/env bash
set -Eeuo pipefail

export PATH="$HOME/.local/bin:$PATH"

codex_home="${CODEX_HOME:-$HOME/.codex}"
existing="$(command -v codex || true)"
install_codex=true

if [[ -n "$existing" ]]; then
    echo "[INFO] Existing Codex: $(codex --version)"
    resolved="$(readlink -f "$existing")"

    case "$resolved" in
        "$codex_home"/packages/standalone/*)
            echo "[INFO] Updating standalone Codex"
            ;;
        *)
            echo "[WARN] Codex is managed externally; preserving it"
            install_codex=false
            ;;
    esac
fi

# Back up existing configuration outside Git.
mkdir -p "$codex_home"
backup_dir="$HOME/.local/state/kubuntu-config/backups"
mkdir -p "$backup_dir"
chmod 700 "$backup_dir"

stamp="$(date +%Y%m%d-%H%M%S)-$$"

for file in config.toml hooks.json; do
    if [[ -f "$codex_home/$file" ]]; then
        cp -p "$codex_home/$file" \
            "$backup_dir/codex-${file}-${stamp}.bak"
        chmod 600 "$backup_dir/codex-${file}-${stamp}.bak"
    fi
done

if [[ "$install_codex" == true ]]; then
    tmp="$(mktemp)"
    trap 'rm -f -- "$tmp"' EXIT

    curl --proto '=https' --tlsv1.2 -fsSL \
        https://chatgpt.com/codex/install.sh \
        -o "$tmp"

    sh -n "$tmp"
    CODEX_NON_INTERACTIVE=1 sh "$tmp"
fi

command -v codex >/dev/null
codex --version

command -v herdr >/dev/null
herdr integration install codex

echo "[OK] Codex and Herdr integration configured"
