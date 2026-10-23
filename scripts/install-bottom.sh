#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
[[ "$(uname -s)" == Linux ]] || { echo '[FAIL] Bottom requires Linux' >&2; exit 1; }
case "$(uname -m)" in x86_64|amd64) arch=x86_64;; aarch64|arm64) arch=aarch64;; *) echo '[FAIL] Unsupported Bottom architecture' >&2; exit 1;; esac
for cmd in curl sha256sum tar python3; do command -v "$cmd" >/dev/null || { echo "[FAIL] Bottom requires $cmd" >&2; exit 1; }; done
release="$(bash "$ROOT/scripts/latest-release.sh" ClementTsang/bottom "bottom_$arch-unknown-linux-gnu.tar.gz")"
IFS=$'\t' read -r tag url digest <<< "$release"
[[ -n "$tag" && -n "$url" && -n "$digest" ]] || { echo '[FAIL] Unable to resolve stable Bottom archive' >&2; exit 1; }
base="$HOME/.local/share/kubuntu-config/bottom"
dest="$base/$tag"
bin="$HOME/.local/bin/btm"
if [[ -e "$bin" && ! -L "$bin" ]] ||
   [[ -L "$bin" && "$(readlink -m "$bin")" != "$base/"* ]]; then
  echo '[FAIL] Existing Bottom binary is not managed by this repo; refusing overwrite' >&2; exit 1;
fi
if [[ -x "$dest/btm" ]] && [[ "$("$dest/btm" --version 2>/dev/null || true)" == *"$tag"* ]]; then
  echo "[OK] Latest stable Bottom $tag already present"
else
  tmp="$(mktemp -d)"
  trap 'rm -rf -- "$tmp"' EXIT
  curl --proto '=https' --tlsv1.2 -fL --retry 3 --connect-timeout 15 "$url" -o "$tmp/bottom.tar.gz"
  printf '%s  %s\n' "$digest" "$tmp/bottom.tar.gz" | sha256sum -c -
  mkdir -p "$tmp/unpacked"
  tar -xzf "$tmp/bottom.tar.gz" -C "$tmp/unpacked" --no-same-owner
  binary="$(find "$tmp/unpacked" -type f -name btm -print -quit)"
  [[ -n "$binary" ]] || { echo '[FAIL] Bottom archive missing btm executable' >&2; exit 1; }
  chmod u+x "$binary"
  [[ "$("$binary" --version 2>/dev/null || true)" == *"$tag"* ]] || {
    echo '[FAIL] Bottom binary version mismatch' >&2; exit 1;
  }
  mkdir -p "$base"
  [[ ! -e "$dest" ]] || { echo "[FAIL] Incomplete Bottom destination already exists: $dest" >&2; exit 1; }
  mkdir -p "$dest"
  install -m755 "$binary" "$dest/btm"
  rm -rf -- "$tmp"
  trap - EXIT
fi
mkdir -p "$HOME/.local/bin"
ln -sfn -- "$dest/btm" "$bin"
[[ "$("$bin" --version 2>/dev/null || true)" == *"$tag"* ]] || {
  echo '[FAIL] Bottom version verification failed' >&2; exit 1;
}
echo "[OK] Latest stable Bottom $tag installed"
