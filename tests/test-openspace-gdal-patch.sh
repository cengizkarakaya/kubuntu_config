#!/usr/bin/env bash
# Offline test of the exact, idempotent OpenSpace GDAL source compatibility fix.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/upstream/modules/globebrowsing"
cd "$TMP/upstream"
git init -q
git config user.name "OpenSpace Offline Test"
git config user.email "openspace-test@example.invalid"
cat > modules/globebrowsing/globebrowsingmodule.cpp <<'SRC'
namespace Example {
Capabilities parseSubDatasets(char** subDatasets,
                             int nSubdatasets)
{
    return nSubdatasets ? Capabilities() : Capabilities();
}
void load() {
    char** subDatasets = GDALGetMetadata(dataset, "SUBDATASETS");
    const int nSubdatasets = CSLCount(subDatasets);
    Capabilities cap = parseSubDatasets(subDatasets, nSubdatasets);
}
}
SRC
git add modules/globebrowsing/globebrowsingmodule.cpp
git commit -qm initial
python3 "$ROOT/scripts/patch-openspace-gdal.py" "$TMP/upstream"
cp modules/globebrowsing/globebrowsingmodule.cpp "$TMP/patched"
python3 "$ROOT/scripts/patch-openspace-gdal.py" "$TMP/upstream"
cmp modules/globebrowsing/globebrowsingmodule.cpp "$TMP/patched"
grep -Fq 'parseSubDatasets(const char* const* subDatasets,' "$TMP/patched"
grep -Fq 'const char* const* subDatasets = GDALGetMetadata' "$TMP/patched"
git diff --check
python3 - "$TMP/upstream" <<'PY'
import pathlib
import subprocess
import sys
base = pathlib.Path(sys.argv[1])
d = base / "modules/globebrowsing/globebrowsingmodule.cpp"
assert d.read_text().count("const char* const*") == 2
baseline = subprocess.check_output(
    ["git", "-C", str(base), "show",
     "HEAD:modules/globebrowsing/globebrowsingmodule.cpp"], text=True
)
assert baseline.count("char**") == 2
PY

# Refuse unrelated, existing source modifications without overwriting any file.
echo '// altered by user' >> modules/globebrowsing/globebrowsingmodule.cpp
if python3 "$ROOT/scripts/patch-openspace-gdal.py" "$TMP/upstream" >"$TMP/error1" 2>&1; then
  echo '[FAIL] Modified OpenSpace file must be rejected.' >&2; exit 1
fi
grep -q 'unexpected modifications' "$TMP/error1"
grep -q 'altered by user' modules/globebrowsing/globebrowsingmodule.cpp

# Restore only the disposable test fixture, then test changing another file.
cp "$TMP/patched" modules/globebrowsing/globebrowsingmodule.cpp
printf 'untouched\n' > other.txt
git add other.txt
git commit -qm 'add other tracked file'
printf 'changed\n' >> other.txt
if python3 "$ROOT/scripts/patch-openspace-gdal.py" "$TMP/upstream" >"$TMP/error2" 2>&1; then
  echo '[FAIL] Unrelated source changes must be rejected.' >&2; exit 1
fi
grep -q 'Other tracked source changes' "$TMP/error2"

# Check --resume bypasses APT, Git submodule fetch, and CMake generation.
python3 - "$ROOT/scripts/build-openspace.sh" <<'PY'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text()
assert "--resume" in s
assert 'if [[ "$mode" == --build ]]; then\n  sudo apt-get update' in s
assert 'if [[ "$mode" == --build ]]; then\n    git -C "$DEST" submodule' in s
assert 'if [[ "$mode" == --resume ]]; then\n  if [[ ! -f "$DEST/build/build.ninja" ]]' in s
assert 'python3 "$SCRIPTS_DIR/patch-openspace-gdal.py" "$DEST"' in s
assert 'cmake --build "$DEST/build"' in s
PY
bash -n "$ROOT/scripts/build-openspace.sh"
echo '[PASS] GDAL patch exactness, idempotency, conflict protection and Ninja resume.'
