#!/usr/bin/env bash
set -Eeuo pipefail
# User-local pinned SVG theme assets. No upstream installer is executed.
REV='829c47bda534d3c9f3c7d46c73a6fe9d946eca41'
target="$HOME/.local/share/icons/Nordzy-dark"
if [[ -s "$target/index.theme" && -d "$target/actions" && -d "$target/apps" ]]; then
  echo '[OK] Nordzy-dark icons already present'
else
  tmp="$(mktemp -d)"
  trap 'rm -rf -- "$tmp"' EXIT
  git clone -q 'https://github.com/MolassesLover/Nordzy-icon.git' "$tmp/source"
  git -C "$tmp/source" checkout -q --detach "$REV"
  [[ "$(git -C "$tmp/source" rev-parse HEAD)" == "$REV" ]] || {
    echo '[FAIL] Nordzy revision mismatch' >&2; exit 1;
  }
  mkdir -p "$tmp/stage"
  for dir in actions animations apps categories devices emblems mimes places status; do
    [[ -d "$tmp/source/src/$dir" ]] || { echo "[FAIL] Icon directory missing: $dir" >&2; exit 1; }
    mkdir -p "$tmp/stage/$dir"
    cp -a "$tmp/source/src/$dir/." "$tmp/stage/$dir/"
    if [[ -d "$tmp/source/links/$dir" ]]; then
      cp -an "$tmp/source/links/$dir/." "$tmp/stage/$dir/"
    fi
  done
  [[ -s "$tmp/source/src/index.theme" ]] || { echo '[FAIL] Nordzy metadata missing' >&2; exit 1; }
  cp "$tmp/source/src/index.theme" "$tmp/stage/index.theme"
  sed -i 's/Nordzy/Nordzy-dark/g' "$tmp/stage/index.theme"
  for dir in actions devices places status; do
    for size in 16 22 24; do
      sub="$tmp/stage/$dir/$size"
      [[ -d "$sub" ]] || continue
      find "$sub" -type f -name '*.svg' -print0 | xargs -0 -r sed -i 's/#2e3440/#d8dee9/g'
    done
  done
  mkdir -p "$target"
  cp -a "$tmp/stage/." "$target/"
  rm -rf -- "$tmp"
  trap - EXIT
fi
[[ -s "$target/index.theme" ]] || { echo '[FAIL] Nordzy icon theme incomplete' >&2; exit 1; }
if command -v kwriteconfig6 >/dev/null; then
  kwriteconfig6 --file kdeglobals --group Icons --key Theme Nordzy-dark
fi
echo '[OK] Nordzy-dark icon theme ready; re-login to apply'
