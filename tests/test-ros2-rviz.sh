#!/usr/bin/env bash
# Static safety checks; no Docker daemon or NVIDIA required.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
base = (root / "robotics/ros2/compose.yaml").read_text()
gfx = (root / "robotics/ros2/compose.rviz.yaml").read_text()
docker = (root / "robotics/ros2/Dockerfile.rviz").read_text()
helper = (root / "scripts/ros2-env.sh").read_text()
assert 'gpus: all' not in base
assert 'profiles: [gui]' in gfx
assert 'network_mode: "service:dev"' in gfx
assert 'ipc: "service:dev"' in gfx
assert 'ipc: shareable' in gfx
for token in ('privileged: true', 'network_mode: host', '/var/run/docker.sock', 'xhost +'):
    assert token not in gfx + helper, token
for token in ('rviz-up)', 'rviz-plan)', 'rviz-check)', 'rviz)', 'rviz-stop)', 'xauth nlist', "sed 's/^..../ffff/'"):
    assert token in helper, token
assert 'ros-lyrical-rviz2' in docker
assert 'ros-lyrical-plotjuggler' in docker
assert 'ros-lyrical-rqt-plot' in docker
assert 'ros-lyrical-plotjuggler-ros \\' not in docker
assert 'plotjuggler_ros' not in docker.split('RUN apt-get update', 1)[1].split('&& rm -rf')[0]
assert 'mesa-utils' in docker
assert 'NVIDIA_DRIVER_CAPABILITIES: graphics,display,utility,compute' in gfx
assert 'XAUTHORITY: /tmp/.Xauthority' in gfx
assert 'QT_QPA_PLATFORM: xcb' in gfx
assert 'source: "${RVIZ_XAUTH:' in gfx
assert 'source: "${ROBOTICS_ROOT:?Set via scripts/ros2-env.sh}/rviz2-config"' in gfx
assert 'target: /home/rosdev/.rviz2' in gfx
assert 'source: "${ROBOTICS_ROOT:?Set via scripts/ros2-env.sh}/ros-gui-config"' in gfx
assert 'target: /home/rosdev/.config' in gfx
assert 'Persistent Qt/rqt/PlotJuggler settings' in helper
assert 'rviz_prepare_config "$auth"' in helper
assert 'persistent_settings' in helper
assert 'create_host_path: false' in gfx
# Check the embedded bash -lc script as an argument, not only the outer
# wrapper (bash -n on the wrapper alone misses nested quote breakage).
import subprocess
rviz_check_open = "compose_rviz_sudo \"$auth\" exec --no-TTY rviz bash -lc '"
assert helper.count(rviz_check_open) == 1, 'rviz-check command not uniquely identified'
inner = helper.split(rviz_check_open, 1)[1].split("\n    '\n    ;;", 1)[0]
assert "      if ros2 pkg prefix plotjuggler_ros" in inner
assert "'" not in inner, 'Unescaped apostrophe breaks the outer single-quoted bash -lc argument'
subprocess.run(["bash", "-n", "-c", inner], check=True)
print('[PASS] Embedded rviz-check Bash is syntactically valid and safely quoted')
print('[PASS] RViz2 profile isolation, graphics env and explicit Xauthority guards')
PY
