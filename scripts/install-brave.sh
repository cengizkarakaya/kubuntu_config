#!/usr/bin/env bash
set -Eeuo pipefail
arch="$(dpkg --print-architecture)"
case "$arch" in amd64|arm64) ;; *) echo "[FAIL] Unsupported Brave architecture: $arch" >&2; exit 1 ;; esac
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
curl -fsSL --retry 3 'https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg' -o "$tmp/key.gpg"
[[ -s "$tmp/key.gpg" ]] || { echo '[FAIL] Brave signing key missing' >&2; exit 1; }
gpg --batch --show-keys "$tmp/key.gpg" >/dev/null || { echo '[FAIL] Brave signing key invalid' >&2; exit 1; }
# Use an audited, hardcoded Debian Deb822 source; do NOT execute an upstream installer
# or blindly trust a downloaded .sources document with arbitrary additional repos.
cat > "$tmp/brave.sources" <<EOF
Types: deb
URIs: https://brave-browser-apt-release.s3.brave.com
Suites: stable
Components: main
Architectures: $arch
Signed-By: /usr/share/keyrings/brave-browser-archive-keyring.gpg
EOF
sudo install -Dm644 "$tmp/key.gpg" /usr/share/keyrings/brave-browser-archive-keyring.gpg
sudo install -Dm644 "$tmp/brave.sources" /etc/apt/sources.list.d/brave-browser-release.sources
sudo apt-get update
sudo apt-get install -y --no-install-recommends --no-remove brave-browser
command -v brave-browser >/dev/null || { echo '[FAIL] Brave package installed but command unavailable' >&2; exit 1; }
echo '[OK] Brave installed/updated to the newest signed APT stable candidate'
