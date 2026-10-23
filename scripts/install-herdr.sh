#!/usr/bin/env bash
set -Eeuo pipefail
# Official Herdr release binaries only; no curl|sh, no sudo, no moving user data.
# SHA-256 digests from the herdrdev/herdr GitHub release v0.9.5.
VERSION='v0.9.5'
command -v curl >/dev/null || { echo '[FAIL] curl is required for Herdr' >&2; exit 1; }
command -v sha256sum >/dev/null || { echo '[FAIL] sha256sum is required for Herdr' >&2; exit 1; }
[[ "$(uname -s)" == Linux ]] || { echo '[FAIL] Herdr installer supports Linux only' >&2; exit 1; }
case "$(uname -m)" in
  x86_64|amd64)
    asset='herdr-linux-x86_64'
    digest='14d9e8bc8b4a9e0118d77c32266f76d461f09b40342eb23752960bd89f59929d'
    ;;
  aarch64|arm64)
    asset='herdr-linux-aarch64'
    digest='17d7536f2da50859523680ef279dffcac8e4a235f4e46fe8da6c2ec44141897c'
    ;;
  *) echo "[FAIL] Unsupported Herdr architecture: $(uname -m)" >&2; exit 1 ;;
esac
target="$HOME/.local/bin/herdr"
if [[ -x "$target" && "$("$target" --version 2>/dev/null)" == 'herdr 0.9.5' ]]; then
  echo '[OK] Herdr v0.9.5 already installed in user PATH'
  exit 0
fi
temp_dir="$(mktemp -d)"
trap 'rm -rf -- "$temp_dir"' EXIT
curl -fL --retry 3 --retry-delay 2 --connect-timeout 15 \
  "https://github.com/herdrdev/herdr/releases/download/$VERSION/$asset" \
  -o "$temp_dir/$asset"
printf '%s  %s\n' "$digest" "$temp_dir/$asset" | sha256sum -c - || {
  echo '[FAIL] Herdr official release checksum mismatch' >&2; exit 1;
}
install -Dm755 "$temp_dir/$asset" "$target"
version="$("$target" --version 2>/dev/null)" || {
  echo '[FAIL] Herdr binary cannot execute after installation' >&2; exit 1;
}
[[ "$version" == 'herdr 0.9.5' ]] || {
  echo "[FAIL] Wrong Herdr version: $version" >&2; exit 1;
}
echo '[OK] Herdr v0.9.5 installed from checksum-verified official binary'
