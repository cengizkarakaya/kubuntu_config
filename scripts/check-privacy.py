#!/usr/bin/env python3
"""Check Git index or a committed tree for common private recovery artifacts."""
import argparse
from collections import Counter
import fnmatch
import json
import os
from pathlib import Path
import re
import subprocess
import stat
import sys

MAX_BYTES = 2 * 1024 * 1024
# No actual owner identifiers belong in public rules.
FORBIDDEN = (
    "backups/application-launcher/snapshot/*",
    "conda/environments/*.full.yml",
    "conda/locks/*",
    "hosts/home-desktop.md",
    "hosts/private/*",
    "docs/host-acceptance-*.md",
    "builds/private/*",
    "inventory/*",
    "backups/private/*",
    "*/menu-current/*",
    "*/menu-portable/*",
    "*/privacy-migration.*/*",
    "*.bundle",
    "*.tar.gz",
    "*.zip",
    "*.log",
    "*.bak",
)
EXCEPTIONS = {"inventory/readme.md", "conda/locks/readme.md"}
PRIVATE_COMPONENTS = {".ssh", ".gnupg", ".secrets", "menu-current", "menu-portable"}
HOME_PATH = re.compile(rb"(?<![A-Za-z0-9_./$}\-])/home/([A-Za-z0-9_.-]+)")
MAC = re.compile(rb"(?<![0-9A-Fa-f:])(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}(?![0-9A-Fa-f:])")
CONTAINER_PATHS = {
    "robotics/ros2/compose.yaml",
    "robotics/ros2/compose.rviz.yaml",
    "robotics/ros2/Dockerfile",
    "robotics/ros2/Dockerfile.rviz",
    "robotics/ros2/README.md",
    "scripts/ros2-env.sh",
    "tests/test-ros2-rviz.sh",
}


def git(root, *args):
    env = dict(os.environ, GIT_NO_LAZY_FETCH="1")
    # Git errors may include private filenames; keep public diagnostics generic.
    proc = subprocess.run(["git", "-C", str(root), *args], env=env,
                          stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False)
    if proc.returncode:
        raise ValueError("Git object inspection failed")
    return proc.stdout


def entries(root, tree):
    if tree is None:
        raw = git(root, "ls-files", "--stage", "-z")
    else:
        oid = git(root, "rev-parse", "--verify", "--end-of-options", tree + "^{tree}").strip().decode("ascii")
        raw = git(root, "ls-tree", "-r", "-z", oid)
    for item in raw.split(b"\0"):
        if not item:
            continue
        header, path = item.split(b"\t", 1)
        mode, second, third = header.decode("ascii").split()
        if tree is None:
            if third != "0":
                raise ValueError("Unmerged index; resolve conflicts before scanning")
            oid = second
        else:
            oid = third
        yield mode, oid, os.fsdecode(path)


def private_path(path):
    path = path.casefold()
    parts = path.split("/")
    if path in EXCEPTIONS:
        return False
    if any(part in PRIVATE_COMPONENTS or part.startswith("privacy-migration.") for part in parts):
        return True
    if any(part == ".env" or part.startswith(".env.") and part not in
           {".env.example", ".env.sample", ".env.template"} for part in parts):
        return True
    return any(fnmatch.fnmatchcase(path, pattern) for pattern in FORBIDDEN)


def content_findings(path, data):
    result = set()
    for match in HOME_PATH.finditer(data):
        if not (path in CONTAINER_PATHS and match.group(1) == b"rosdev"):
            result.add("absolute-home")
    if MAC.search(data):
        result.add("mac-address")
    return result


def load_denylist(root, path):
    """Read private literal values, never logging their contents."""
    if path is None:
        return ()
    path = Path(path)
    resolved = path.resolve()
    root = root.resolve()
    if (resolved == root or root in resolved.parents or
            any((p / ".git").exists() for p in resolved.parents)):
        raise ValueError("Denylist must be outside Git")
    parent = path.parent.stat()
    if parent.st_uid != os.getuid() or stat.S_IMODE(parent.st_mode) & 0o077:
        raise ValueError("Denylist parent must be private")
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(fd, "rb") as stream:
        info = os.fstat(stream.fileno())
        if (not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid() or
                stat.S_IMODE(info.st_mode) != 0o600 or info.st_size > 65536):
            raise ValueError("Denylist must be an owned regular mode-0600 file")
        data = stream.read(65537)
    if len(data) > 65536 or b"\0" in data:
        raise ValueError("Invalid denylist")
    data.decode("utf-8")
    terms = tuple(line.strip() for line in data.splitlines()
                  if line.strip() and not line.lstrip().startswith(b"#"))
    if len(terms) > 256 or any(len(term) < 4 for term in terms):
        raise ValueError("Denylist requires 4+ byte literals, at most 256")
    return terms


def deny_match(data, terms):
    return any(term in data for term in terms)


def scan(root, tree=None, terms=(), cache=None):
    findings = []
    count = 0
    if cache is None:
        cache = {}
    for mode, oid, path in entries(root, tree):
        count += 1
        if deny_match(os.fsencode(path), terms):
            findings.append(("private-literal", path))
        if private_path(path):
            findings.append(("private-path", path))
            continue
        if mode not in {"100644", "100755"}:
            findings.append(("nonregular-entry", path))
            continue
        key = (path, oid)
        if key in cache:
            findings.extend((rule, path) for rule in cache[key])
            continue
        size = int(git(root, "cat-file", "-s", oid))
        if size > MAX_BYTES:
            findings.append(("oversize-blob", path))
            continue
        data = git(root, "cat-file", "blob", oid)
        try:
            data.decode("utf-8")
        except UnicodeDecodeError:
            findings.append(("nontext-blob", path))
            continue
        if b"\0" in data:
            findings.append(("nontext-blob", path))
            continue
        rules = content_findings(path, data)
        if deny_match(data, terms):
            rules.add("private-literal")
        cache[key] = sorted(rules)
        findings.extend((rule, path) for rule in cache[key])
    return count, findings


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--index", action="store_true", help="scan staged Git objects (default)")
    modes.add_argument("--tree", help="scan a specific committed tree, e.g. HEAD")
    parser.add_argument("--local-details", action="store_true",
                        help="LOCAL ONLY: show escaped offending paths, never matching content")
    parser.add_argument("--denylist", type=Path, help="LOCAL ONLY: private literal list")
    args = parser.parse_args()
    try:
        terms = load_denylist(args.root, args.denylist)
        count, findings = scan(args.root, args.tree, terms)
    except (OSError, ValueError, subprocess.SubprocessError):
        print("[FAIL] Privacy scan could not inspect Git objects.", file=sys.stderr)
        return 2
    for rule, total in sorted(Counter(rule for rule, _ in findings).items()):
        print(f"[FAIL] {rule}: {total} file(s)", file=sys.stderr)
    if args.local_details:
        for rule, path in findings:
            print(json.dumps({"rule": rule, "path": path}, ensure_ascii=True), file=sys.stderr)
    if findings:
        print("[FAIL] Privacy policy; review locally before publication.", file=sys.stderr)
        return 1
    if not count:
        print("[FAIL] Empty tree or index.", file=sys.stderr)
        return 2
    print(f"[PASS] Privacy policy: {count} Git entries")
    return 0


if __name__ == "__main__":
    sys.exit(main())
