#!/usr/bin/env bash
set -Eeuo pipefail
# Rust installation is user-scoped; never silently curl|sh remote code as root.
if command -v rustup >/dev/null 2>&1; then
  rustup toolchain install stable
  rustup default stable
  rustup component add rust-analyzer rustfmt clippy
elif apt-cache show rustup >/dev/null 2>&1; then
  sudo apt-get install -y rustup
  rustup toolchain install stable
  rustup default stable
  rustup component add rust-analyzer rustfmt clippy
else
  echo '[WARN] rustup not in APT. Install via official rustup.rs after reviewing the installer.'
  echo '[WARN] No unofficial Rust installation performed.'
fi
