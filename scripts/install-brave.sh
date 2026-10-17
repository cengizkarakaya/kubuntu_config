#!/usr/bin/env bash
set -Eeuo pipefail
if command -v brave-browser >/dev/null 2>&1; then echo '[OK] Brave present'; exit 0; fi
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
curl -fsSL --retry 3 https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg -o "$tmp/key.gpg"
curl -fsSL --retry 3 https://brave-browser-apt-release.s3.brave.com/brave-browser.sources -o "$tmp/brave.sources"
grep -Fq 'brave-browser-apt-release.s3.brave.com' "$tmp/brave.sources" || exit 1
grep -Fq 'Signed-By:' "$tmp/brave.sources" || exit 1
sudo install -Dm644 "$tmp/key.gpg" /usr/share/keyrings/brave-browser-archive-keyring.gpg
sudo install -Dm644 "$tmp/brave.sources" /etc/apt/sources.list.d/brave-browser-release.sources
sudo apt-get update
sudo apt-get install -y brave-browser
