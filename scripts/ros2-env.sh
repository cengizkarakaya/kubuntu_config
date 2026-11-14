#!/usr/bin/env bash
# User-friendly ROS 2 Compose commands while keeping Docker rootful access explicit.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE="$ROOT/robotics/ros2/compose.yaml"
ROBOTICS_ROOT="${ROBOTICS_ROOT:-$HOME/Workspaces/Robotics}"
ROS_UID="$(id -u)"
ROS_GID="$(id -g)"
mode="${1:---help}"

if (( EUID == 0 )); then
  echo 'Run as the desktop user; this script requests sudo only for Docker operations.' >&2
  exit 2
fi
[[ "$ROBOTICS_ROOT" == /* ]] || { echo 'ROBOTICS_ROOT must be an absolute path.' >&2; exit 2; }
[[ -f "$COMPOSE" ]] || { echo "Missing Compose file: $COMPOSE" >&2; exit 2; }

compose_user() {
  env ROS_UID="$ROS_UID" ROS_GID="$ROS_GID" ROBOTICS_ROOT="$ROBOTICS_ROOT" \
    docker compose -f "$COMPOSE" "$@"
}
compose_sudo() {
  sudo env ROS_UID="$ROS_UID" ROS_GID="$ROS_GID" ROBOTICS_ROOT="$ROBOTICS_ROOT" \
    docker compose -f "$COMPOSE" "$@"
}

case "$mode" in
  --plan|plan)
    compose_user config --quiet
    echo "[OK] Compose syntax and interpolation validated. Workspaces: $ROBOTICS_ROOT"
    echo '[INFO] No images built, containers started or host files created.'
    ;;
  --up|up)
    mkdir -p "$ROBOTICS_ROOT/tio_ws/src" "$ROBOTICS_ROOT/rova_ws/src"
    compose_user config --quiet
    compose_sudo up --detach --build dev
    echo '[OK] ROS 2 dev service requested. Run: bash scripts/ros2-env.sh check'
    ;;
  --shell|shell)
    # Bash supports -i, not the long-form --interactive option.
    compose_sudo exec dev bash -i
    ;;
  --check|check)
    compose_sudo exec --no-TTY dev bash -lc '
      set -e
      source /opt/ros/lyrical/setup.bash
      test "$ROS_DISTRO" = lyrical
      command -v ros2
      command -v colcon
      command -v vcs
      test "$(id -u)" != 0
      test -d /workspaces/tio_ws/src
      test -d /workspaces/rova_ws/src
      touch /workspaces/tio_ws/.write-check /workspaces/rova_ws/.write-check
      rm -f /workspaces/tio_ws/.write-check /workspaces/rova_ws/.write-check
      printf "[OK] ROS_DISTRO=%s user=%s domain=%s\n" "$ROS_DISTRO" "$(id -u)" "$ROS_DOMAIN_ID"
      printf "[OK] colcon and both writable host workspaces available\n"
    '
    ;;
  --status|status)
    compose_sudo ps
    ;;
  --down|down)
    compose_sudo down
    echo '[OK] Development container stopped; workspaces and image preserved.'
    ;;
  --help|-h|help)
    printf 'Usage: bash scripts/ros2-env.sh [plan|up|check|shell|status|down]\n'
    printf 'Workspace root (default): %s\n' "$ROBOTICS_ROOT"
    printf 'No ROS packages or NVIDIA devices are installed on Kubuntu host.\n'
    ;;
  *)
    echo "Unknown command: $mode" >&2
    exit 2
    ;;
esac
