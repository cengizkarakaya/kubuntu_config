#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
tmp="$(mktemp -d)"
external="$(mktemp -d /dev/shm/kubuntu-restic-test.XXXXXXXX)"
trap 'rm -rf -- "$tmp" "$external"' EXIT
export HOME="$tmp/home" XDG_STATE_HOME="$tmp/state" MOCK_LOG="$tmp/log"
mkdir -p "$HOME/project" "$tmp/bin"
printf 'project\nmissing\n' > "$tmp/manifest"
cat > "$tmp/bin/restic" <<'MOCK'
#!/bin/bash
printf '%s\n' "$*" >> "$MOCK_LOG"
MOCK
chmod +x "$tmp/bin/restic"
export PATH="$tmp/bin:$PATH"
tool="$ROOT/scripts/backup-personal.sh"
bash "$tool" --plan --manifest "$tmp/manifest" > "$tmp/plan"
grep -Fq 'PRESENT:' "$tmp/plan"
grep -Fq 'ABSENT:' "$tmp/plan"
test ! -e "$MOCK_LOG"
test ! -e "$XDG_STATE_HOME"
if bash "$tool" --init --repo "$ROOT/backup-test"; then exit 1; fi
if bash "$tool" --init --repo "$tmp/same-filesystem"; then exit 1; fi
if bash "$tool" --backup --repo "$external/restic"; then exit 1; fi
test ! -e "$MOCK_LOG"
bash "$tool" --init --repo "$external/restic"
grep -Fq ' init' "$MOCK_LOG"
bash "$tool" --backup --repo "$external/restic" --manifest "$tmp/manifest"
grep -Fq "backup --one-file-system -- $HOME/project" "$MOCK_LOG"
bash "$tool" --verify --repo "$external/restic"
grep -Fq 'check --read-data' "$MOCK_LOG"
mkdir "$tmp/restore"
bash "$tool" --restore latest --repo "$external/restic" --target "$tmp/restore"
grep -Fq "restore latest --target $tmp/restore" "$MOCK_LOG"
touch "$tmp/restore/existing"
if bash "$tool" --restore latest --repo "$external/restic" --target "$tmp/restore"; then exit 1; fi
if bash "$tool" --restore latest --repo "$external/restic" --target "$HOME"; then exit 1; fi
printf '../outside\n' > "$tmp/bad"
if bash "$tool" --plan --manifest "$tmp/bad"; then exit 1; fi
echo '[PASS] Restic mock: no-write plan, private manifest, separate filesystem, backup and restore safety'
