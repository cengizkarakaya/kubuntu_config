#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
export HOME="$tmp/home" XDG_STATE_HOME="$tmp/state"
mkdir -p "$HOME" "$tmp/bin"
export MOCK_LOG="$tmp/commands"
cat > "$tmp/bin/conda" <<'MOCK'
#!/bin/bash
printf '%s\n' "$*" >> "$MOCK_LOG"
case "$1 $2" in
  'env export') printf 'name: fenicsx\nchannels:\n  - conda-forge\ndependencies:\n  - fenics-dolfinx\nprefix: /private/example\n' ;;
  'list -n') printf '# platform: linux-64\n@EXPLICIT\nhttps://conda.anaconda.org/conda-forge/linux-64/example.conda\n' ;;
  'info --json') printf '{"platform":"linux-64","envs_dirs":["%s/envs"]}\n' "$HOME" ;;
  'env list') printf '{"envs":["%s/envs/fenicsx"]}\n' "$HOME" ;;
  'env create'|'create -n'|'run -n') : ;;
  *) exit 2 ;;
esac
MOCK
chmod +x "$tmp/bin/conda"
export PATH="$tmp/bin:$PATH"
bash "$ROOT/scripts/conda-envs.sh" plan
test ! -e "$XDG_STATE_HOME"
test ! -e "$MOCK_LOG"
bash "$ROOT/scripts/conda-envs.sh" export fenicsx
history="$(find "$XDG_STATE_HOME" -name fenicsx.env.yml)"
full="$(find "$XDG_STATE_HOME" -name fenicsx.full.yml)"
lock="$(find "$XDG_STATE_HOME" -name 'fenicsx.*.explicit.txt')"
test -s "$history" && test -s "$full" && test -s "$lock"
if grep -q '^prefix:' "$history" "$full"; then exit 1; fi
grep -Fxq '@EXPLICIT' "$lock"
test "$(stat -c %a "$history")" = 600
cp "$MOCK_LOG" "$tmp/before"
bash "$ROOT/scripts/conda-envs.sh" restore restored "$history" --kind yaml
cmp "$MOCK_LOG" "$tmp/before"
if bash "$ROOT/scripts/conda-envs.sh" restore fenicsx "$history" --kind yaml --apply; then exit 1; fi
if grep -q '^env create' "$MOCK_LOG"; then exit 1; fi
sed 's/linux-64/osx-arm64/' "$lock" > "$tmp/wrong.txt"
if bash "$ROOT/scripts/conda-envs.sh" restore restored "$tmp/wrong.txt" --kind explicit --apply; then exit 1; fi
bash "$ROOT/scripts/conda-envs.sh" restore restored "$lock" --kind explicit --apply
grep -q '^create -n restored' "$MOCK_LOG"
bash "$ROOT/scripts/conda-envs.sh" restore restored "$history" --kind yaml --apply
grep -q '^env create -n restored' "$MOCK_LOG"
bash "$ROOT/scripts/conda-envs.sh" verify restored --profile fenicsx
grep -q '^run -n restored python' "$MOCK_LOG"
echo '[PASS] Private exports, prefix removal, no-write restore plan, overwrite and platform guards, smoke-test invocation'
