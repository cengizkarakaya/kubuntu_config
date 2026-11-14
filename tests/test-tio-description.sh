#!/usr/bin/env bash
# Verify TIO starter XML/launch structure and non-destructive file bootstrap.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
root = Path(sys.argv[1])
package = root / 'robotics/tio_description'
metadata = ET.parse(package / 'package.xml').getroot()
assert metadata.findtext('name') == 'tio_description'
assert metadata.findtext('buildtool_depend') == 'ament_cmake'
model = ET.parse(package / 'urdf/tio.urdf.xacro').getroot()
assert model.attrib['name'] == 'tio'
links = {x.attrib['name'] for x in model.findall('link')}
for name in ('base_footprint', 'base_link', 'lidar_link', 'camera_pan_link',
             'camera_tilt_link', 'camera_link', 'camera_optical_frame', 'imu_link'):
    assert name in links, name
macros = [el for el in model if el.tag.endswith('macro')]
assert any(el.attrib.get('name') == 'wheel' for el in macros)
instances = [el for el in model if el.tag.endswith('wheel')]
assert {x.attrib['name'] for x in instances} == {
    'front_left_wheel', 'front_right_wheel', 'rear_left_wheel', 'rear_right_wheel'}
joints = {x.attrib['name']: x for x in model.findall('joint')}
assert joints['camera_pan_joint'].attrib['type'] == 'revolute'
assert joints['camera_tilt_joint'].attrib['type'] == 'revolute'
assert joints['lidar_joint'].attrib['type'] == 'fixed'
assert joints['camera_optical_joint'].attrib['type'] == 'fixed'
for prop in ('body_length', 'body_width', 'body_height', 'wheel_radius',
             'wheel_width', 'wheelbase', 'wheel_track'):
    assert any(x.attrib.get('name') == prop for x in model if x.tag.endswith('property'))
launch = package / 'launch/display.launch.py'
compile(launch.read_text(), str(launch), 'exec')
text = launch.read_text()
assert 'robot_state_publisher' in text and 'joint_state_publisher' in text
assert 'xacro.process_file' in text
assert 'use_sim_time' in text
assert 'install(DIRECTORY urdf launch' in (package / 'CMakeLists.txt').read_text()
print('[PASS] TIO package metadata, XML model, geometry parameters and launch Python syntax')
PY

tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
# Verify the launcher does not modify any user files before explicit init.
ROBOTICS_ROOT="$tmp/robotics" bash "$ROOT/scripts/ros2-tio.sh" plan > "$tmp/plan.txt"
test ! -e "$tmp/robotics"
ROBOTICS_ROOT="$tmp/robotics" bash "$ROOT/scripts/ros2-tio.sh" init > "$tmp/init.txt"
test -f "$tmp/robotics/tio_ws/src/tio_description/package.xml"
ROBOTICS_ROOT="$tmp/robotics" bash "$ROOT/scripts/ros2-tio.sh" init > "$tmp/init-again.txt"
echo 'USER CUSTOMIZATION' >> "$tmp/robotics/tio_ws/src/tio_description/CMakeLists.txt"
if ROBOTICS_ROOT="$tmp/robotics" bash "$ROOT/scripts/ros2-tio.sh" init > "$tmp/over.txt" 2>&1; then
  echo '[FAIL] Second init should reject a customized project.' >&2
  exit 1
fi
grep -q 'USER CUSTOMIZATION' "$tmp/robotics/tio_ws/src/tio_description/CMakeLists.txt"
echo '[PASS] TIO init is non-destructive and idempotent for an unmodified starter'
