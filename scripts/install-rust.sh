#!/usr/bin/env bash
set -Eeuo pipefail
# Trust system APT sources; never curl | sh or execute a remote installer.
if ! command -v rustup >/dev/null 2>&1; then
  if apt-cache show rustup >/dev/null 2>&1; then
    sudo apt-get install -y rustup
  else
    echo '[FAIL] rustup unavailable in APT and not in PATH.' >&2
    echo 'Install rustup via its official documented installer manually, then rerun bootstrap.' >&2
    exit 1
  fi
fi
rustup toolchain install stable --profile default
rustup update stable
rustup default stable
rustup component add rustfmt clippy rust-analyzer
command -v cargo >/dev/null || { echo '[FAIL] cargo unavailable after rustup installation' >&2; exit 1; }
echo '[OK] Rust toolchain and core components'
