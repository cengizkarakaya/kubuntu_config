#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/mock-bin" "$work/home" "$work/flatpak-state"
export HOME="$work/home"
export MOCK_LOG="$work/log"
export MOCK_FLAT_STATE="$work/flatpak-state"
: > "$MOCK_LOG"
cat > "$work/mock-bin/apt-cache" <<'EOF'
#!/usr/bin/env bash
[[ "$1" == show ]] || exit 2
[[ "$2" == goodpkg ]]
EOF
cat > "$work/mock-bin/dpkg-query" <<'EOF'
#!/usr/bin/env bash
[[ "${*: -1}" == goodpkg ]] || exit 1
printf 'install ok installed\n'
EOF
cat > "$work/mock-bin/sudo" <<'EOF'
#!/usr/bin/env bash
printf 'sudo: %s\n' "$*" >> "$MOCK_LOG"
[[ "$1" == apt-get ]] || exit 1
exit 0
EOF
cat > "$work/mock-bin/flatpak" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  remote-add) exit 0 ;;
  info) [[ -f "$MOCK_FLAT_STATE/${*: -1}" ]] ;;
  install)
    id="${*: -1}"
    [[ "${MOCK_FLAT_FAIL:-}" != "$id" ]] || exit 42
    touch "$MOCK_FLAT_STATE/$id"
    ;;
  *) exit 2 ;;
esac
EOF
chmod +x "$work/mock-bin/"*
export PATH="$work/mock-bin:$PATH"
printf 'goodpkg\n' > "$work/apt.txt"
bash "$ROOT/scripts/install-apt.sh" "$work/apt.txt"
[[ ! -e "$HOME/.local/state/kubuntu-config/apt-unavailable.txt" ]]
grep -q 'sudo: apt-get install' "$MOCK_LOG"
printf 'goodpkg\nmissingpkg\n' > "$work/apt.txt"
if bash "$ROOT/scripts/install-apt.sh" "$work/apt.txt"; then
  echo '[FAIL] APT installer accepted a missing package' >&2; exit 1
fi
grep -q missingpkg "$HOME/.local/state/kubuntu-config/apt-unavailable.txt"
echo '[PASS] APT installer fails and reports missing packages'
bash "$ROOT/scripts/install-flatpaks.sh"
[[ -e "$MOCK_FLAT_STATE/net.cozic.joplin_desktop" ]]
rm -f "$MOCK_FLAT_STATE/net.cozic.joplin_desktop"
export MOCK_FLAT_FAIL='net.cozic.joplin_desktop'
if bash "$ROOT/scripts/install-flatpaks.sh"; then
  echo '[FAIL] Flatpak installer accepted an unavailable app' >&2; exit 1
fi
echo '[PASS] Flatpak installer fails on missing apps'
# Re-enable the single authorized application-extension path: pinned Arch Yazi.
mkdir -p "$HOME/.config/yazi" "$HOME/.local/bin"
ln -s "$ROOT/dotfiles/yazi/.config/yazi/package.toml" "$HOME/.config/yazi/package.toml"
touch "$HOME/.local/bin/yazi-rg"
chmod +x "$HOME/.local/bin/yazi-rg"
for cmd in yazi ya git rg fzf bat zoxide; do
  cat > "$work/mock-bin/$cmd" <<'EOF'
#!/usr/bin/env bash
if [[ "${0##*/}" == ya && "${1:-}" == pkg && "${2:-}" == install ]]; then
  printf '%s\\n' 'yazi pkg install' >> "$MOCK_LOG"
  for p in git full-border toggle-pane smart-enter jump-to-char smart-filter smart-paste chmod mount diff; do
    mkdir -p "$HOME/.config/yazi/plugins/$p.yazi"
  done
  mkdir -p "$HOME/.config/yazi/flavors/nord.yazi"
fi
EOF
  chmod +x "$work/mock-bin/$cmd"
done
bash "$ROOT/scripts/install-yazi-plugins.sh"
grep -q 'yazi pkg install' "$MOCK_LOG"
echo '[PASS] The authorized Yazi plugin installer uses the pinned Arch manifest and verifies 10 plugins + Nord flavor'
