#!/usr/bin/env python3
"""Check declared repository policy; no installs or host access."""
import argparse
from pathlib import Path
import sys
import tomllib


def manifest(path, flatpak=False):
    result = set()
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.split("#", 1)[0].strip()
        if line:
            result.add(line.split("\t", 1)[0].strip() if flatpak else line)
    return result


def violations(root):
    with (root / "policy/invariants.toml").open("rb") as stream:
        policy = tomllib.load(stream)
    problems = []
    for section, path in (("apt", "packages/apt.txt"), ("flatpak", "packages/flatpak.tsv")):
        actual = manifest(root / path, section == "flatpak")
        required = set(policy[section]["required"])
        forbidden = set(policy[section]["forbidden"])
        problems += [f"{section}: missing required {x}" for x in sorted(required - actual)]
        problems += [f"{section}: forbidden {x}" for x in sorted(actual & forbidden)]
    bootstrap = (root / "bootstrap.sh").read_text(encoding="utf-8")
    problems += [f"bootstrap: forbidden {x}" for x in policy["bootstrap"]["forbidden"] if x in bootstrap]
    return problems


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    errors = violations(args.root)
    for error in errors:
        print(f"[FAIL] {error}", file=sys.stderr)
    if not errors:
        print("[PASS] Declarative repository policy")
    return bool(errors)


if __name__ == "__main__":
    sys.exit(main())
