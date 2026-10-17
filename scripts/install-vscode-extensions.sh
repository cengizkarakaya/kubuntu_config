#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
command -v code >/dev/null || { echo 'VS Code not installed'; exit 1; }
while IFS= read -r id; do
  [[ -n "$id" && "$id" != \#* ]] || continue
  code --install-extension "$id" || echo "[WARN] Extension failed: $id"
done < "$ROOT/applications/vscode-extensions.txt"
