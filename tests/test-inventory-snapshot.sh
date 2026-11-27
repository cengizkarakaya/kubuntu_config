#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
export HOME="$tmp/home"
export XDG_STATE_HOME="$HOME/state"
mkdir -p "$HOME"
bash "$ROOT/scripts/inventory-snapshot.sh" --plan > "$tmp/plan"
grep -Fq 'No files written' "$tmp/plan"
test ! -e "$XDG_STATE_HOME"
if XDG_STATE_HOME="$ROOT" bash "$ROOT/scripts/inventory-snapshot.sh" --plan > "$tmp/refused" 2>&1; then exit 1; fi
mkdir -p "$tmp/bin"
cat > "$tmp/bin/dpkg-query" <<'MOCK'
#!/bin/bash
printf 'ii \talpha\t1.0\n'
MOCK
cat > "$tmp/bin/apt-mark" <<'MOCK'
#!/bin/bash
printf 'alpha\n'
MOCK
cat > "$tmp/bin/dpkg" <<'MOCK'
#!/bin/bash
printf 'alpha\tinstall\n'
MOCK
chmod +x "$tmp/bin/"*
for tool in python3 bash dirname cat uname git; do
  ln -s "$(command -v "$tool")" "$tmp/bin/$tool"
done
PATH="$tmp/bin" bash "$ROOT/scripts/inventory-snapshot.sh" --capture > "$tmp/result"
snapshot="$(find "$XDG_STATE_HOME" -name inventory.json -type f)"
test -f "$snapshot"
test "$(stat -c %a "$snapshot")" = 600
python3 - "$snapshot" "$tmp/after.json" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
assert data["apt"]["items"]["alpha"]["version"] == "1.0"
assert data["conda"]["status"] == "not-installed"
data["apt"]["items"]["alpha"]["version"] = "2.0"
with open(sys.argv[2], "w") as f:
    json.dump(data, f)
PY
bash "$ROOT/scripts/inventory-snapshot.sh" --compare "$snapshot" "$tmp/after.json" > "$tmp/diff"
grep -Fq 'alpha:' "$tmp/diff"
grep -Fq '2.0' "$tmp/diff"
echo '[PASS] Private inventory plan, mock capture, permissions and comparison'
