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
# Persist the entire ~/.rviz2 directory as a host bind mount. When the
# previous container exists, preserve its first-run persistent_settings file
# before the new mount obscures the old container-local settings.
rviz_prepare_config() {
  local auth="$1" dest="$ROBOTICS_ROOT/rviz2-config" existing temp
  if [[ -L "$dest" || ( -e "$dest" && ! -d "$dest" ) ]]; then
    echo "[FAIL] RViz config destination is not a normal directory: $dest" >&2
    return 1
  fi
  if [[ ! -d "$dest" ]]; then
    (umask 077; mkdir -p -- "$dest")
  fi
  # Do not replace existing host settings. A failed import is reported,
  # and the original container remains unchanged until the Compose restart.
  if [[ ! -e "$dest/persistent_settings" ]]; then
    existing="$(compose_rviz_sudo "$auth" ps -q rviz 2>/dev/null || true)"
    if [[ -n "$existing" ]]; then
      temp="$(mktemp "$dest/.persistent_settings.import.XXXXXXXX")"
      if compose_rviz_sudo "$auth" exec --no-TTY rviz \
          cat /home/rosdev/.rviz2/persistent_settings > "$temp" && [[ -s "$temp" ]]; then
        mv -- "$temp" "$dest/persistent_settings"
        echo '[OK] Existing RViz2 persistent_settings imported into host directory.'
      else
        rm -f -- "$temp"
        echo '[WARN] Could not import old RViz2 settings; old container has not yet been recreated.' >&2
        echo '[WARN] If preserving them is important, inspect and back them up before continuing.' >&2
        return 1
      fi
    fi
  fi
  echo "[INFO] Persistent RViz2 configuration: $dest"
  # Keep Qt/rqt/PlotJuggler settings in a separate host directory.
  local gui_dest="$ROBOTICS_ROOT/ros-gui-config"
  if [[ -L "$gui_dest" || ( -e "$gui_dest" && ! -d "$gui_dest" ) ]]; then
    echo "[FAIL] ROS GUI configuration path is not a normal directory: $gui_dest" >&2
    return 1
  fi
  if [[ ! -d "$gui_dest" ]]; then
    (umask 077; mkdir -p -- "$gui_dest")
  fi
  echo "[INFO] Persistent Qt/rqt/PlotJuggler settings: $gui_dest"
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
    rviz_prepare_config "$auth"
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
      for pkg in rqt_gui rqt_graph rqt_console rqt_image_view rqt_topic plotjuggler plotjuggler_ros; do
        ros2 pkg prefix "$pkg" >/dev/null
        printf "[OK] ROS 2 GUI package: %s\n" "$pkg"
      done
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
  --rqt|rqt|--rqt-graph|rqt-graph|--rqt-console|rqt-console|--rqt-image|rqt-image|--plotjuggler|plotjuggler)
    auth="$(rviz_auth_path)"
    [[ -f "$auth" ]] || {
      echo '[FAIL] First run: bash scripts/ros2-env.sh rviz-up' >&2
      exit 1
    }
    case "$mode" in
      --rqt|rqt) gui_package=rqt_gui; gui_exec=rqt_gui ;;
      --rqt-graph|rqt-graph) gui_package=rqt_graph; gui_exec=rqt_graph ;;
      --rqt-console|rqt-console) gui_package=rqt_console; gui_exec=rqt_console ;;
      --rqt-image|rqt-image) gui_package=rqt_image_view; gui_exec=rqt_image_view ;;
      --plotjuggler|plotjuggler) gui_package=plotjuggler; gui_exec=plotjuggler ;;
    esac
    echo "[INFO] Starting ROS 2 GUI: $gui_package/$gui_exec (Ctrl+C to stop)"
    compose_rviz_sudo "$auth" exec rviz bash -lc '
      source /opt/ros/lyrical/setup.bash
      exec ros2 run "$1" "$2"
    ' _ "$gui_package" "$gui_exec"
    ;;
  --rviz-stop|rviz-stop)
    auth="$(rviz_auth_path)"
    compose_rviz_sudo "$auth" stop rviz
    echo '[OK] RViz2 viewer stopped. The development service remains available.'
    ;;
  --help|-h|help)
    printf 'Usage: bash scripts/ros2-env.sh [plan|up|check|shell|status|down|rviz-plan|rviz-up|rviz-check|rviz|rqt|rqt-graph|rqt-console|rqt-image|plotjuggler|rviz-stop]\n'
    printf 'Workspace root (default): %s\n' "$ROBOTICS_ROOT"
    printf 'No ROS packages or NVIDIA devices are installed on Kubuntu host.\n'
    ;;
  *)
    echo "Unknown command: $mode" >&2
    exit 2
    ;;
esac
