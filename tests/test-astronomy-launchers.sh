#!/usr/bin/env bash
# Offline, sandboxed test: never touches the actual KDE menu, Flatpak or APT.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
mkdir -p "$XDG_CONFIG_HOME/menus" "$XDG_DATA_HOME/flatpak/exports/share/applications" "$TMP/bin" \
  "$HOME/.local/opt/celestia" "$HOME/.local/opt/openspace/bin"
cat > "$XDG_CONFIG_HOME/menus/applications-kmenuedit.menu" <<'EOF'
<Menu>
 <Name>Applications</Name>
 <Menu>
  <Name>Physics</Name>
  <Menu>
   <Name>Astronomy</Name>
   <Directory>Astronomy.directory</Directory>
  </Menu>
 </Menu>
 <Menu>
  <Name>Astronomy</Name>
  <NotDeleted/>
  <Include>
   <Filename>KStars.desktop</Filename>
   <Filename>Stellarium.desktop</Filename>
  </Include>
  <Layout>
   <Merge type="files"/>
   <Filename>Stellarium.desktop</Filename>
   <Filename>KStars.desktop</Filename>
  </Layout>
 </Menu>
 <Menu>
  <Name>Robotics</Name>
  <Include><Filename>webots.desktop</Filename></Include>
 </Menu>
</Menu>
EOF
cat > "$TMP/bin/flatpak" <<'EOF'
#!/usr/bin/env bash
[[ "$1" == info && "$2" == --user && "$3" == space.gaiasky.GaiaSky ]]
EOF
chmod +x "$TMP/bin/flatpak"
touch "$XDG_DATA_HOME/flatpak/exports/share/applications/space.gaiasky.GaiaSky.desktop"
printf '#!/bin/sh\nexit 0\n' > "$HOME/.local/opt/celestia/Celestia.AppImage"
printf '#!/bin/sh\nexit 0\n' > "$HOME/.local/opt/openspace/bin/OpenSpace"
chmod +x "$HOME/.local/opt/celestia/Celestia.AppImage" "$HOME/.local/opt/openspace/bin/OpenSpace"
export PATH="$TMP/bin:$PATH"
cp "$XDG_CONFIG_HOME/menus/applications-kmenuedit.menu" "$TMP/before.menu"
python3 "$ROOT/scripts/install-astronomy-launchers.py" --check > "$TMP/plan"
cmp "$TMP/before.menu" "$XDG_CONFIG_HOME/menus/applications-kmenuedit.menu"
test ! -e "$HOME/.local/bin/kubuntu-astronomy-celestia"

python3 "$ROOT/scripts/install-astronomy-launchers.py" --install > "$TMP/install"
MENU="$XDG_CONFIG_HOME/menus/applications-kmenuedit.menu"
for id in kubuntu-astronomy-celestia kubuntu-astronomy-openspace; do
  test -x "$HOME/.local/bin/$id"
  test -f "$XDG_DATA_HOME/applications/$id.desktop"
  grep -q 'X-Kubuntu-Astronomy-Managed=true' "$XDG_DATA_HOME/applications/$id.desktop"
done
python3 - "$MENU" <<'PY'
from pathlib import Path
import sys
m = Path(sys.argv[1]).read_text()
for id in ("kubuntu-astronomy-celestia.desktop",
           "kubuntu-astronomy-openspace.desktop",
           "space.gaiasky.GaiaSky.desktop"):
    assert m.count("<Filename>" + id + "</Filename>") == 2, id
assert m.count("<Filename>KStars.desktop</Filename>") == 2
assert m.count("<Filename>Stellarium.desktop</Filename>") == 2
assert "<Filename>webots.desktop</Filename>" in m
assert "<Name>Physics</Name>" in m
print("[PASS] Astronomy entries integrated without affecting other menu sections.")
PY
test "$(find "$XDG_STATE_HOME/kubuntu-config" -name applications-kmenuedit.menu | wc -l)" -eq 1
sha256sum "$MENU" > "$TMP/menu-hash"
python3 "$ROOT/scripts/install-astronomy-launchers.py" --install > "$TMP/repeat"
sha256sum -c "$TMP/menu-hash"
test "$(find "$XDG_STATE_HOME/kubuntu-config" -name applications-kmenuedit.menu | wc -l)" -eq 1

echo '# customized' >> "$XDG_DATA_HOME/applications/kubuntu-astronomy-celestia.desktop"
if python3 "$ROOT/scripts/install-astronomy-launchers.py" --install > "$TMP/fail" 2>&1; then
  echo '[FAIL] Customized desktop entry must never be overwritten.' >&2
  exit 1
fi
grep -q customized "$XDG_DATA_HOME/applications/kubuntu-astronomy-celestia.desktop"
echo '[PASS] Dry-run, backup, idempotency, app-detection and conflict protection.'
