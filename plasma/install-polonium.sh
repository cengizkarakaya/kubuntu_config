#!/usr/bin/env bash
set -Eeuo pipefail
# Reproducible Polonium 1.2.1 KWin script, built in user scope from a pinned commit.
# Source: https://github.com/zeroxoneafour/polonium/releases/tag/v1.2.1
REPO='https://github.com/zeroxoneafour/polonium.git'
VERSION='1.2.1'
REV='3638b1625e95877f93279527de3b82b9b09aff3a'
[[ "${XDG_SESSION_TYPE:-}" == wayland ]] || { echo '[FAIL] Polonium requires Plasma Wayland (X11 unsupported)' >&2; exit 1; }
for command_name in git npm node make zip unzip kpackagetool6 kwriteconfig6 plasmashell; do
  command -v "$command_name" >/dev/null || { echo "[FAIL] Polonium requires $command_name" >&2; exit 1; }
done
node_ver="$(node -p 'process.versions.node')"
node_major="${node_ver%%.*}"
node_minor="${node_ver#*.}"; node_minor="${node_minor%%.*}"
# Vite 8 in the upstream npm workspace requires Node 20.19+ or 22.12+.
if ! { [[ "$node_major" == 20 && "$node_minor" =~ ^[0-9]+$ && "$node_minor" -ge 19 ]] ||
        [[ "$node_major" == 22 && "$node_minor" =~ ^[0-9]+$ && "$node_minor" -ge 12 ]] ||
        [[ "$node_major" =~ ^[0-9]+$ && "$node_major" -ge 24 ]]; }; then
  echo "[FAIL] Polonium build requires Node 20.19+, 22.12+ or 24+; found $node_ver" >&2
  exit 1
fi
plasma_version="$(plasmashell --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1 || true)"
[[ -n "$plasma_version" ]] && dpkg --compare-versions "$plasma_version" ge 6.4 || {
  echo "[FAIL] Polonium requires Plasma >= 6.4; found: ${plasma_version:-unknown}" >&2; exit 1;
}
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
installed="$data_home/kwin/scripts/polonium/metadata.json"
polonium_present=0
[[ -f "$installed" ]] && polonium_present=1
# Avoid unneeded npm/network runs when the already installed source has our pinned version.
if [[ -f "$installed" ]] && grep -Eq '"Version"[[:space:]]*:[[:space:]]*"1\.2\.1"' "$installed"; then
  echo '[OK] Polonium stable 1.2.1 already installed; not overwriting user configuration.'
else
  tmp="$(mktemp -d)"
  trap 'rm -rf -- "$tmp"' EXIT
  git clone --quiet --filter=blob:none "$REPO" "$tmp/source"
  cd "$tmp/source"
  git checkout --quiet --detach "$REV"
  [[ "$(git rev-parse HEAD)" == "$REV" ]] || { echo '[FAIL] Unexpected Polonium revision' >&2; exit 1; }
  [[ -f package-lock.json && -f Makefile ]] || { echo '[FAIL] Expected upstream build files missing' >&2; exit 1; }
  grep -Fq '"version": "1.2.1"' package.json || { echo '[FAIL] Unexpected Polonium version' >&2; exit 1; }
  # Upstream pins kwin-api as a Git submodule (gitlink), not as an npm registry
  # package. Verify URL and exact submodule commit before any npm build.
  grep -Fxq '	url = https://github.com/zeroxoneafour/kwin-api' .gitmodules || {
    echo '[FAIL] Unexpected Polonium kwin-api submodule URL' >&2; exit 1;
  }
  git submodule update --init --depth 1 -- kwin-api
  expected_api='8fc04bd086a1445ea67783eaa33517b70e01c063'
  [[ "$(git -C kwin-api rev-parse HEAD)" == "$expected_api" && -f kwin-api/package.json ]] || {
    echo '[FAIL] Polonium kwin-api submodule missing or at wrong revision' >&2; exit 1;
  }
  # Lockfile pins dependency contents. Do not run third-party npm install/postinstall scripts.
  npm ci --ignore-scripts --no-audit --no-fund
  [[ -x node_modules/.bin/esbuild ]] || { echo '[FAIL] Local esbuild binary missing' >&2; exit 1; }
  # Use a local binary, not npx automatic package downloads.
  ./node_modules/.bin/esbuild --bundle src/index.ts --outfile=polonium.mjs --format=esm --platform=neutral
  make build
  [[ -s polonium.kwinscript ]] || { echo '[FAIL] Polonium package was not generated' >&2; exit 1; }
  # Check package output paths before invoking KPackage.
  unzip -l polonium.kwinscript | grep -Fq 'pkg/metadata.json' || {
    echo '[FAIL] Polonium archive missing expected metadata' >&2; exit 1;
  }
  if ((polonium_present)); then
    kpackagetool6 -t KWin/Script -u polonium.kwinscript
  else
    kpackagetool6 -t KWin/Script -i polonium.kwinscript
  fi
  [[ -f "$installed" ]] || { echo '[FAIL] Polonium not found after installation' >&2; exit 1; }
fi
kwriteconfig6 --file kwinrc --group Plugins --key poloniumEnabled true
# Kröhnkite and Polonium both reposition windows; they must never run simultaneously.
kwriteconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled false
if [[ -d "$data_home/kwin/scripts/krohnkite" ]]; then
  echo '[INFO] Removing user-installed Kröhnkite; Polonium is the selected replacement.'
  kpackagetool6 -t KWin/Script -r krohnkite
  [[ ! -d "$data_home/kwin/scripts/krohnkite" ]] || {
    echo '[FAIL] Kröhnkite remains installed; remove it through KDE KWin Scripts.' >&2; exit 1;
  }
fi
echo '[OK] Pinned Polonium selected, Kröhnkite disabled. Log out/in before live testing.'
