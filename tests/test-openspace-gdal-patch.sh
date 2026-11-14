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

# Restore only the disposable target fixture. A build can legitimately modify
# unrelated tracked files. Both staged and unstaged unrelated changes must be
# left untouched, and should not prevent the exact approved GDAL patch.
cp "$TMP/patched" modules/globebrowsing/globebrowsingmodule.cpp
printf 'untouched\n' > other.txt
git add other.txt
git commit -qm 'add other tracked file'
printf 'changed\n' >> other.txt
printf 'staged-only\n' > staged-other.txt
git add staged-other.txt
cp other.txt "$TMP/other-before"
cp staged-other.txt "$TMP/staged-before"
python3 "$ROOT/scripts/patch-openspace-gdal.py" "$TMP/upstream" >"$TMP/other-out"
cmp other.txt "$TMP/other-before"
cmp staged-other.txt "$TMP/staged-before"
git diff --quiet -- other.txt && { echo '[FAIL] Unrelated changes were reverted.' >&2; exit 1; }
git diff --cached --quiet -- staged-other.txt && { echo '[FAIL] Unrelated staged changes were reverted.' >&2; exit 1; }
grep -q 'already applied' "$TMP/other-out"

# Staged changes to the exact target file are still a hard conflict.
git add modules/globebrowsing/globebrowsingmodule.cpp
if python3 "$ROOT/scripts/patch-openspace-gdal.py" "$TMP/upstream" >"$TMP/error2" 2>&1; then
  echo '[FAIL] Staged GDAL target modifications must be rejected.' >&2; exit 1
fi
grep -q 'GDAL target file has staged changes' "$TMP/error2"
cmp other.txt "$TMP/other-before"
cmp staged-other.txt "$TMP/staged-before"

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
echo '[PASS] GDAL patch exactness, idempotency, target-file protection, preservation of unrelated changes and Ninja resume.'
