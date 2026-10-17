#!/usr/bin/env bash
set -Eeuo pipefail
# Yazi upstream official Debian/Ubuntu stable repo:
# https://yazi-rs.github.io/docs/installation/#debian-and-ubuntu
# No nightly repository, no third-party packaging mirror, no remote shell script.
if apt-cache show yazi >/dev/null 2>&1; then
  echo '[OK] Yazi already available in configured signed APT repositories'
  exit 0
fi
arch="$(dpkg --print-architecture)"
case "$arch" in amd64|arm64) ;; *) echo "[FAIL] Unsupported Yazi architecture: $arch" >&2; exit 1 ;; esac
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
curl -fsSL --retry 3 'https://yazi-rs.github.io/builds/yazi-keyring.gpg' -o "$tmp/key.gpg"
[[ -s "$tmp/key.gpg" ]] || { echo '[FAIL] Yazi APT signing key missing' >&2; exit 1; }
gpg --batch --show-keys "$tmp/key.gpg" >/dev/null || { echo '[FAIL] Invalid Yazi signing key' >&2; exit 1; }
cat > "$tmp/yazi.sources" <<EOF
Types: deb
URIs: https://yazi-rs.github.io/builds/
Suites: stable
Components: main
Architectures: $arch
Signed-By: /usr/share/keyrings/yazi-keyring.gpg
EOF
sudo install -Dm644 "$tmp/key.gpg" /usr/share/keyrings/yazi-keyring.gpg
sudo install -Dm644 "$tmp/yazi.sources" /etc/apt/sources.list.d/yazi.sources
sudo apt-get update
apt-cache show yazi >/dev/null 2>&1 || { echo '[FAIL] Yazi not indexed after enabling official stable repo' >&2; exit 1; }
echo '[OK] Official signed Yazi stable APT repo enabled'
