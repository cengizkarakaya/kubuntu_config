#!/usr/bin/env bash
# Functional offline test of the non-destructive Robotics KDE launcher installer.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

mkdir -p "$TMP/home/.config/menus" "$TMP/bin"
cat > "$TMP/home/.config/menus/applications-kmenuedit.menu" <<'MENU'
<!DOCTYPE Menu PUBLIC '-//freedesktop//DTD Menu 1.0//EN' 'http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd'>
<Menu>
 <Name>Applications</Name>
 <Menu>
  <Name>Physics</Name>
  <Menu>
   <Name>Robotics</Name>
   <Directory>Robotics.directory</Directory>
  </Menu>
 </Menu>
 <Menu>
  <Name>Robotics</Name>
  <NotDeleted/>
  <Menu>
   <Name>Electronics</Name>
   <Directory>Electronics.directory</Directory>
  </Menu>
  <Layout>
   <Merge type="files"/>
   <Filename>webots.desktop</Filename>
  </Layout>
  <Include>
   <Filename>webots.desktop</Filename>
  </Include>
 </Menu>
 <Menu>
  <Name>Electronics</Name>
  <Include><Filename>kicad.desktop</Filename></Include>
 </Menu>
</Menu>
MENU
cat > "$TMP/bin/alacritty" <<'ALACRITTY'
#!/usr/bin/env bash
echo "mock Alacritty, no GUI"
ALACRITTY
chmod +x "$TMP/bin/alacritty"
cp "$TMP/home/.config/menus/applications-kmenuedit.menu" "$TMP/before.menu"
export HOME="$TMP/home" XDG_CONFIG_HOME="$TMP/home/.config"
export XDG_DATA_HOME="$TMP/home/.local/share" XDG_STATE_HOME="$TMP/home/.local/state"
export PATH="$TMP/bin:$PATH"

python3 "$ROOT/scripts/install-ros2-launchers.py" --check > "$TMP/check.txt"
cmp "$TMP/before.menu" "$TMP/home/.config/menus/applications-kmenuedit.menu"
test ! -e "$HOME/.local/bin/kubuntu-ros2-launcher"

python3 "$ROOT/scripts/install-ros2-launchers.py" --install > "$TMP/install.txt"
test -x "$HOME/.local/bin/kubuntu-ros2-launcher"
for name in ros2-terminal ros2-gui-start ros2-rviz ros2-rqt ros2-rqt-graph ros2-rqt-console ros2-rqt-image ros2-plotjuggler; do
  test -f "$XDG_DATA_HOME/applications/kubuntu-$name.desktop"
  grep -q 'X-Kubuntu-ROS2-Managed=true' "$XDG_DATA_HOME/applications/kubuntu-$name.desktop"
done
python3 - "$HOME/.config/menus/applications-kmenuedit.menu" <<'PY'
import sys
from pathlib import Path
m = Path(sys.argv[1]).read_text()
assert m.count('<Filename>webots.desktop</Filename>') == 2
for name in ('ros2-terminal','ros2-gui-start','ros2-rviz','ros2-rqt','ros2-rqt-graph',
             'ros2-rqt-console','ros2-rqt-image','ros2-plotjuggler'):
    assert m.count('<Filename>kubuntu-' + name + '.desktop</Filename>') == 2, name
assert '<Filename>kicad.desktop</Filename>' in m
assert '<Name>Physics</Name>' in m
print('[PASS] Robotics menu retains Webots, Physics and Electronics and includes ROS apps')
PY
test "$(find "$XDG_STATE_HOME/kubuntu-config" -name applications-kmenuedit.menu | wc -l)" -eq 1
sha256sum "$HOME/.config/menus/applications-kmenuedit.menu" > "$TMP/menu-hash"
python3 "$ROOT/scripts/install-ros2-launchers.py" --install > "$TMP/install-again.txt"
sha256sum -c "$TMP/menu-hash"
test "$(find "$XDG_STATE_HOME/kubuntu-config" -name applications-kmenuedit.menu | wc -l)" -eq 1

# Protect user-customized launchers from accidental overwrite.
echo '# custom user setting' >> "$XDG_DATA_HOME/applications/kubuntu-ros2-rqt.desktop"
if python3 "$ROOT/scripts/install-ros2-launchers.py" --install > "$TMP/conflict.txt" 2>&1; then
  echo '[FAIL] A conflicting desktop entry should cause installer refusal' >&2
  exit 1
fi
grep -q 'custom user setting' "$XDG_DATA_HOME/applications/kubuntu-ros2-rqt.desktop"

python3 - "$ROOT/scripts/ros2-env.sh" "$ROOT/robotics/ros2/Dockerfile.rviz" <<'PY'
from pathlib import Path
import sys
s=Path(sys.argv[1]).read_text()
d=Path(sys.argv[2]).read_text()
for label in ('rqt', 'rqt-graph', 'rqt-console', 'rqt-image', 'plotjuggler'):
    assert f'--{label}' in s, label
assert 'exec ros2 run "$1" "$2"' in s
for package in ('ros-lyrical-rqt', 'ros-lyrical-rqt-graph',
                'ros-lyrical-rqt-console', 'ros-lyrical-rqt-image-view',
                'ros-lyrical-rqt-topic', 'ros-lyrical-rqt-plot', 'ros-lyrical-plotjuggler'):
    assert package in d, package
assert 'ros-lyrical-plotjuggler-ros \\\n' not in d, 'unavailable binary package in Dockerfile'
assert 'ros2 pkg prefix plotjuggler_ros' not in d, 'unavailable plugin enforced at build'
print('[PASS] ROS GUI helper, available Docker packages, and optional plugin handling')
PY

echo '[PASS] Read-only planning, safe installs, backup, idempotency and conflict refusal'
