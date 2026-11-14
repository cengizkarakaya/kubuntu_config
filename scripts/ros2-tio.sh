#!/usr/bin/env bash
# Opt-in, non-destructive TIO description starter for the ROS 2 Lyrical dev service.
set -Eeuo pipefail
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$REPO_ROOT/robotics/tio_description"
ROBOTICS_ROOT="${ROBOTICS_ROOT:-$HOME/Workspaces/Robotics}"
DEST="$ROBOTICS_ROOT/tio_ws/src/tio_description"
COMPOSE="$REPO_ROOT/robotics/ros2/compose.yaml"
ROS_UID="$(id -u)"
ROS_GID="$(id -g)"
mode="${1:-help}"

if (( EUID == 0 )); then
  echo '[FAIL] Run as your desktop user; Docker access is requested with sudo.' >&2
  exit 2
fi
[[ "$ROBOTICS_ROOT" == /* ]] || { echo '[FAIL] ROBOTICS_ROOT must be an absolute path.' >&2; exit 2; }
[[ -f "$TEMPLATE/package.xml" && -f "$COMPOSE" ]] || {
  echo '[FAIL] TIO template or ROS 2 Compose file missing.' >&2; exit 2;
}
if [[ -L "$DEST" ]]; then
  echo '[FAIL] Destination is a symlink. Refusing to modify it.' >&2; exit 2;
fi

compose_sudo() {
  sudo env ROS_UID="$ROS_UID" ROS_GID="$ROS_GID" ROBOTICS_ROOT="$ROBOTICS_ROOT" \
    docker compose -f "$COMPOSE" "$@"
}
case "$mode" in
  --plan|plan)
    printf 'Template: %s\nHost project: %s\n' "$TEMPLATE" "$DEST"
    if [[ -e "$DEST" ]]; then
      if [[ -d "$DEST" ]] && diff -qr "$TEMPLATE" "$DEST" >/dev/null; then
        echo '[OK] TIO source already matches the starter template.'
      else
        echo '[INFO] A TIO source directory already exists and differs; init will NOT overwrite it.'
      fi
    else
      echo '[INFO] init will copy the starter package once, preserving all later user edits.'
    fi
    echo '[INFO] No host files or Docker containers changed.'
    ;;
  --init|init)
    [[ ! -e "$DEST" ]] || {
      if [[ -d "$DEST" ]] && diff -qr "$TEMPLATE" "$DEST" >/dev/null; then
        echo '[OK] TIO starter already installed (identical); nothing changed.'
        exit 0
      fi
      echo "[FAIL] Refusing to overwrite an existing TIO project: $DEST" >&2
      exit 1
    }
    mkdir -p -- "$ROBOTICS_ROOT/tio_ws/src"
    cp -a -- "$TEMPLATE" "$DEST"
    printf '[OK] Starter TIO package copied to %s\n' "$DEST"
    ;;
  --build|build)
    [[ -f "$DEST/package.xml" ]] || {
      echo '[FAIL] Run: bash scripts/ros2-tio.sh init' >&2; exit 1;
    }
    compose_sudo exec --no-TTY dev bash -lc '
      set -e
      source /opt/ros/lyrical/setup.bash
      cd /workspaces/tio_ws
      colcon build --symlink-install --packages-select tio_description
      source install/setup.bash
      ros2 pkg prefix tio_description
      xacro src/tio_description/urdf/tio.urdf.xacro > /tmp/tio-validated.urdf
      test -s /tmp/tio-validated.urdf
      echo "[OK] tio_description compiled, indexed and Xacro expanded successfully."
    '
    ;;
  --run|run)
    [[ -f "$DEST/package.xml" ]] || {
      echo '[FAIL] TIO project not initialized.' >&2; exit 1;
    }
    echo '[INFO] Publishing /robot_description, /joint_states and TF; Ctrl+C stops these nodes.'
    compose_sudo exec dev bash -lc '
      set -e
      source /opt/ros/lyrical/setup.bash
      source /workspaces/tio_ws/install/setup.bash
      exec ros2 launch tio_description display.launch.py
    '
    ;;
  --status|status)
    compose_sudo exec --no-TTY dev bash -lc '
      source /opt/ros/lyrical/setup.bash
      ros2 node list
      ros2 topic list
    '
    ;;
  --help|help|-h)
    printf 'Usage: bash scripts/ros2-tio.sh [plan|init|build|run|status]\n'
    echo 'This is a provisional visual/kinematic description, not a measured CAD model.'
    echo 'The init command NEVER overwrites an existing TIO source folder.'
    ;;
  *)
    echo "[FAIL] Unknown command: $mode" >&2
    exit 2
    ;;
esac
