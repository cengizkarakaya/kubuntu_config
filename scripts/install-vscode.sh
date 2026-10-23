#!/usr/bin/env bash
set -Eeuo pipefail
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
curl -fsSL --retry 3 https://packages.microsoft.com/keys/microsoft.asc -o "$tmp/key.asc"
gpg --batch --yes --dearmor -o "$tmp/microsoft.gpg" "$tmp/key.asc"
sudo install -Dm644 "$tmp/microsoft.gpg" /usr/share/keyrings/microsoft.gpg
cat > "$tmp/vscode.sources" <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64 arm64
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF
sudo install -Dm644 "$tmp/vscode.sources" /etc/apt/sources.list.d/vscode.sources
sudo apt-get update
sudo apt-get install -y --no-install-recommends --no-remove code
command -v code >/dev/null || { echo '[FAIL] VS Code binary missing' >&2; exit 1; }
echo '[OK] VS Code installed/updated to newest signed APT stable candidate'
