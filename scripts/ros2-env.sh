#!/usr/bin/env bash
# User-friendly ROS 2 Compose commands while keeping Docker rootful access explicit.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE="$ROOT/robotics/ros2/compose.yaml"
RVIZ_COMPOSE="$ROOT/robotics/ros2/compose.rviz.yaml"
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

# RViz2 is opt-in. The X11 auth cookie lives only in the user's runtime
# directory; never stage it in this public Git repository.
rviz_auth_path() {
  [[ -n "${XDG_RUNTIME_DIR:-}" && -d "$XDG_RUNTIME_DIR" ]] || {
    echo '[FAIL] XDG_RUNTIME_DIR is missing; run from a logged-in Plasma desktop session.' >&2
    return 1
  }
  printf '%s/kubuntu-ros2/rviz.xauth\n' "$XDG_RUNTIME_DIR"
}
compose_rviz_user() {
  local auth="$1"; shift
  env ROS_UID="$ROS_UID" ROS_GID="$ROS_GID" ROBOTICS_ROOT="$ROBOTICS_ROOT" \
    RVIZ_XAUTH="$auth" DISPLAY="${DISPLAY:-}" \
    docker compose -f "$COMPOSE" -f "$RVIZ_COMPOSE" --profile gui "$@"
}
compose_rviz_sudo() {
  local auth="$1"; shift
  sudo env ROS_UID="$ROS_UID" ROS_GID="$ROS_GID" ROBOTICS_ROOT="$ROBOTICS_ROOT" \
    RVIZ_XAUTH="$auth" DISPLAY="${DISPLAY:-}" \
    docker compose -f "$COMPOSE" -f "$RVIZ_COMPOSE" --profile gui "$@"
}
rviz_display_preflight() {
  local display_number
  [[ -n "${DISPLAY:-}" && "$DISPLAY" == :* ]] || {
    echo '[FAIL] A local XWayland DISPLAY such as :0 is required.' >&2; return 1;
  }
  display_number="${DISPLAY#:}"
  display_number="${display_number%%.*}"
  [[ "$display_number" =~ ^[0-9]+$ && -S "/tmp/.X11-unix/X$display_number" ]] || {
    echo "[FAIL] XWayland socket missing for DISPLAY=$DISPLAY" >&2; return 1;
  }
  command -v xauth >/dev/null || {
    echo '[FAIL] Install host xauth first: sudo apt install xauth' >&2; return 1;
  }
  [[ -n "$(xauth nlist "$DISPLAY" 2>/dev/null || true)" ]] || {
    echo '[FAIL] No Xauthority cookie for DISPLAY. Inspect DISPLAY/XAUTHORITY in the Plasma session.' >&2
    return 1
  }
}
rviz_generate_cookie() {
  local auth_file auth_dir temp entries
  auth_file="$(rviz_auth_path)" || return 1
  auth_dir="$(dirname -- "$auth_file")"
  (umask 077; mkdir -p -m 700 "$auth_dir")
  temp="$(mktemp "$auth_dir/.rviz-auth.XXXXXXXX")"
  # FamilyWild (ffff) works despite differing X11 hostnames within the container.
  # Keep the original server cookie; do not weaken X server access control.
  entries="$(xauth nlist "$DISPLAY")"
  if ! printf '%s\n' "$entries" | sed 's/^..../ffff/' | xauth -f "$temp" nmerge -; then
    rm -f -- "$temp"
    return 1
  fi
  if [[ -z "$(xauth -f "$temp" list 2>/dev/null || true)" ]]; then
    rm -f -- "$temp"
    echo '[FAIL] Xauthority cookie export was empty.' >&2
    return 1
  fi
  chmod 600 "$temp"
  mv -f -- "$temp" "$auth_file"
  printf '%s\n' "$auth_file"
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
  --rviz-plan|rviz-plan)
    auth="$(rviz_auth_path)"
    compose_rviz_user "$auth" config --quiet
    echo '[OK] Opt-in RViz2 Compose overlay parses correctly. No GPU/window launched.'
    ;;
  --rviz-up|rviz-up)
    rviz_display_preflight
    command -v nvidia-smi >/dev/null || {
      echo '[FAIL] NVIDIA driver unavailable on host.' >&2; exit 1;
    }
    nvidia-smi -L
    auth="$(rviz_generate_cookie)"
    echo "[INFO] Private Xauthority cookie: $auth"
    # RViz joins dev's local DDS network and shared IPC; this may recreate dev.
    compose_rviz_sudo "$auth" up --detach --build --force-recreate rviz
    echo '[OK] RViz2 viewer service started. Run: bash scripts/ros2-env.sh rviz-check'
    ;;
  --rviz-check|rviz-check)
    auth="$(rviz_auth_path)"
    [[ -f "$auth" ]] || { echo '[FAIL] Run rviz-up to create the X11 cookie first.' >&2; exit 1; }
    compose_rviz_sudo "$auth" exec --no-TTY rviz bash -lc '
      set -e
      source /opt/ros/lyrical/setup.bash
      test "$ROS_DISTRO" = lyrical
      command -v rviz2
      nvidia-smi -L
      glxinfo -B
      renderer="$(glxinfo -B | sed -n "s/^OpenGL renderer string: //p" | head -n 1)"
      case "$renderer" in
        *NVIDIA*|*GeForce*|*RTX*) printf "[OK] NVIDIA OpenGL renderer: %s\n" "$renderer";;
        *) printf "[FAIL] Unexpected OpenGL renderer: %s\n" "$renderer" >&2; exit 1;;
      esac
    '
    ;;
  --rviz|rviz)
    auth="$(rviz_auth_path)"
    [[ -f "$auth" ]] || { echo '[FAIL] Run rviz-up first.' >&2; exit 1; }
    echo '[INFO] Starting RViz2 GUI; Ctrl+C closes the GUI without deleting workspaces.'
    compose_rviz_sudo "$auth" exec rviz bash -lc 'source /opt/ros/lyrical/setup.bash && exec rviz2'
    ;;
  --rviz-stop|rviz-stop)
    auth="$(rviz_auth_path)"
    compose_rviz_sudo "$auth" stop rviz
    echo '[OK] RViz2 viewer stopped. The development service remains available.'
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
