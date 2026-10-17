#!/usr/bin/env bash
set -Eeuo pipefail
# Pinned Nordzy SVG assets; do not execute the upstream install script.
REV='829c47bda534d3c9f3c7d46c73a6fe9d946eca41'
target="$HOME/.local/share/icons/Nordzy-dark"
if [[ -f "$target/index.theme" ]]; then echo '[OK] Nordzy-dark icons already installed'; exit 0; fi
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git clone -q https://github.com/MolassesLover/Nordzy-icon.git "$tmp/source"
git -C "$tmp/source" checkout -q "$REV"
[[ "$(git -C "$tmp/source" rev-parse HEAD)" == "$REV" ]] || exit 1
mkdir -p "$target"
for dir in actions animations apps categories devices emblems mimes places status; do
  mkdir -p "$target/$dir"
  cp -a "$tmp/source/src/$dir/." "$target/$dir/"
  if [[ -d "$tmp/source/links/$dir" ]]; then
    cp -an "$tmp/source/links/$dir/." "$target/$dir/"
  fi
done
cp "$tmp/source/src/index.theme" "$target/index.theme"
sed -i 's/Nordzy/Nordzy-dark/g' "$target/index.theme"
# The upstream dark icon variant switches dark strokes to lighter Nord text.
for dir in actions devices places status; do
  for size in 16 22 24; do
    sub="$target/$dir/$size"
    [[ -d "$sub" ]] || continue
    find "$sub" -type f -name '*.svg' -print0 | xargs -0 -r sed -i 's/#2e3440/#d8dee9/g'
  done
done
for dir in actions apps categories emblems devices mimes places status; do
  sub="$target/$dir/symbolic"
  [[ -d "$sub" ]] || continue
  find "$sub" -type f -name '*.svg' -print0 | xargs -0 -r sed -i 's/#2e3440/#d8dee9/g'
done
if command -v kwriteconfig6 >/dev/null; then
  kwriteconfig6 --file kdeglobals --group Icons --key Theme Nordzy-dark
fi
echo '[OK] Nordzy-dark icon theme installed in user data; log out and in.'
