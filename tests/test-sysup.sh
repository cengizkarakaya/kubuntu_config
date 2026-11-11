#!/usr/bin/env bash
# Offline sysup integration tests; only mocked executables are ever called.
set -Eeuo pipefail

if ((EUID == 0)); then
    echo '[SKIP] sysup tests require an unprivileged user'
    exit 0
fi

SYSUP="${TEST_SYSUP:-$(cd -- "$(dirname -- "$0")/.." && pwd)/scripts/sysup}"
WORK="$(mktemp -d)"
trap 'rm -rf -- "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/home/.local/state/kubuntu-config" "$WORK/repo/scripts"
touch "$WORK/repo/bootstrap.sh" "$WORK/home/.local/state/kubuntu-config/bootstrap.lock"
for name in helix bottom herdr codex; do
  printf '#!/usr/bin/env bash\nprintf "install-%%s\\n" "%s" >> "$MOCK_TRACE"\n' "$name" > "$WORK/repo/scripts/install-$name.sh"
done
cat > "$WORK/bin/getent" <<'STUB'
#!/usr/bin/env bash
if [[ "$1" == ahosts ]]; then exit 0; fi
exec /usr/bin/getent "$@"
STUB
cat > "$WORK/bin/sudo" <<'STUB'
#!/usr/bin/env bash
exec "$@"
STUB
cat > "$WORK/bin/dpkg" <<'STUB'
#!/usr/bin/env bash
[[ "$1" == --audit ]]
STUB
cat > "$WORK/bin/apt-get" <<'STUB'
#!/usr/bin/env bash
printf 'apt-get %s\n' "$*" >> "$MOCK_TRACE"
if [[ "${MOCK_APT_SLEEP:-0}" == 1 && "$*" == *update* ]]; then sleep 2; fi
STUB
cat > "$WORK/bin/flatpak" <<'STUB'
#!/usr/bin/env bash
echo flatpak >> "$MOCK_TRACE"
if [[ "${MOCK_FLATPAK_FAIL:-0}" == 1 ]]; then exit 42; fi
STUB
cat > "$WORK/bin/snap" <<'STUB'
#!/usr/bin/env bash
echo snap >> "$MOCK_TRACE"
STUB
cat > "$WORK/bin/rustup" <<'STUB'
#!/usr/bin/env bash
echo rustup >> "$MOCK_TRACE"
STUB
cat > "$WORK/bin/fwupdmgr" <<'STUB'
#!/usr/bin/env bash
echo firmware >> "$MOCK_TRACE"
exit 2
STUB
chmod +x "$WORK/bin/"*
export HOME="$WORK/home" PATH="$WORK/bin:$PATH" MOCK_TRACE="$WORK/trace"

# A failed independent stage must not stop Snap, Rustup, or installer scripts.
export MOCK_FLATPAK_FAIL=1
if bash "$SYSUP" __execute interactive "$WORK/repo" "$(id -u)" 0 '' 'test-failed'; then
    echo 'expected independent Flatpak failure' >&2; exit 1
fi
grep -q 'snap' "$MOCK_TRACE"
grep -q 'rustup' "$MOCK_TRACE"
grep -q 'install-codex' "$MOCK_TRACE"
[[ "$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["status"])' "$HOME/.local/state/kubuntu-config/status.json")" == failed ]]

# Resume must skip completed APT and Snap stages, but repeat failed Flatpak.
: > "$MOCK_TRACE"
export MOCK_FLATPAK_FAIL=0
bash "$SYSUP" __execute interactive "$WORK/repo" "$(id -u)" 1 '' 'test-resumed'
! grep -q 'apt-get' "$MOCK_TRACE"
! grep -q '^snap$' "$MOCK_TRACE"
grep -q '^flatpak$' "$MOCK_TRACE"
[[ "$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["status"])' "$HOME/.local/state/kubuntu-config/status.json")" == completed ]]

# Cancellation signal is deferred until the running APT metadata command ends.
: > "$MOCK_TRACE"
: > "$HOME/.local/state/kubuntu-config/completed.txt"
export MOCK_APT_SLEEP=1
bash "$SYSUP" __execute interactive "$WORK/repo" "$(id -u)" 0 '' 'test-cancel' > "$WORK/cancel.out" 2>&1 &
runpid=$!
for _ in {1..100}; do
    if grep -q 'apt-get .*update' "$MOCK_TRACE"; then break; fi
    sleep 0.02
done
kill -USR1 "$runpid"
set +e
wait "$runpid"
rc=$?
set -e
[[ "$rc" == 130 ]] || { echo "cancel exit=$rc"; cat "$WORK/cancel.out"; exit 1; }
grep -q 'apt-get .*update' "$MOCK_TRACE"
! grep -q 'full-upgrade' "$MOCK_TRACE"
! grep -q '^snap$' "$MOCK_TRACE"
[[ "$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["status"])' "$HOME/.local/state/kubuntu-config/status.json")" == cancelled ]]

echo '[PASS] sysup error isolation, checkpoint/resume and deferred cancellation (mocked)'
