#!/usr/bin/env bash
# No host firewall changes. Static tests + opt-in plan smoke test.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/sudo" <<'MOCK'
#!/usr/bin/env bash
echo '[FAIL] plan must not run sudo' >&2
exit 99
MOCK
chmod +x "$TMP/bin/sudo"
PATH="$TMP/bin:$PATH" bash "$ROOT/scripts/netalertx-api-guard.sh" plan > "$TMP/plan"
grep -q 'TCP/20212' "$TMP/plan"
grep -q "Does not enable UFW" "$TMP/plan"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root=Path(sys.argv[1])
config=(root/'network/netalertx/api-guard.nft').read_text()
root_script=(root/'network/netalertx/api-guard-root.sh').read_text()
wrapper=(root/'scripts/netalertx-api-guard.sh').read_text()
unit=(root/'network/netalertx/netalertx-api-guard.service').read_text()
assert 'table inet kubuntu_netalertx_api_guard' in config
assert 'type filter hook input priority -10; policy accept;' in config
assert 'iifname != "lo" tcp dport 20212 counter drop' in config
assert not any('flush ruleset' in line for line in config.splitlines() if not line.lstrip().startswith('#'))
assert 'nft delete table inet' in root_script
assert 'nft -f "$config"' in root_script
assert 'nft list table inet "$table"' in root_script
assert 'sudo systemctl enable --now netalertx-api-guard.service' in wrapper
assert 'sudo systemctl disable --now netalertx-api-guard.service' in wrapper
assert 'sudo install -o root -g root -m 0755 -D' in wrapper
assert 'ExecStart=/usr/local/libexec/kubuntu-netalertx-api-guard apply' in unit
assert 'ExecStop=/usr/local/libexec/kubuntu-netalertx-api-guard remove' in unit
assert 'After=local-fs.target nftables.service' in unit
assert 'Before=docker.service' in unit
assert not (root/'bootstrap.sh').read_text().find('netalertx-api-guard') >= 0
PY
echo '[PASS] Narrow NetAlertX API guard is opt-in, loopback-safe, boot-persistent and does not flush host rules'
