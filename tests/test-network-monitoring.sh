#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/docker" <<'MOCK'
#!/usr/bin/env bash
# No daemon access in static CI; only "compose version/config" are allowed.
[[ "$1" == compose ]] || exit 90
exit 0
MOCK
cat > "$TMP/bin/sudo" <<'MOCK'
#!/usr/bin/env bash
echo "[FAIL] unexpected sudo in read-only plan" >&2
exit 93
MOCK
chmod +x "$TMP/bin/docker" "$TMP/bin/sudo"
PATH="$TMP/bin:$PATH" bash "$ROOT/scripts/netalertx.sh" plan > "$TMP/netalertx-plan.txt"
grep -q 'localhost' "$TMP/netalertx-plan.txt"
PATH="$TMP/bin:$PATH" bash "$ROOT/scripts/install-network-monitoring.sh" plan > "$TMP/install-plan.txt"
grep -q 'Sniffnet' "$TMP/install-plan.txt"
grep -q 'RustNet' "$TMP/install-plan.txt"
grep -q 'iperf3' "$TMP/install-plan.txt"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
r = Path(sys.argv[1])
compose = (r/'network/netalertx/compose.yaml').read_text()
installer = (r/'scripts/install-network-monitoring.sh').read_text()
wrapper = (r/'scripts/netalertx.sh').read_text()
for expected in ('ghcr.io/netalertx/netalertx:latest','network_mode: host',
                 'read_only: true', 'LISTEN_ADDR: "127.0.0.1"',
                 'NET_RAW', 'NET_ADMIN', 'netalertx_data',
                 'restart: unless-stopped', 'max-size: "10m"'):
    assert expected in compose, expected
assert 'privileged: true' not in compose
assert '/var/run/docker.sock' not in compose
assert 'down -v' not in wrapper and 'down --volumes' not in wrapper
assert 'sudo docker' in wrapper
assert "latest-release.sh" in installer
assert 'sha256sum -c' in installer
assert 'apt-get -s --no-remove' in installer
assert 'sudo apt-get install' in installer
assert 'iperf3' in installer
assert 'bootstrap.sh' not in wrapper
assert 'network-monitoring.md' in (r/'README.md').read_text()
PY
echo '[PASS] Network monitoring opt-in profile is reproducible, non-destructive on plan, and separately documented'
