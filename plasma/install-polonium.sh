#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# Install the latest *stable release artifact*, validated against its SHA256
# and KWin metadata. Do not build arbitrary HEAD or use unverified scripts.
[[ "${XDG_SESSION_TYPE:-}" == wayland ]] || {
  echo '[FAIL] Polonium requires a Plasma Wayland session' >&2; exit 1;
}
for cmd in python3 curl sha256sum unzip kpackagetool6 kwriteconfig6 plasmashell dpkg; do
  command -v "$cmd" >/dev/null || { echo "[FAIL] Polonium requires $cmd" >&2; exit 1; }
done
plasma_version="$(plasmashell --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1 || true)"
[[ -n "$plasma_version" ]] && dpkg --compare-versions "$plasma_version" ge 6.4 || {
  echo "[FAIL] Polonium requires Plasma >= 6.4; found ${plasma_version:-unknown}" >&2; exit 1;
}
IFS=$'\t' read -r tag url digest < <(bash "$ROOT/scripts/latest-release.sh" zeroxoneafour/polonium polonium.kwinscript)
[[ -n "${tag:-}" && -n "${url:-}" && -n "${digest:-}" ]] || {
  echo '[FAIL] Unable to resolve latest stable Polonium release' >&2; exit 1;
}
version="${tag#v}"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
installed="$data_home/kwin/scripts/polonium/metadata.json"
if [[ -r "$installed" ]] && python3 - "$installed" "$version" <<'PY'
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8") as f: m = json.load(f)
    sys.exit(0 if m.get("KPlugin", {}).get("Id") == "polonium" and
             m.get("KPlugin", {}).get("Version") == sys.argv[2] else 1)
except (OSError, ValueError): sys.exit(1)
PY
then
  echo "[OK] Latest stable Polonium already installed: $version"
else
  tmp="$(mktemp -d)"
  trap 'rm -rf -- "$tmp"' EXIT
  curl --proto '=https' --tlsv1.2 -fL --retry 3 --connect-timeout 15 \
    "$url" -o "$tmp/polonium.kwinscript"
  printf '%s  %s\n' "$digest" "$tmp/polonium.kwinscript" | sha256sum -c -
  unzip -t "$tmp/polonium.kwinscript" >/dev/null
  unzip -p "$tmp/polonium.kwinscript" pkg/metadata.json | python3 -c '
import json, sys
m=json.load(sys.stdin)
if m.get("KPlugin",{}).get("Id")!="polonium" or m["KPlugin"].get("Version")!=sys.argv[1]:
    sys.exit("Unexpected Polonium KWin metadata: refusing install")
' "$version"
  if [[ -f "$installed" ]]; then
    kpackagetool6 -t KWin/Script -u "$tmp/polonium.kwinscript"
  else
    kpackagetool6 -t KWin/Script -i "$tmp/polonium.kwinscript"
  fi
  [[ -r "$installed" ]] || { echo '[FAIL] Polonium not installed after KPackage transaction' >&2; exit 1; }
  python3 - "$installed" "$version" <<'PY'
import json,sys
with open(sys.argv[1],encoding="utf-8") as f: m=json.load(f)
assert m.get("KPlugin",{}).get("Id")=="polonium" and m["KPlugin"].get("Version")==sys.argv[2], "Polonium version mismatch"
PY
  echo "[OK] Latest stable Polonium $version installed and verified"
fi
kwriteconfig6 --file kwinrc --group Plugins --key poloniumEnabled true
kwriteconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled false
if [[ -d "$data_home/kwin/scripts/krohnkite" ]]; then
  echo '[INFO] Removing conflicting user-installed Kröhnkite'
  kpackagetool6 -t KWin/Script -r krohnkite
  [[ ! -d "$data_home/kwin/scripts/krohnkite" ]] || {
    echo '[FAIL] Conflicting Kröhnkite remains; check KWin Scripts' >&2; exit 1;
  }
fi
echo '[OK] Polonium selected. Re-login required to activate the updated KWin script.'
