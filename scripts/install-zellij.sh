#!/usr/bin/env bash
set -Eeuo pipefail
# Zellij is missing from standard Ubuntu package archives; compile a pinned
# release in the user account using crates.io lockfile integrity checks.
export PATH="$HOME/.cargo/bin:$PATH"
VERSION='0.45.1'
command -v cargo >/dev/null || { echo '[FAIL] Cargo missing: install the Rust toolchain first' >&2; exit 1; }
if command -v zellij >/dev/null 2>&1 && zellij --version 2>/dev/null | grep -Eq '(^|[[:space:]])0\.45\.1([[:space:]]|$)'; then
  echo '[OK] Zellij 0.45.1 already available'
  exit 0
fi
cargo install --locked --version "$VERSION" zellij
[[ -x "$HOME/.cargo/bin/zellij" ]] || { echo '[FAIL] Zellij binary not produced by Cargo' >&2; exit 1; }
"$HOME/.cargo/bin/zellij" --version | grep -Fq "$VERSION" || {
  echo '[FAIL] Zellij installed version mismatch' >&2; exit 1;
}
echo '[OK] Zellij pinned version built in user scope; Rust/Cargo handles dependency checks'
