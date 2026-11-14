#!/usr/bin/env bash
# Offline checks: OpenSpace plan does not install packages or create sources.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

mkdir -p "$TMP/home"
HOME="$TMP/home" bash "$ROOT/scripts/build-openspace.sh" --plan > "$TMP/plan"
test -z "$(find "$TMP/home" -mindepth 1 -print -quit)"
grep -q 'cmake' "$TMP/plan"
grep -q 'qt6-base-dev' "$TMP/plan"
grep -q 'libgdal-dev' "$TMP/plan"
grep -q 'GCC >=13' "$TMP/plan"
grep -q 'Qt >=6.8' "$TMP/plan"
grep -q 'Git submodules' "$TMP/plan"

builder="$ROOT/scripts/build-openspace.sh"
bash -n "$builder"
# Resource + toolchain gates must precede any sudo APT operations.
python3 - "$builder" <<'PY'
from pathlib import Path
import sys

s = Path(sys.argv[1]).read_text()
before = s.index('free_kb="$(df -Pk "$HOME"')
version_gate = s.index('cmake_version="$(cmake --version')
apt_command = s.index('sudo apt-get update')
pkg_check = s.index('pkg-config --modversion Qt6Core')
clone = s.index('git clone --recursive')
assert before < version_gate < apt_command < pkg_check < clone
assert 'dpkg --compare-versions "$cmake_version" ge 4.0' in s
assert '(( gcc_version < 13 ))' in s
assert 'dpkg --compare-versions "$qt_version" ge 6.8' in s
assert 'pkg-config --exists gdal' in s
assert '--no-remove' in s
print('[PASS] Version check before APT; Qt/GDAL validation before clone.')
PY
echo '[PASS] OpenSpace dry-run, pinned channel and dependency safety checks.'
