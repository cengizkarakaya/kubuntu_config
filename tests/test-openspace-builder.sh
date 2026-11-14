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

# Simulate APT with a disposable executable: check-apt must not request sudo,
# install anything, or silently accept removal of the existing JACK2 libraries.
mkdir -p "$TMP/mockbin"
cat > "$TMP/mockbin/apt-get" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$MOCK_APT_ARGS"
[[ "$1" == -s ]] || exit 10
[[ " $* " == *" --no-remove "* ]] || exit 11
[[ " $* " == *" libjack-jackd2-dev "* ]] || exit 12
[[ " $* " == *" libmpv-dev "* ]] || exit 13
[[ "${MOCK_APT_FAIL:-0}" != 1 ]]
MOCK
chmod +x "$TMP/mockbin/apt-get"
MOCK_APT_ARGS="$TMP/apt-args" HOME="$TMP/home" PATH="$TMP/mockbin:$PATH" \
  bash "$builder" --check-apt > "$TMP/apt-plan"
grep -q 'libjack-jackd2-dev' "$TMP/apt-args"
grep -q 'APT simulation succeeded' "$TMP/apt-plan"
if MOCK_APT_FAIL=1 MOCK_APT_ARGS="$TMP/apt-args" HOME="$TMP/home" \
     PATH="$TMP/mockbin:$PATH" bash "$builder" --check-apt > "$TMP/apt-fail" 2>&1; then
  echo '[FAIL] OpenSpace must abort when APT simulation returns failure.' >&2
  exit 1
fi
grep -q 'cannot satisfy all dependencies without removing packages' "$TMP/apt-fail"
test -z "$(find "$TMP/home" -mindepth 1 -print -quit)"
echo '[PASS] JACK2 provider preserved and failed APT simulations abort safely.'
# Resource + toolchain gates must precede any sudo APT operations.
python3 - "$builder" <<'PY'
from pathlib import Path
import sys

s = Path(sys.argv[1]).read_text()
before = s.index('free_kb="$(df -Pk "$HOME"')
version_gate = s.index('cmake_version="$(cmake --version')
apt_command = s.index('sudo apt-get update')
pkg_check = s.index('qt_version="$(pkg-config --modversion Qt6Core')
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
