#!/usr/bin/env python3
"""Enforce the reviewed Bash entrypoint/header baseline without executing scripts."""
import argparse
from pathlib import Path
import re
import subprocess
import sys
import tomllib

BASH = re.compile(r"^#!\s*(?:/usr/bin/env(?:\s+-S)?\s+bash|/bin/bash|/usr/bin/bash)(?:\s|$)")
STRICT = {"set -euo pipefail", "set -Eeuo pipefail"}
# This deliberately recognizes straightforward declarations, not full shell grammar.
OPTION_CHANGE = re.compile(
    r"^\s*(?:builtin\s+)?set\s+(?:[-+][A-Za-z]*[eEu][A-Za-z]*|[-+]o\s+(?:errexit|nounset|pipefail|errtrace)\b)"
)
DISABLE = re.compile(r"^\s*(?:builtin\s+)?set\s+\+(?:[A-Za-z]*[eEu][A-Za-z]*|o\s+(?:errexit|nounset|pipefail|errtrace)\b)")


def check_header(source, mode):
    lines = source.splitlines()
    commands = [line.strip() for line in lines
                if line.strip() and not line.lstrip().startswith("#")]
    first = commands[0] if commands else ""
    if mode == "sourced":
        if any(OPTION_CHANGE.match(line) or re.match(r"^\s*set\s+[-+]o\s+pipefail\b", line)
               for line in lines):
            return "sourced-option-change"
        return None
    if mode == "failfast":
        if first not in STRICT:
            return "missing-failfast-header"
        if any(DISABLE.match(line) for line in lines):
            return "strict-option-disabled"
    elif mode == "collect":
        if first != "set -uo pipefail":
            return "invalid-collector-header"
    elif mode == "interactive":
        if first != "set -u":
            return "invalid-interactive-header"
    else:
        return "unknown-mode"
    return None


def violations(root):
    with (root / "policy/bash-modes.toml").open("rb") as stream:
        exceptions = tomllib.load(stream)["exceptions"]
    paths = subprocess.check_output(["git", "-C", str(root), "ls-files", "-z"])
    errors = []
    seen = set()
    count = 0
    for name in paths.decode("utf-8").split("\0"):
        if not name:
            continue
        path = root / name
        if not path.is_file() or path.is_symlink():
            continue
        with path.open("rb") as stream:
            first = stream.readline(1024).decode("utf-8", errors="replace")
        if not (name.endswith((".sh", ".bash")) or BASH.match(first) or name in exceptions):
            continue
        count += 1
        mode = exceptions.get(name, {}).get("mode", "failfast")
        if name in exceptions:
            seen.add(name)
            if not exceptions[name].get("reason"):
                errors.append(f"{name}: missing exception reason")
        source = path.read_text(encoding="utf-8")
        if mode != "sourced" and not BASH.match(first):
            errors.append(f"{name}: missing Bash shebang")
        issue = check_header(source, mode)
        if issue:
            errors.append(f"{name}: {issue}")
    errors.extend(f"{name}: stale exception" for name in sorted(set(exceptions) - seen))
    if not count:
        errors.append("No Bash scripts found")
    return count, errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    try:
        count, errors = violations(args.root)
    except (OSError, ValueError, KeyError, subprocess.SubprocessError):
        print("[FAIL] Could not inspect Bash policy", file=sys.stderr)
        return 2
    for error in errors:
        print(f"[FAIL] {error}", file=sys.stderr)
    if not errors:
        print(f"[PASS] Bash mode baseline: {count} files")
    return int(bool(errors))


if __name__ == "__main__":
    sys.exit(main())
