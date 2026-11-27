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
# Docker and socket status are simulated; assert a backend bound to all
# interfaces is warned about, while a localhost listener does not warn.
cat > "$TMP/bin/docker" <<'MOCK'
#!/usr/bin/env bash
if [[ "$1" == inspect ]]; then
  printf 'true\n'
  exit 0
fi
[[ "$1" == compose ]] || exit 90
exit 0
MOCK
cat > "$TMP/bin/sudo" <<'MOCK'
#!/usr/bin/env bash
[[ "$1" == docker ]] || exit 93
shift
exec docker "$@"
MOCK
cat > "$TMP/bin/ss" <<'MOCK'
#!/usr/bin/env bash
printf 'LISTEN 0 128 %s:20212 0.0.0.0:*\n' "${MOCK_LISTEN_ADDR:-0.0.0.0}"
MOCK
chmod +x "$TMP/bin/docker" "$TMP/bin/sudo" "$TMP/bin/ss"
MOCK_LISTEN_ADDR=0.0.0.0 PATH="$TMP/bin:$PATH" \
  bash "$ROOT/scripts/netalertx.sh" check > "$TMP/netalertx-wildcard.txt"
grep -Fq '[WARN] NetAlertX API port 20212' "$TMP/netalertx-wildcard.txt"
MOCK_LISTEN_ADDR=127.0.0.1 PATH="$TMP/bin:$PATH" \
  bash "$ROOT/scripts/netalertx.sh" check > "$TMP/netalertx-local.txt"
if grep -Fq '[WARN] NetAlertX API port 20212' "$TMP/netalertx-local.txt"; then
  echo '[FAIL] Loopback-only API caused a false exposure warning' >&2
  exit 1
fi
echo '[PASS] NetAlertX check warns on wildcard API socket without changing firewall'
PATH="$TMP/bin:$PATH" bash "$ROOT/scripts/netalertx.sh" update > "$TMP/netalertx-update.txt"
grep -Fq 'Applying the reviewed image digest' "$TMP/netalertx-update.txt"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import re
import sys
r = Path(sys.argv[1])
compose = (r/'network/netalertx/compose.yaml').read_text()
installer = (r/'scripts/install-network-monitoring.sh').read_text()
wrapper = (r/'scripts/netalertx.sh').read_text()
assert re.search(r'^    image: ghcr\.io/netalertx/netalertx:\d+\.\d+\.\d+@sha256:[0-9a-f]{64}
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
# Regression test: upstream RustNet's Debian package is rustnet-monitor,
# even though its command and GitHub repository are called "rustnet".
# Exercise the real installer function without sudo, network, APT or Docker.
grep -Fq 'install_official_deb domcyrus/rustnet "Rustnet_LinuxDEB_${arch}.deb" rustnet-monitor' \
  "$ROOT/scripts/install-network-monitoring.sh"
[[ "$(grep -Fc 'verify_one rustnet-monitor rustnet' "$ROOT/scripts/install-network-monitoring.sh")" == 2 ]]
function_source="$(sed -n '/^install_official_deb() {/,/^}/p' "$ROOT/scripts/install-network-monitoring.sh")"
[[ -n "$function_source" ]] || { echo '[FAIL] Missing installer function' >&2; exit 1; }
export function_source ROOT TMP
bash <<'MOCK_DEB'
set -Eeuo pipefail
work="$TMP/mock-deb"
arch=amd64
mkdir -p "$work"
bash() {
  [[ "$1" == "$ROOT/scripts/latest-release.sh" ]] || return 2
  printf 'v1.7.0\thttps://github.com/domcyrus/rustnet/releases/download/v1.7.0/Rustnet_LinuxDEB_amd64.deb\t%s\n' "$(printf '0%.0s' {1..64})"
}
curl() {
  local file="${@: -1}"
  printf 'Mock .deb' > "$file"
}
sha256sum() { cat >/dev/null; echo 'Mock download: OK'; }
dpkg-query() {
  [[ -f "$TMP/rustnet-installed" ]] || return 1
  printf '1.7.0-1'
}
dpkg() { return 1; }
dpkg-deb() {
  case "$3" in
    Package) printf 'rustnet-monitor' ;;
    Version) printf '1.7.0-1' ;;
    Architecture) printf 'amd64' ;;
    *) return 2 ;;
  esac
}
apt-get() { [[ "$1" == -s && "$2" == --no-remove && "$3" == install ]]; }
sudo() {
  [[ "$1" == apt-get && "$2" == install ]] || return 2
  : > "$TMP/rustnet-installed"
}
eval "$function_source"
install_official_deb domcyrus/rustnet Rustnet_LinuxDEB_amd64.deb rustnet-monitor
[[ -e "$TMP/rustnet-installed" ]]
rm "$TMP/rustnet-installed"
if install_official_deb domcyrus/rustnet Rustnet_LinuxDEB_amd64.deb rustnet > /dev/null 2>&1; then
  echo '[FAIL] Untrusted package-name mismatch was accepted' >&2
  exit 1
fi
MOCK_DEB
echo '[PASS] RustNet Debian metadata: expected rustnet-monitor, executable rustnet; mismatch still rejected'

echo '[PASS] Network monitoring opt-in profile is reproducible, non-destructive on plan, and separately documented'
, compose, re.M)
assert 'netalertx:latest' not in compose
for expected in ('network_mode: host',
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
# Regression test: upstream RustNet's Debian package is rustnet-monitor,
# even though its command and GitHub repository are called "rustnet".
# Exercise the real installer function without sudo, network, APT or Docker.
grep -Fq 'install_official_deb domcyrus/rustnet "Rustnet_LinuxDEB_${arch}.deb" rustnet-monitor' \
  "$ROOT/scripts/install-network-monitoring.sh"
[[ "$(grep -Fc 'verify_one rustnet-monitor rustnet' "$ROOT/scripts/install-network-monitoring.sh")" == 2 ]]
function_source="$(sed -n '/^install_official_deb() {/,/^}/p' "$ROOT/scripts/install-network-monitoring.sh")"
[[ -n "$function_source" ]] || { echo '[FAIL] Missing installer function' >&2; exit 1; }
export function_source ROOT TMP
bash <<'MOCK_DEB'
set -Eeuo pipefail
work="$TMP/mock-deb"
arch=amd64
mkdir -p "$work"
bash() {
  [[ "$1" == "$ROOT/scripts/latest-release.sh" ]] || return 2
  printf 'v1.7.0\thttps://github.com/domcyrus/rustnet/releases/download/v1.7.0/Rustnet_LinuxDEB_amd64.deb\t%s\n' "$(printf '0%.0s' {1..64})"
}
curl() {
  local file="${@: -1}"
  printf 'Mock .deb' > "$file"
}
sha256sum() { cat >/dev/null; echo 'Mock download: OK'; }
dpkg-query() {
  [[ -f "$TMP/rustnet-installed" ]] || return 1
  printf '1.7.0-1'
}
dpkg() { return 1; }
dpkg-deb() {
  case "$3" in
    Package) printf 'rustnet-monitor' ;;
    Version) printf '1.7.0-1' ;;
    Architecture) printf 'amd64' ;;
    *) return 2 ;;
  esac
}
apt-get() { [[ "$1" == -s && "$2" == --no-remove && "$3" == install ]]; }
sudo() {
  [[ "$1" == apt-get && "$2" == install ]] || return 2
  : > "$TMP/rustnet-installed"
}
eval "$function_source"
install_official_deb domcyrus/rustnet Rustnet_LinuxDEB_amd64.deb rustnet-monitor
[[ -e "$TMP/rustnet-installed" ]]
rm "$TMP/rustnet-installed"
if install_official_deb domcyrus/rustnet Rustnet_LinuxDEB_amd64.deb rustnet > /dev/null 2>&1; then
  echo '[FAIL] Untrusted package-name mismatch was accepted' >&2
  exit 1
fi
MOCK_DEB
echo '[PASS] RustNet Debian metadata: expected rustnet-monitor, executable rustnet; mismatch still rejected'

echo '[PASS] Network monitoring opt-in profile is reproducible, non-destructive on plan, and separately documented'
