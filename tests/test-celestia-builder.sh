#!/usr/bin/env bash
# Offline read-only checks for Celestia's opt-in source builder.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
HOME="$TMP/home"
mkdir -p "$HOME"
before="$(find "$HOME" -mindepth 1 | wc -l)"
HOME="$HOME" bash "$ROOT/scripts/build-celestia-stable.sh" --plan > "$TMP/plan"
after="$(find "$HOME" -mindepth 1 | wc -l)"
test "$before" -eq "$after"
grep -q 'gettext autopoint' "$TMP/plan"
grep -q 'AM_PO_SUBDIRS and AM_GNU_GETTEXT' "$TMP/plan"
grep -q 'temporary build tree' "$TMP/plan"
grep -q 'git -C "$SOURCE" archive --format=tar "$TAG" | tar -xf - -C "$BUILD"' \
  "$ROOT/scripts/build-celestia-stable.sh"
if grep -Eq '^[[:space:]]*git[[:space:]]+(clean|reset)([[:space:]]|$)' "$ROOT/scripts/build-celestia-stable.sh"; then
  echo '[FAIL] Source cleanup/reset commands are forbidden.' >&2; exit 1
fi
bash -n "$ROOT/scripts/build-celestia-stable.sh"
grep -q 'sh -n ./configure' "$ROOT/scripts/build-celestia-stable.sh"

# Exercise the actual inline Python patch on a tiny representative source.
# No network, APT, Git operations or source tree cleanup are performed.
python3 - "$ROOT/scripts/build-celestia-stable.sh" "$TMP" <<'PY'
from pathlib import Path
import sys

builder = Path(sys.argv[1]).read_text()
work = Path(sys.argv[2])
marker = '''python3 - "$BUILD/acinclude.m4" <<'PY'\n'''
assert marker in builder
inline = builder.split(marker, 1)[1].split("\nPY\n", 1)[0]
fixture = (
    "HEADER\nAC_DEFUN([KDE_CHECK_QT_JPEG],\n[\n"
    "if test -n \"$LIBJPEG\"; then\n"
    "AC_CACHE_VAL(kde_cv_qt_jpeg,\n[\n"
    "AC_LANG_RESTORE\nfi\n])\n"
    "if test yes; then\n: \nfi\n])\n"
    "AC_DEFUN([AC_FIND_ZLIB],\n[\n])\n"
)
src = work / "acinclude.m4"
src.write_text(fixture)
sys.argv = ["patch", str(src)]
exec(compile(inline, "<celestia-build-inline-patch>", "exec"))
new = src.read_text()
assert "AC_LANG_RESTORE\n])\nfi" in new
assert new.startswith("HEADER\n")
assert new.endswith("AC_DEFUN([AC_FIND_ZLIB],\n[\n])\n")
print("[PASS] Legacy misplaced-fi patch is minimal and scoped to build copy.")
PY
echo '[PASS] Celestia plan, source isolation, and configure syntax preflight are configured.'
