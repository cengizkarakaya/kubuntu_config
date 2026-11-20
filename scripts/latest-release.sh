#!/usr/bin/env bash
set -Eeuo pipefail
# Retrieve the newest non-draft, non-prerelease GitHub release at RUN TIME.
# Output: <tag><TAB><verified asset URL><TAB><SHA256>
# Fail closed if Github doesn't advertise a trusted SHA256 digest.
repo="${1:?Usage: latest-release.sh owner/repo asset-name}"
asset="${2:?Usage: latest-release.sh owner/repo asset-name}"
[[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ &&
   "$asset" =~ ^[A-Za-z0-9_.{}-]+$ ]] || { echo '[FAIL] Invalid GitHub repository or asset' >&2; exit 2; }
for cmd in curl python3; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "[FAIL] Required for release lookup: $cmd" >&2; exit 1; }
done
tmp="$(mktemp)"
trap 'rm -f -- "$tmp"' EXIT
# Prefer an existing GitHub CLI login. Anonymous API lookups share the
# per-IP limit (often exhausted on VPNs/shared networks); gh API calls are
# authenticated without printing or storing the token in this repository.
fetched=0
if command -v gh >/dev/null 2>&1 && gh auth token --hostname github.com >/dev/null 2>&1; then
  if gh api --hostname github.com -H 'Accept: application/vnd.github+json' \
    "repos/$repo/releases/latest" > "$tmp"; then
    fetched=1
  else
    echo '[WARN] Authenticated GitHub release lookup failed; trying public HTTPS.' >&2
  fi
fi
if ((fetched == 0)); then
  if ! curl --proto '=https' --tlsv1.2 -fsSL --retry 3 --connect-timeout 15 \
    -H 'Accept: application/vnd.github+json' \
    "https://api.github.com/repos/$repo/releases/latest" -o "$tmp"; then
    echo '[FAIL] GitHub release metadata could not be retrieved; no application was changed.' >&2
    echo '[HINT] HTTP 403 can mean an exhausted anonymous API limit or another access restriction.' >&2
    echo '[HINT] Check: gh auth status --hostname github.com' >&2
    echo '[HINT] If not signed in: gh auth login --hostname github.com' >&2
    echo '[HINT] Then retry: sysup resume (or the individual installer).' >&2
    exit 1
  fi
fi
python3 - "$tmp" "$repo" "$asset" <<'PY'
import json, re, sys
path, repo, asset = sys.argv[1:]
with open(path, encoding="utf-8") as handle:
    data = json.load(handle)
tag = data.get("tag_name", "")
if data.get("draft") or data.get("prerelease") or not re.fullmatch(r"v?\d+(?:\.\d+){1,3}", tag):
    sys.exit("[FAIL] Latest release is not a verified stable numeric tag")
asset = asset.replace("{tag}", tag)
expected = f"https://github.com/{repo}/releases/download/{tag}/{asset}"
matches = [x for x in data.get("assets", []) if x.get("name") == asset]
if len(matches) != 1 or matches[0].get("browser_download_url") != expected:
    sys.exit("[FAIL] Expected asset not published at the official release URL")
digest = matches[0].get("digest") or ""
if not re.fullmatch(r"sha256:[a-fA-F0-9]{64}", digest):
    sys.exit("[FAIL] GitHub release has no verified SHA-256 asset digest; refusing download")
print(f"{tag}\t{expected}\t{digest.split(':', 1)[1].lower()}")
PY
