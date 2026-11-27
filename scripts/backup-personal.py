#!/usr/bin/env python3
"""Opt-in, encrypted Restic backup. No automatic publication or live restore."""

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

from recovery_common import ROOT, ordinary_user

CANDIDATES = ROOT / "backups/personal-manifest.txt"


def inside(path, parent):
    return path == parent or parent in path.parents


def manifest_paths(manifest, home, require_private=False):
    if require_private and inside(manifest.resolve(), ROOT):
        raise ValueError("Copy and review the candidate manifest privately before backup")
    result = []
    for raw in manifest.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        relative = Path(line)
        if relative.is_absolute() or ".." in relative.parts or not relative.parts or any(c in line for c in "*?[]\x00\r\n"):
            raise ValueError(f"Not an explicit relative HOME path: {line}")
        if relative.parts[0] in (".ssh", ".gnupg", ".secrets") or relative.parts[:2] == (".local", "share") and len(relative.parts) == 2:
            raise ValueError(f"Overbroad or prohibited source: {line}")
        path = home / relative
        resolved = path.resolve()
        if not inside(resolved, home) or inside(resolved, ROOT) or inside(ROOT, resolved):
            raise ValueError(f"Source overlaps public repository or escapes HOME: {line}")
        if resolved != path:
            raise ValueError(f"Symlink source or ancestor: {line}")
        if path not in result:
            result.append(path)
    return result


def repository(value, home):
    if value is None or not value.is_absolute():
        raise ValueError("Specify an absolute local --repo on a separate mounted filesystem")
    target = value.resolve()
    if target != value or inside(target, ROOT) or inside(ROOT, target) or inside(target, home) or inside(home, target):
        raise ValueError("Backup repository must be outside HOME and Git, without symlink components")
    if not target.parent.is_dir():
        raise ValueError("Repository parent must already exist on the mounted backup filesystem")
    if target.exists() and not target.is_dir():
        raise ValueError("Repository destination is not a directory")
    device = (target if target.exists() else target.parent).stat().st_dev
    if device == home.stat().st_dev:
        raise ValueError("Backup destination is on the same filesystem as HOME")
    return target


def main():
    p = argparse.ArgumentParser(description=__doc__)
    mode = p.add_mutually_exclusive_group()
    mode.add_argument("--plan", action="store_true")
    mode.add_argument("--init", action="store_true")
    mode.add_argument("--backup", action="store_true")
    mode.add_argument("--verify", action="store_true")
    mode.add_argument("--list", action="store_true")
    mode.add_argument("--restore", metavar="SNAPSHOT_ID_OR_LATEST")
    p.add_argument("--repo", type=Path)
    p.add_argument("--manifest", type=Path, default=CANDIDATES)
    p.add_argument("--target", type=Path, help="existing empty staging directory for restore")
    args = p.parse_args()
    ordinary_user()
    home = Path.home().resolve()
    plan = not any((args.init, args.backup, args.verify, args.list, args.restore))
    if plan or args.backup:
        sources = manifest_paths(args.manifest, home, require_private=args.backup)
        present = []
        for path in sources:
            exists = path.exists()
            print(f"{'PRESENT' if exists else 'ABSENT'}: {path}")
            if exists:
                present.append(path)
        print(f"Present sources: {len(present)}/{len(sources)}")
    if plan:
        if args.repo is not None:
            print(f"Backup destination: {repository(args.repo, home)}")
        print("[PLAN] No writes, no restic invocation; review paths, close applications and confirm external media.")
        return 0
    target = repository(args.repo, home)
    binary = shutil.which("restic")
    if binary is None:
        raise ValueError("Install the signed Ubuntu restic package separately")
    cmd = [binary, "-r", str(target)]
    if args.init:
        if target.exists() and any(target.iterdir()):
            raise ValueError("Refusing init in a nonempty directory")
        operation = ["init"]
    elif args.backup:
        if not present:
            raise ValueError("No present backup sources")
        operation = ["backup", "--one-file-system", "--", *map(str, present)]
    elif args.verify:
        operation = ["check", "--read-data"]
    elif args.list:
        operation = ["snapshots"]
    else:
        if not re.fullmatch(r"latest|[0-9a-fA-F]{8,64}", args.restore):
            raise ValueError("Use a snapshot ID or latest")
        if args.target is None or not args.target.is_absolute():
            raise ValueError("Restore needs an absolute existing empty --target")
        stage = args.target.resolve()
        if stage != args.target or not stage.is_dir() or any(stage.iterdir()):
            raise ValueError("Restore target must be an existing empty normal directory")
        if any(inside(stage, path) or inside(path, stage) for path in (ROOT, target)) or stage == home or inside(home, stage):
            raise ValueError("Restore target overlaps live HOME, Git or backup repository")
        operation = ["restore", args.restore, "--target", str(stage)]
    # Restic handles passwords itself. Never collect, print or store a password.
    subprocess.run(cmd + operation, check=True)
    return 0


if __name__ == "__main__":
    os.umask(0o077)
    try:
        sys.exit(main())
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        sys.exit(f"[FAIL] {exc}")
