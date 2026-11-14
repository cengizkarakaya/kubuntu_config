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
if grep -Eq 'git (clean|reset)' "$ROOT/scripts/build-celestia-stable.sh"; then
  echo '[FAIL] Source cleanup/reset commands are forbidden.' >&2; exit 1
fi
bash -n "$ROOT/scripts/build-celestia-stable.sh"
echo '[PASS] Celestia plan is read-only; gettext/autopoint and clean source archive are configured.'
