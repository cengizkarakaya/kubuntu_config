#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
export MOCK_META="$tmp/release.json"
cat > "$tmp/bin/curl" <<'EOF'
#!/usr/bin/env bash
out=''
while (( $# )); do
  case "$1" in
    -o) out="$2"; shift 2 ;;
    *) shift ;;
  esac
done
[[ -n "$out" ]] || exit 2
[[ "${MOCK_CURL_FAIL:-0}" != 1 ]] || { echo 'curl: (22) HTTP 403 (mock)' >&2; exit 22; }
cp "$MOCK_META" "$out"
EOF
chmod +x "$tmp/bin/curl"
cat > "$tmp/bin/gh" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  auth) [[ "${MOCK_GH_MODE:-disabled}" != disabled ]] ;;
  api)
    [[ "${MOCK_GH_MODE:-disabled}" == success ]] || exit 22
    cat "$MOCK_META"
    ;;
  *) exit 2 ;;
esac
EOF
chmod +x "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH"
python3 - "$MOCK_META" <<'PY'
import json,sys
json.dump({"tag_name":"v3.4.5","draft":False,"prerelease":False,"assets":[
  {"name":"test.bin","browser_download_url":
  "https://github.com/example/tool/releases/download/v3.4.5/test.bin",
  "digest":"sha256:"+"a"*64}]},open(sys.argv[1],"w"))
PY
output="$(bash "$ROOT/scripts/latest-release.sh" example/tool test.bin)"
[[ "$output" == $'v3.4.5\thttps://github.com/example/tool/releases/download/v3.4.5/test.bin\t'$(printf 'a%.0s' {1..64}) ]] || {
  echo '[FAIL] Valid GitHub release not parsed' >&2; exit 1;
}
python3 - "$MOCK_META" <<'PY'
import json,sys
p=sys.argv[1]
with open(p) as f: x=json.load(f)
x["assets"][0]["name"]="helix-v3.4.5-x86_64-linux.tar.xz"
x["assets"][0]["browser_download_url"]="https://github.com/example/tool/releases/download/v3.4.5/helix-v3.4.5-x86_64-linux.tar.xz"
with open(p,"w") as f: json.dump(x,f)
PY
bash "$ROOT/scripts/latest-release.sh" example/tool 'helix-{tag}-x86_64-linux.tar.xz' | grep -Fq 'helix-v3.4.5-x86_64-linux.tar.xz'
python3 - "$MOCK_META" <<'PY'
import json,sys
p=sys.argv[1]
with open(p) as f: x=json.load(f)
x["assets"][0]["name"]="test.bin"
x["assets"][0]["browser_download_url"]="https://github.com/example/tool/releases/download/v3.4.5/test.bin"
with open(p,"w") as f: json.dump(x,f)
PY
for field in prerelease missing_digest wrong_url; do
  python3 - "$MOCK_META" "$field" <<'PY'
import json,sys
p,case=sys.argv[1:]
with open(p) as f: x=json.load(f)
x["prerelease"]=case=="prerelease"
x["assets"][0]["digest"]="" if case=="missing_digest" else "sha256:"+"a"*64
x["assets"][0]["browser_download_url"]=(
    "https://example.com/evil" if case=="wrong_url"
    else "https://github.com/example/tool/releases/download/v3.4.5/test.bin")
with open(p,"w") as f: json.dump(x,f)
PY
  if bash "$ROOT/scripts/latest-release.sh" example/tool test.bin; then
    echo "[FAIL] Unsafe release was accepted: $field" >&2; exit 1;
  fi
done
# Restore valid metadata after the negative security tests.
python3 - "$MOCK_META" <<'PY'
import json,sys
p=sys.argv[1]
with open(p) as f: x=json.load(f)
x["prerelease"]=False
x["assets"][0]["name"]="test.bin"
x["assets"][0]["digest"]="sha256:"+"a"*64
x["assets"][0]["browser_download_url"]="https://github.com/example/tool/releases/download/v3.4.5/test.bin"
with open(p,"w") as f: json.dump(x,f)
PY
# Authenticated gh API must be used ahead of anonymous curl.
export MOCK_GH_MODE=success MOCK_CURL_FAIL=1
output="$(bash "$ROOT/scripts/latest-release.sh" example/tool test.bin)"
[[ "$output" == $'v3.4.5\thttps://github.com/example/tool/releases/download/v3.4.5/test.bin\t'$(printf 'a%.0s' {1..64}) ]] || {
  echo '[FAIL] Authenticated gh API response not used' >&2; exit 1;
}
# If authenticated gh fails, retry anonymous curl (still validate metadata).
export MOCK_GH_MODE=fail MOCK_CURL_FAIL=0
output="$(bash "$ROOT/scripts/latest-release.sh" example/tool test.bin)"
[[ "$output" == v3.4.5$'\t'* ]] || { echo '[FAIL] Anonymous fallback failed' >&2; exit 1; }
# Fail closed when both authenticated and anonymous lookups are unavailable.
export MOCK_GH_MODE=fail MOCK_CURL_FAIL=1
if bash "$ROOT/scripts/latest-release.sh" example/tool test.bin >"$tmp/failed.stdout" 2>"$tmp/failed.stderr"; then
  echo '[FAIL] Resolver accepted two unavailable metadata sources' >&2; exit 1;
fi
[[ ! -s "$tmp/failed.stdout" ]] || { echo '[FAIL] Resolver emitted untrusted metadata' >&2; exit 1; }
grep -Fq 'gh auth status' "$tmp/failed.stderr"
echo '[PASS] Authenticated lookup, safe anonymous fallback and explicit 403 failure checked'
echo '[PASS] Latest-release resolver requires stable numeric tags, correct upstream URLs and GitHub SHA256 digests'
