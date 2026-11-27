#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
exec python3 -B "$ROOT/scripts/inventory-snapshot.py" "$@"
