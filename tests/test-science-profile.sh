#!/usr/bin/env bash
# Read-only APT science profile test: the plan must never sudo/install/remove packages.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin"
printf '%s\n' '#!/usr/bin/env bash' '[[ "$1" == policy ]] || exit 2' 'echo "  Candidate: 999.0"' > "$tmp/bin/apt-cache"
printf '%s\n' '#!/usr/bin/env bash' \
  '[[ "$1" == -s && "$2" == install ]] || exit 2' \
  '[[ " $* " == *" --no-remove "* ]] || exit 2' \
  '[[ " $* " == *" quantum-espresso-data-sssp "* ]] || exit 2' \
  '[[ " $* " != *" quantum-espresso-data "* ]] || exit 2' \
  'echo "APT MOCK SIMULATION OK"' > "$tmp/bin/apt-get"
printf '%s\n' '#!/usr/bin/env bash' 'echo "SUDO MUST NOT RUN" >&2; exit 88' > "$tmp/bin/sudo"
chmod +x "$tmp/bin/"*
PATH="$tmp/bin:$PATH" bash "$ROOT/scripts/install-science.sh" --plan > "$tmp/output"
grep -q 'APT MOCK SIMULATION OK' "$tmp/output"
grep -q 'Dry run only' "$tmp/output"
echo '[PASS] Science plan simulates without sudo and preserves QE SSSP alternative'
