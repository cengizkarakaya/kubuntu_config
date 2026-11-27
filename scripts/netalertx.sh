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
    echo 'Image is pinned to a reviewed release digest; update the repository before applying a new release.'
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
        echo '[INFO] Applying the reviewed image digest in the current Compose file (not a floating latest tag).'
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
        # Upstream v26.10.28 hard-codes Flask/GraphQL to 0.0.0.0.
        # LISTEN_ADDR=127.0.0.1 applies only to nginx, NOT the API.
        # Report the binding without changing user-managed host firewall rules.
        if command -v ss >/dev/null 2>&1; then
            if ss -H -ltn 2>/dev/null | awk '
                $1 == "LISTEN" && $4 ~ /:20212$/ &&
                index($4, "127.0.0.1:") != 1 && index($4, "[::1]:") != 1 { found=1 }
                END { exit !found }
            '; then
                echo '[WARN] NetAlertX API port 20212 listens on a non-loopback address.'
                echo '[WARN] Upstream GraphQL binds 0.0.0.0; LISTEN_ADDR only controls the web UI.'
                echo '[HINT] Review host firewall rules; see docs/network-monitoring.md.'
            fi
        fi
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
