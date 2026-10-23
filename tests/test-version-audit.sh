#!/usr/bin/env bash
set -Eeuo pipefail
REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/bin" "$work/root/scripts" "$work/root/packages" \
  "$work/home/.local/bin" "$work/home/.local/share/fonts/FiraCodeNerd"
cp "$REPO/scripts/version-audit.sh" "$work/root/scripts/version-audit.sh"
printf 'goodpkg\n' > "$work/root/packages/apt.txt"
printf 'org.example.App\tExample\n' > "$work/root/packages/flatpak.tsv"
printf 'v3.5.1\n' > "$work/home/.local/share/fonts/FiraCodeNerd/.kubuntu-config-version"
export HOME="$work/home"
export MOCK_CANDIDATE=2.0
export KUBUNTU_SKIP_PLASMA=1
cat > "$work/home/.local/bin/herdr" <<'EOF'
#!/usr/bin/env bash
echo 'herdr 0.9.5'
EOF
cat > "$work/bin/dpkg-query" <<'EOF'
#!/usr/bin/env bash
printf '2.0'
EOF
cat > "$work/bin/apt-cache" <<'EOF'
#!/usr/bin/env bash
printf 'Package:\n  Installed: 2.0\n  Candidate: %s\n' "${MOCK_CANDIDATE:-2.0}"
EOF
cat > "$work/bin/flatpak" <<'EOF'
#!/usr/bin/env bash
printf 'abc123\n'
EOF
cat > "$work/root/scripts/latest-release.sh" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  herdrdev/herdr) printf 'v0.9.5\t%s\t%s\n' https://github.com/herdrdev/herdr/release dummysha ;;
  zeroxoneafour/polonium) printf 'v1.2.1\t%s\t%s\n' https://github.com/zeroxoneafour/polonium/release dummysha ;;
  ryanoasis/nerd-fonts) printf 'v3.5.1\t%s\t%s\n' https://github.com/ryanoasis/nerd-fonts/release dummysha ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$work/bin/"* "$work/home/.local/bin/herdr" "$work/root/scripts/latest-release.sh"
export PATH="$work/bin:$PATH"
bash "$work/root/scripts/version-audit.sh"
export MOCK_CANDIDATE=3.0
if bash "$work/root/scripts/version-audit.sh"; then
  echo '[FAIL] Audit incorrectly accepted an outdated APT package' >&2
  exit 1
fi
echo '[PASS] Version audit passes newest candidates and fails on stale installed packages'
