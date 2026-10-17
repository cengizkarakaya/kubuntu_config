#!/usr/bin/env bash
set -Eeuo pipefail
# Review source: https://github.com/KBeDevel/krohnkite-kwin6
# Pinned commit; build entirely in a temporary unprivileged directory.
SRC='https://github.com/KBeDevel/krohnkite-kwin6.git'
REV='fd67a3acd0a220bb6c1f41a1c7f3cc538ef19a82'
for tool in git npm node 7z make python3 kpackagetool6 kwriteconfig6; do
  command -v "$tool" >/dev/null || { echo "[WARN] Kröhnkite needs: $tool"; exit 1; }
done
if kpackagetool6 -t KWin/Script -s krohnkite >/dev/null 2>&1; then
  echo '[OK] Kröhnkite package present; reusing without force upgrade'
  kwriteconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled true
  exit 0
fi
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
git clone -q "$SRC" "$tmp/source"
cd "$tmp/source"
git checkout -q "$REV"
[[ "$(git rev-parse HEAD)" == "$REV" ]] || { echo 'Krohnkite revision mismatch'; exit 1; }
# Protect Arch key assignments; this is an explicit and documented local patch
# to upstream default key assignments, never an unreviewed source update.
python3 - <<'PY'
from pathlib import Path
import re
p=Path('res/shortcuts.qml')
s=p.read_text()
updates={
  'toggleFloat':'Meta+Shift+F',
  'floatAll':'',
  'rotate':'',
  'setMaster':'',
  'monocleLayout':''
}
for obj, seq in updates.items():
    pat=r'(id:\s*'+re.escape(obj)+r'\s*;[\s\S]*?sequence:\s*")[^"]*(";)'
    s,n=re.subn(pat,lambda m:m.group(1)+seq+m.group(2),s,count=1)
    if n!=1: raise SystemExit('Missing Kröhnkite shortcut '+obj)
p.write_text(s)
PY
npm ci --ignore-scripts --no-audit --no-fund
./node_modules/.bin/tsc
make package
package="$(find . -maxdepth 1 -name 'krohnkite-*.kwinscript' -type f -print -quit)"
[[ -n "$package" ]] || { echo 'Kröhnkite build failed: package missing'; exit 1; }
kpackagetool6 -t KWin/Script -i "$package"
kwriteconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled true
kwriteconfig6 --file kwinrc --group Script-krohnkite --key screenGapLeft 20
kwriteconfig6 --file kwinrc --group Script-krohnkite --key screenGapRight 20
kwriteconfig6 --file kwinrc --group Script-krohnkite --key screenGapTop 20
kwriteconfig6 --file kwinrc --group Script-krohnkite --key screenGapBottom 20
kwriteconfig6 --file kwinrc --group Script-krohnkite --key tileLayoutGap 5
echo '[OK] Kröhnkite KWin6 installed; log out/in and test shortcuts.'
