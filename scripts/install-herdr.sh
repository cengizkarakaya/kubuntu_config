#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# Always query the latest upstream STABLE release, verify its SHA256,
# and refuse unsigned/unknown assets. Run entirely without sudo.
[[ "$(uname -s)" == Linux ]] || { echo '[FAIL] Herdr requires Linux' >&2; exit 1; }
case "$(uname -m)" in
  x86_64|amd64) asset='herdr-linux-x86_64' ;;
  aarch64|arm64) asset='herdr-linux-aarch64' ;;
  *) echo "[FAIL] Unsupported Herdr architecture: $(uname -m)" >&2; exit 1 ;;
esac
IFS=$'\t' read -r tag url digest < <(bash "$ROOT/scripts/latest-release.sh" herdrdev/herdr "$asset")
[[ -n "${tag:-}" && -n "${url:-}" && -n "${digest:-}" ]] || {
  echo '[FAIL] Could not resolve newest stable Herdr release' >&2; exit 1;
}
expected="herdr ${tag#v}"
target="$HOME/.local/bin/herdr"
if [[ -x "$target" && "$("$target" --version 2>/dev/null || true)" == "$expected" ]]; then
  echo "[OK] Latest stable Herdr already installed: $expected"
  exit 0
fi
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
curl --proto '=https' --tlsv1.2 -fL --retry 3 --connect-timeout 15 \
  "$url" -o "$tmp/herdr"
printf '%s  %s\n' "$digest" "$tmp/herdr" | sha256sum -c - || {
  echo '[FAIL] Herdr release SHA-256 mismatch' >&2; exit 1;
}
chmod 755 "$tmp/herdr"
[[ "$("$tmp/herdr" --version 2>/dev/null || true)" == "$expected" ]] || {
  echo '[FAIL] Herdr executable version did not match upstream release' >&2; exit 1;
}
mkdir -p "$HOME/.local/bin"
install -m755 "$tmp/herdr" "$HOME/.local/bin/.herdr-staged-$$"
mv -f -- "$HOME/.local/bin/.herdr-staged-$$" "$target"
echo "[OK] Installed verified latest stable Herdr $tag"
