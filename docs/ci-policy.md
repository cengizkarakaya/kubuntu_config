# CI policy architecture

The former inline Python assertion block in `.github/workflows/qa.yml` is preserved in `tests/test-policy-legacy.py` (all 59 assert statements). This is a deliberately independent regression gate. `policy/invariants.toml` adds an inspectable declaration of package and bootstrap invariants checked by `scripts/check-policy.py`; it does not drive production installation. `tests/test-policy.py` exercises deliberate violations using temporary copies of manifests. Existing behavior tests are unchanged. Do not delete old assertions until equivalent independent behavioral coverage has been demonstrated. A change to policy alone must not silently relax the independent safety checks. The legacy text checks remain syntax-sensitive by design during migration.

```bash
python3 -B tests/test-policy-legacy.py
python3 -B scripts/check-policy.py
python3 -B tests/test-policy.py
```

## Python quality gate

All tracked Python source files (including tests and ROS launch files) are compiled by CI. Ruff is installed from a version-pinned official release asset checked against its published SHA-256. The blocking baseline is E9, F63, F7 and F82 (syntax, invalid constructs and undefined names). Default Ruff rules are reported as advisory statistics; tool failures remain blocking. Do not automatically reformat files or broaden the baseline until findings have been reviewed. Existing independent functional tests are retained. The CI tools are not installed by bootstrap or sysup.

## Private-data gate

The independent [privacy policy](privacy-policy.md) checks committed Git objects and runs synthetic positive and negative fixtures. It complements Gitleaks and does not establish that history or all personal information is clean. CI diagnostics omit paths and matching values.

## Bash execution modes

The baseline in `policy/bash-modes.toml` applies to tracked .sh/.bash files and
Bash-shebang commands (including extensionless commands). Entrypoints and tests
must begin with `set -euo pipefail` or `set -Eeuo pipefail`; known exceptions
are individually documented. Collectors deliberately retain `set -uo pipefail`
for explicit status handling; best-effort diagnostics are not acceptance gates.
Sourced helpers must not change the caller's strict options. The interactive
Yazi search retains its existing selection/cancellation semantics. Version
checks retain their existing fail-fast header and explicit mismatch handling.

```bash
python3 -B scripts/check-bash-modes.py
python3 -B tests/test-bash-modes.py
```

This is a static header and simple option-declaration check, not a shell parser
or proof of runtime failure propagation. It does not analyze indirect option
changes, conditional errexit semantics, process substitutions or all nested
shells. Existing independent Bash syntax, ShellCheck and functional tests
remain required. Review any new exception before adding it; never apply strict
mode mechanically to sourced code or a status-collecting controller.
