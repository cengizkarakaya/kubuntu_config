#!/usr/bin/env python3
"""Private workstation inventory: no installs, sudo or network queries."""

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

from recovery_common import (
    ROOT,
    new_snapshot,
    ordinary_user,
    private_root,
    write_private,
)

STAGES = {
    "apt": ("dpkg-query", "apt_upgrade"),
    "flatpak-user": ("flatpak", "flatpak"),
    "snap": ("snap", "snap"),
    "rustup": ("rustup", "rustup"),
    "helix": ("hx", "helix"),
    "bottom": ("btm", "bottom"),
    "herdr": ("herdr", "herdr"),
    "codex": ("codex", "codex"),
}
COMMANDS = {
    "os": ["cat", "/etc/os-release"],
    "kernel": ["uname", "-r", "-m"],
    "plasma": ["plasmashell", "--version"],
    "apt-manual": ["apt-mark", "showmanual"],
    "dpkg-selections": ["dpkg", "--get-selections"],
    "flatpak-system": ["flatpak", "list", "--system", "--columns=ref:full,version:full,active:full,origin:full"],
    "cargo": ["cargo", "--version"],
    "cargo-installed": ["cargo", "install", "--list"],
    "python": ["python3", "--version"],
    "docker-client": ["docker", "--version"],
    "docker-compose": ["docker", "compose", "version"],
    "nvidia-driver": ["nvidia-smi", "--query-gpu=driver_version", "--format=csv,noheader"],
    "repo-commit": ["git", "-C", str(ROOT), "rev-parse", "HEAD"],
    "repo-dirty": ["git", "-C", str(ROOT), "status", "--porcelain"],
}


def execute(args):
    return subprocess.run(args, capture_output=True,
                          text=True, errors="replace", timeout=45, check=True,
                          env=dict(os.environ, LC_ALL="C")).stdout


def collect():
    result = {}
    conda = shutil.which("conda") or str(Path.home() / ".local/opt/miniforge3/bin/conda")
    commands = dict(COMMANDS, conda=[conda, "env", "list", "--json"])
    for label, (binary, stage) in STAGES.items():
        if not shutil.which(binary):
            result[label] = {"status": "not-installed"}
            continue
        try:
            result[label] = json.loads(execute([sys.executable, str(ROOT / "scripts/sysup-report.py"), "capture", stage]))
        except (OSError, ValueError, subprocess.SubprocessError) as exc:
            result[label] = {"status": "unavailable", "error": str(exc)}
    for label, command in commands.items():
        if not shutil.which(command[0]):
            result[label] = {"status": "not-installed"}
            continue
        try:
            output = execute(command)
            if label in ("apt-manual", "dpkg-selections", "flatpak-system"):
                output = "\n".join(sorted(output.splitlines()))
            result[label] = {"status": "ok", "output": output.strip()}
        except (OSError, subprocess.SubprocessError) as exc:
            result[label] = {"status": "unavailable", "error": str(exc)}
    return result


def compare(old, new):
    for key in sorted(old.keys() | new.keys()):
        a, b = old.get(key, {}), new.get(key, {})
        if a == b:
            continue
        if a.get("status") != "ok" or b.get("status") != "ok":
            print(f"{key}: {a.get('status', 'missing')} -> {b.get('status', 'missing')}; not a verified diff")
            continue
        if "items" in a and "items" in b:
            for name in sorted(a["items"].keys() | b["items"].keys()):
                before, after = a["items"].get(name), b["items"].get(name)
                if before != after:
                    print(f"{key}: {name}: {before} -> {after}")
        else:
            before = set(a.get("output", "").splitlines())
            after = set(b.get("output", "").splitlines())
            for line in sorted(before - after):
                print(f"{key}: - {line}")
            for line in sorted(after - before):
                print(f"{key}: + {line}")


def main():
    p = argparse.ArgumentParser(description=__doc__)
    mode = p.add_mutually_exclusive_group()
    mode.add_argument("--plan", action="store_true")
    mode.add_argument("--capture", action="store_true")
    mode.add_argument("--compare", nargs=2, metavar=("BEFORE_JSON", "AFTER_JSON"))
    args = p.parse_args()
    ordinary_user()
    if args.compare:
        compare(*(json.loads(Path(x).read_text(encoding="utf-8")) for x in args.compare))
    elif args.capture:
        output = new_snapshot("inventory")
        data = collect()
        write_private(output / "inventory.json", json.dumps(data, indent=2, sort_keys=True) + "\n")
        for key, value in sorted(data.items()):
            print(f"{key}: {value['status']}")
        print(f"Private inventory: {output / 'inventory.json'}")
        if any(v["status"] == "unavailable" for v in data.values()):
            return 1
    else:
        print(f"[PLAN] Private destination: {private_root('inventory')}")
        print("[PLAN] Sources: " + ", ".join(sorted(STAGES.keys() | COMMANDS.keys() | {"conda"})))
        print("[PLAN] No files written, no sudo, no updates. Never commit raw inventory.")
    return 0


if __name__ == "__main__":
    os.umask(0o077)
    try:
        sys.exit(main())
    except (OSError, ValueError, TypeError) as exc:
        sys.exit(f"[FAIL] {exc}")
