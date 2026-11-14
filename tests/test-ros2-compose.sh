#!/usr/bin/env bash
# Read-only test of wrapper interpolation; never requires Docker daemon.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin"
cat > "$tmp/bin/docker" <<'MOCK'
#!/usr/bin/env bash
set -e
[[ "$1" == compose ]] || exit 2
shift
[[ "$1" == -f && -f "$2" ]] || exit 2
shift 2
[[ "$1" == config && "$2" == --quiet ]] || exit 2
[[ "${ROS_UID:-}" =~ ^[0-9]+$ ]] || exit 2
[[ "${ROS_GID:-}" =~ ^[0-9]+$ ]] || exit 2
[[ "${ROBOTICS_ROOT:-}" == /* ]] || exit 2
MOCK
chmod +x "$tmp/bin/docker"
PATH="$tmp/bin:$PATH" ROBOTICS_ROOT="$tmp/safe-robotics" bash "$ROOT/scripts/ros2-env.sh" plan > "$tmp/output"
grep -q 'No images built' "$tmp/output"
test ! -e "$tmp/safe-robotics"
python3 - "$ROOT/robotics/ros2/compose.yaml" <<'PY'
import sys
from pathlib import Path
s=Path(sys.argv[1]).read_text()
for forbidden in ('privileged: true', 'network_mode: host', '/var/run/docker.sock', '/dev/dri', '/tmp/.X11-unix'):
    assert forbidden not in s, forbidden
assert s.count('create_host_path: false') == 2
assert 'ROS_AUTOMATIC_DISCOVERY_RANGE: LOCALHOST' in s
print('[PASS] No host-device/network privilege in initial Compose profile')
PY
python3 - "$ROOT/robotics/ros2/Dockerfile" <<'PY'
import sys
from pathlib import Path
s = Path(sys.argv[1]).read_text()
packages = [line.strip().rstrip(chr(92)).strip() for line in s.splitlines()]
for package in ('colcon', 'vcstool'):
    assert package not in packages, f"conflicting package: {package}"
for package in ('python3-colcon-core', 'python3-colcon-ros', 'python3-vcstool'):
    assert package in packages, f"missing package: {package}"
for command in ('colcon', 'vcs'):
    assert 'command -v ' + command in s, f"missing binary check: {command}"
print('[PASS] Dockerfile uses ROS-compatible colcon/vcs package names')
PY
echo '[PASS] Plan validates interpolated configuration without files, sudo or Docker daemon'
