#!/usr/bin/env bash
# Minimal rootful-Docker wrapper. Never add the desktop user to docker group.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE="$ROOT/network/netalertx/compose.yaml"
ACTION="${1:-plan}"
[[ $# -le 1 ]] || { echo 'Usage: bash scripts/netalertx.sh [plan|up|update|check|logs|down]' >&2; exit 2; }
case "$ACTION" in plan|up|update|check|logs|down) ;; *) echo "[FAIL] Unknown action: $ACTION" >&2; exit 2;; esac
(( EUID != 0 )) || { echo '[FAIL] Run as normal user (script prompts for sudo only when necessary).' >&2; exit 2; }
command -v docker >/dev/null 2>&1 || { echo '[FAIL] Docker Engine CLI missing' >&2; exit 1; }
docker compose version >/dev/null || { echo '[FAIL] Docker Compose v2 plugin missing' >&2; exit 1; }
docker compose -p kubuntu-netalertx -f "$COMPOSE" config --quiet || {
    echo '[FAIL] NetAlertX Compose configuration is invalid' >&2; exit 1;
}
if [[ "$ACTION" == plan ]]; then
    echo 'NetAlertX opt-in plan: GHCR official image, rootful Docker via sudo, host networking.'
    echo 'Web interface: http://127.0.0.1:20211 (localhost only).'
    echo 'GraphQL/API may still listen separately; inspect firewall/ports on your host.'
    echo 'Data volume: kubuntu-netalertx_netalertx_data (NOT stored in the public Git repository).'
    echo 'Required capture capabilities: NET_RAW, NET_ADMIN and NET_BIND_SERVICE.'
    echo 'Recommended local interface/subnet (confirm in the NetAlertX Settings UI):'
    if command -v ip >/dev/null 2>&1; then
        ip -4 route show default || true
        ip -o -4 addr show scope global || true
    fi
    echo 'Start: bash scripts/netalertx.sh up'
    exit 0
fi
# sudo stays on the docker invocation; never modify group membership.
docker_root() { sudo docker "$@"; }
compose_root() { docker_root compose -p kubuntu-netalertx -f "$COMPOSE" "$@"; }
case "$ACTION" in
    up)
        # Explicit action: install/start and keep discovery running when workstation is on.
        compose_root up -d --no-build
        compose_root ps
        ;;
    update)
        compose_root pull
        compose_root up -d --no-build
        compose_root ps
        ;;
    check)
        compose_root ps
        [[ "$(docker_root inspect --format '{{.State.Running}}' kubuntu-netalertx 2>/dev/null || true)" == true ]] || {
            echo '[FAIL] NetAlertX container is not running' >&2; exit 1;
        }
        echo '[OK] NetAlertX container is running (application discovery must be checked in UI)'
        ;;
    logs)
        compose_root logs --tail 100
        ;;
    down)
        # Never delete named volumes or user data.
        compose_root down
        echo '[OK] NetAlertX stopped; the named data volume was preserved'
        ;;
esac
