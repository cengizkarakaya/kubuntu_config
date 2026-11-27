#!/usr/bin/env python3
"""Explicit Conda environment recovery; no bootstrap or sysup integration."""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

from recovery_common import new_snapshot, ordinary_user, private_root, write_private

PROFILES = {
    "fenicsx": "import dolfinx; from mpi4py import MPI; assert MPI.COMM_WORLD.size >= 1; print(dolfinx.__version__)",
    "sage": "from sage.all import ZZ; assert ZZ(42).factor().value() == 42; print('Sage arithmetic OK')",
}


def name(value):
    if value == "base" or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]*", value):
        raise argparse.ArgumentTypeError("Use a named non-base environment, without path separators")
    return value


def conda():
    binary = shutil.which("conda") or str(Path.home() / ".local/opt/miniforge3/bin/conda")
    if not os.access(binary, os.X_OK):
        raise ValueError("Conda not found; install official Miniforge separately")
    return binary


def run(*args, capture=False):
    result = subprocess.run([conda(), *args], check=True, text=True,
                            stdout=subprocess.PIPE if capture else None)
    return result.stdout


def yaml_without_prefix(text):
    return "\n".join(line for line in text.splitlines() if not line.startswith("prefix:")) + "\n"


def export_env(env):
    history = yaml_without_prefix(run("env", "export", "-n", env, "--from-history", capture=True))
    full = yaml_without_prefix(run("env", "export", "-n", env, capture=True))
    explicit = run("list", "-n", env, "--explicit", capture=True)
    if not history.strip() or not full.strip() or "@EXPLICIT" not in explicit.splitlines():
        raise ValueError("Incomplete Conda exports")
    platform = json.loads(run("info", "--json", capture=True))["platform"]
    output = new_snapshot("conda")
    write_private(output / f"{env}.env.yml", history)
    write_private(output / f"{env}.full.yml", full)
    write_private(output / f"{env}.{platform}.explicit.txt", explicit)
    write_private(output / "README.txt", "PRIVATE. Review all channels, URLs, variables, paths and pip entries before copying any file to Git. Explicit file covers Conda packages only; full YAML may contain pip entries. Rebuild and test separately.\n")
    print(f"Private Conda exports: {output}")


def restore(env, source, kind, apply):
    if not source.is_file():
        raise ValueError("Reviewed manifest does not exist")
    if kind == "explicit":
        content = source.read_text(encoding="utf-8").splitlines()
        if "@EXPLICIT" not in content:
            raise ValueError("Not an explicit Conda package list")
        platforms = [line.split(":", 1)[1].strip() for line in content if line.startswith("# platform:")]
        if len(platforms) != 1:
            raise ValueError("Explicit list must identify its original platform")
        args = ("create", "-n", env, "--file", str(source), "--yes")
    else:
        args = ("env", "create", "-n", env, "--file", str(source), "--yes")
        platforms = []
    if not apply:
        print(f"[PLAN] Create new environment {env} from {source} ({kind})")
        print("[PLAN] No solver, downloads or writes. Review channels, pip packages and local paths first.")
        return
    info = json.loads(run("info", "--json", capture=True))
    existing = json.loads(run("env", "list", "--json", capture=True))["envs"]
    if any(Path(p).name == env for p in existing) or any(
        (Path(p) / env).exists() or (Path(p) / env).is_symlink() for p in info["envs_dirs"]
    ):
        raise ValueError("Environment already exists; refusing overwrite")
    if platforms and platforms[0] != info["platform"]:
        raise ValueError("Explicit list belongs to a different Conda platform")
    run(*args)
    print("Environment created; application smoke test still required.")


def main():
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="action")
    sub.add_parser("plan")
    sub.add_parser("list")
    ex = sub.add_parser("export")
    ex.add_argument("env", type=name)
    re_p = sub.add_parser("restore")
    re_p.add_argument("env", type=name)
    re_p.add_argument("source", type=Path)
    re_p.add_argument("--kind", required=True, choices=("yaml", "explicit"))
    re_p.add_argument("--apply", action="store_true")
    ve = sub.add_parser("verify")
    ve.add_argument("env", type=name)
    ve.add_argument("--profile", choices=PROFILES, required=True)
    args = p.parse_args()
    ordinary_user()
    if args.action in (None, "plan"):
        print(f"[PLAN] Export privately under {private_root('conda')}; no writes.")
        print("[PLAN] Named non-base environments only; explicit restore requires --apply.")
    elif args.action == "list":
        run("env", "list")
    elif args.action == "export":
        # Check private destination before invoking Conda.
        private_root("conda")
        export_env(args.env)
    elif args.action == "restore":
        restore(args.env, args.source.resolve(), args.kind, args.apply)
    elif args.action == "verify":
        run("run", "-n", args.env, "python", "-c", PROFILES[args.profile])
    return 0


if __name__ == "__main__":
    os.umask(0o077)
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as exc:
        sys.exit(f"[FAIL] {exc}")
