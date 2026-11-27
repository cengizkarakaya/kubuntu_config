#!/usr/bin/env python3
"""Explicit installation and execution of local, non-overwriting privacy hooks."""
import argparse
import importlib.util
import os
from pathlib import Path
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
FILES = ("pre-commit", "pre-push", "privacy-guard-run.py", "privacy-guard-check.py")
OID = re.compile(r"[0-9a-f]{40}(?:[0-9a-f]{24})?")


def git(*args):
    proc = subprocess.run(["git", *args], stdout=subprocess.PIPE,
                          stderr=subprocess.DEVNULL, check=False)
    if proc.returncode:
        raise ValueError("Git inspection failed")
    return proc.stdout.strip()


def repository():
    return Path(os.fsdecode(git("rev-parse", "--show-toplevel"))).resolve()


def checker():
    path = HERE / ("privacy-guard-check.py" if __file__.endswith("privacy-guard-run.py")
                   else "check-privacy.py")
    spec = importlib.util.spec_from_file_location("privacy_guard_check", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def hook_dir():
    proc = subprocess.run(["git", "config", "--get", "core.hooksPath"],
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
    if proc.returncode != 1:
        raise ValueError("Custom hooksPath or config error; do not overwrite it")
    hooks = Path(os.fsdecode(git("rev-parse", "--git-path", "hooks"))).absolute()
    if hooks.is_symlink():
        raise ValueError("Symlink hook directory")
    return hooks


def wrapper(mode):
    return ('#!/bin/sh\n# kubuntu-config privacy guard\n'
            'exec python3 -B "$(dirname -- "$0")/privacy-guard-run.py" '
            + mode + ' "$@"\n').encode()


def install(hooks):
    if any((hooks / name).exists() or (hooks / name).is_symlink() for name in FILES):
        raise ValueError("Existing hook or guard file; refusing to overwrite")
    data = {
        "pre-commit": wrapper("pre-commit"),
        "pre-push": wrapper("pre-push"),
        "privacy-guard-run.py": Path(__file__).read_bytes(),
        "privacy-guard-check.py": (HERE / "check-privacy.py").read_bytes(),
    }
    hooks.mkdir(parents=True, exist_ok=True)
    created = []
    try:
        for name in ("privacy-guard-run.py", "privacy-guard-check.py", "pre-commit", "pre-push"):
            path = hooks / name
            fd = os.open(path, os.O_CREAT | os.O_EXCL | os.O_WRONLY | os.O_NOFOLLOW, 0o700)
            created.append(path)
            with os.fdopen(fd, "wb") as stream:
                stream.write(data[name])
    except OSError:
        for path in created:
            path.unlink()
        raise
    print("[PASS] Local hooks installed; existing hooks were not overwritten.")


def local_terms(check, root):
    state = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")
    path = state / "kubuntu-config/privacy-guard/denylist.txt"
    if path.exists() or path.is_symlink():
        return check.load_denylist(root, path)
    return ()


def report(findings):
    if findings:
        print("[FAIL] Privacy guard: blocked private or unsupported content.", file=sys.stderr)
        return 1
    return 0


def pre_push(check, root, terms, lines):
    commits = set()
    for line in lines:
        local_ref, local, remote_ref, remote = line.split()
        if not OID.fullmatch(local) or not OID.fullmatch(remote):
            raise ValueError("Invalid push object ID")
        if not remote_ref.startswith(("refs/heads/", "refs/tags/")):
            raise ValueError("Unsupported pushed ref")
        if check.deny_match(remote_ref.encode(), terms) or check.deny_match(local_ref.encode(), terms):
            return report(True)
        if not local.strip("0"):
            continue  # Deleting a ref transfers no new object.
        # Resolve tags to commits, also inspect annotated tag messages.
        obj_type = git("cat-file", "-t", local)
        if obj_type == b"tag":
            raw = git("cat-file", "tag", local)
            if b"\ntype commit\n" not in raw.split(b"\n\n", 1)[0] + b"\n":
                raise ValueError("Nested or noncommit tag requires manual review")
            if check.deny_match(raw, terms):
                return report(True)
        tip = git("rev-parse", "--verify", local + "^{commit}").decode("ascii")
        args = ["rev-list", tip]
        if remote.strip("0"):
            # Missing remote history is an error, not a silent exclusion.
            old = git("rev-parse", "--verify", remote + "^{commit}").decode("ascii")
            args.extend(["--not", old])
        commits.update(git(*args).decode("ascii").splitlines())
        commits.add(tip)
    cache = {}
    for commit in sorted(commits):
        if check.deny_match(git("cat-file", "commit", commit), terms):
            return report(True)
        count, findings = check.scan(root, commit, terms, cache)
        if not count or findings:
            return report(True)
    print(f"[PASS] Privacy guard: {len(commits)} outgoing commit tree(s) checked.")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("--install", "--status", "pre-commit", "pre-push"),
                        nargs="?")
    # Explicit flags are parsed separately from Git hook arguments.
    if len(sys.argv) >= 2 and sys.argv[1] in ("--install", "--status"):
        action = sys.argv[1]
        if len(sys.argv) != 2:
            return 2
    elif len(sys.argv) >= 2 and sys.argv[1] in ("pre-commit", "pre-push"):
        action = sys.argv[1]
    else:
        parser.print_help()
        return 2
    try:
        root = repository()
        if action == "--install":
            if os.geteuid() == 0:
                raise ValueError("Run as ordinary user")
            install(hook_dir())
            return 0
        if action == "--status":
            hooks = hook_dir()
            present = all((hooks / name).is_file() and not (hooks / name).is_symlink()
                          for name in FILES)
            if present:
                present = all((hooks / mode).read_bytes() == wrapper(mode)
                              for mode in ("pre-commit", "pre-push"))
                present = present and (hooks / "privacy-guard-run.py").read_bytes() == Path(__file__).read_bytes()
                present = present and (hooks / "privacy-guard-check.py").read_bytes() == (HERE / "check-privacy.py").read_bytes()
                present = present and all(os.access(hooks / mode, os.X_OK) for mode in FILES[:2])
            print("[PASS] Local hooks match current code." if present else "[WARN] Local hooks absent or differ.")
            return 0 if present else 1
        check = checker()
        terms = local_terms(check, root)
        if action == "pre-commit":
            count, findings = check.scan(root, terms=terms)
            if count and not findings:
                print(f"[PASS] Privacy guard: {count} staged entries.")
                return 0
            return report(True)
        return pre_push(check, root, terms, sys.stdin)
    except (OSError, ValueError, subprocess.SubprocessError, ImportError):
        print("[FAIL] Privacy guard could not safely complete; review local configuration.", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
