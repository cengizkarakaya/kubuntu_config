#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
[[ "$(uname -s)" == Linux ]] || { echo '[FAIL] Helix requires Linux' >&2; exit 1; }
case "$(uname -m)" in x86_64|amd64) arch=x86_64;; aarch64|arm64) arch=aarch64;; *) echo '[FAIL] Unsupported Helix architecture' >&2; exit 1;; esac
for cmd in curl sha256sum tar python3; do command -v "$cmd" >/dev/null || { echo "[FAIL] Helix requires $cmd" >&2; exit 1; }; done
release="$(bash "$ROOT/scripts/latest-release.sh" helix-editor/helix "helix-{tag}-$arch-linux.tar.xz")"
IFS=$'\t' read -r tag url digest <<< "$release"
[[ -n "$tag" && -n "$url" && -n "$digest" ]] || { echo '[FAIL] Unable to resolve stable Helix archive' >&2; exit 1; }
bin="$HOME/.local/bin/hx"
runtime_link="$HOME/.config/helix/runtime"
base="$HOME/.local/share/kubuntu-config/helix"
dest="$base/$tag"
if [[ -e "$bin" && ! -L "$bin" ]] || [[ -e "$runtime_link" && ! -L "$runtime_link" ]]; then
  echo '[FAIL] Unmanaged Helix executable or runtime exists; refusing to overwrite user files' >&2; exit 1;
fi
if [[ -L "$bin" && "$(readlink -m "$bin")" != "$base/"* ]] ||
   [[ -L "$runtime_link" && "$(readlink -m "$runtime_link")" != "$base/"* ]]; then
  echo '[FAIL] Helix symlink belongs to another installation; refusing overwrite' >&2; exit 1
fi
if [[ -x "$dest/hx" && -d "$dest/runtime" ]] &&
   [[ "$("$dest/hx" --version 2>/dev/null || true)" == *"$tag"* ]]; then
  echo "[OK] Latest Helix $tag already present"
else
  tmp="$(mktemp -d)"
  trap 'rm -rf -- "$tmp"' EXIT
  curl --proto '=https' --tlsv1.2 -fL --retry 3 --connect-timeout 15 "$url" -o "$tmp/helix.tar.xz"
  printf '%s  %s\n' "$digest" "$tmp/helix.tar.xz" | sha256sum -c -
  mkdir -p "$tmp/unpacked"
  tar -xJf "$tmp/helix.tar.xz" -C "$tmp/unpacked" --no-same-owner
  binary="$(find "$tmp/unpacked" -type f -name hx -print -quit)"
  [[ -n "$binary" && -d "$(dirname "$binary")/runtime" ]] || {
    echo '[FAIL] Helix release missing executable or runtime' >&2; exit 1;
  }
  source_dir="$(dirname "$binary")"
  chmod u+x "$source_dir/hx"
  [[ "$("$source_dir/hx" --version 2>/dev/null || true)" == *"$tag"* ]] || {
    echo '[FAIL] Helix binary version mismatch' >&2; exit 1;
  }
  mkdir -p "$base"
  [[ ! -e "$dest" ]] || { echo "[FAIL] Incomplete Helix destination already exists: $dest" >&2; exit 1; }
  mv -- "$source_dir" "$dest"
  rm -rf -- "$tmp"
  trap - EXIT
fi
mkdir -p "$HOME/.local/bin" "$HOME/.config/helix"
ln -sfn -- "$dest/hx" "$bin"
ln -sfn -- "$dest/runtime" "$runtime_link"
[[ "$("$bin" --version 2>/dev/null || true)" == *"$tag"* && -d "$runtime_link" ]] || {
  echo '[FAIL] Helix binary/runtime verification failed' >&2; exit 1;
}
echo "[OK] Latest stable Helix $tag installed with runtime"
