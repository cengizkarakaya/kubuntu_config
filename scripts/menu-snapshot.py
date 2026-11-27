#!/usr/bin/env python3
"""Render reviewed KDE menu snapshots without shell expansion or live capture."""
import argparse
import os
from pathlib import Path
import re
import shutil
import stat
import tempfile

TOKEN = b"@HOME@"
KINDS = {
    (".local", "share", "applications"): ".desktop",
    (".local", "share", "desktop-directories"): ".directory",
    (".config", "menus"): ".menu",
}
FOREIGN_HOME = re.compile(rb"/home/[A-Za-z0-9._-]+")


def home_bytes(home):
    # A bare substitution must be safe in Desktop Entry Exec, Path and XML.
    # Unusual home paths require manual context-specific escaping instead.
    if not re.fullmatch(r"/[A-Za-z0-9._/-]+", str(home)) or ".." in home.parts:
        raise ValueError("Unsupported HOME path for portable launcher templates")
    return os.fsencode(home)


def files(root):
    if root.is_symlink() or not root.is_dir():
        raise ValueError("Snapshot root is not a normal directory")
    for path in sorted(root.rglob("*")):
        if path.is_symlink():
            raise ValueError(f"Symlink in snapshot: {path.relative_to(root)}")
        if path.is_dir():
            continue
        relative = path.relative_to(root)
        if not path.is_file() or not any(
            relative.parts[:len(prefix)] == prefix and path.suffix == suffix
            for prefix, suffix in KINDS.items()
        ):
            raise ValueError(f"Unexpected snapshot file: {relative}")
        yield path, relative


def template(root, home):
    prefix = home_bytes(home)
    # Match the home directory itself or a path beneath it, not a username
    # sharing a prefix. Do not interpret text as shell commands.
    pattern = re.compile(re.escape(prefix) + rb"(?=$|[/\s\"'<>;])")
    pending = []
    for source, relative in files(root):
        raw = source.read_bytes()
        if TOKEN in raw:
            raise ValueError(f"Reserved template marker in raw capture: {relative}")
        rendered = pattern.sub(TOKEN, raw)
        if FOREIGN_HOME.search(rendered):
            raise ValueError(f"Unreviewed absolute home path: {relative}")
        pending.append((source, raw, rendered))
    for source, raw, rendered in pending:
        if rendered != raw:
            source.write_bytes(rendered)


def safe_target(home, relative):
    dest = home / relative
    for candidate in (home, *dest.parents):
        if candidate == home or home in candidate.parents:
            if candidate.is_symlink() or (candidate.exists() and not candidate.is_dir()):
                raise ValueError(f"Unsafe destination parent: {candidate}")
    if dest.is_symlink() or (dest.exists() and not dest.is_file()):
        raise ValueError(f"Unsafe destination: {relative}")
    return dest


def restore(root, home, backup=None):
    prefix = home_bytes(home)
    pending = []
    # Preflight every file before writing anything.
    for source, relative in files(root):
        raw = source.read_bytes()
        if FOREIGN_HOME.search(raw):
            raise ValueError(f"Unreviewed absolute home path in snapshot: {relative}")
        rendered = raw.replace(TOKEN, prefix)
        dest = safe_target(home, relative)
        if dest.exists() and dest.read_bytes() == rendered:
            continue
        pending.append((source, relative, dest, raw, rendered))
    for source, relative, dest, raw, rendered in pending:
        if backup is None:
            kind = "replace with backup" if dest.exists() else "new"
            print(f"[PLAN] {relative} ({kind})")
            if TOKEN in raw:
                print(f"       @HOME@ -> {home}")
            continue
        if dest.exists():
            saved = backup / relative
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(dest, saved)
        dest.parent.mkdir(parents=True, exist_ok=True)
        fd, name = tempfile.mkstemp(prefix=".menu-restore-", dir=dest.parent)
        temp = Path(name)
        try:
            with os.fdopen(fd, "wb") as stream:
                stream.write(rendered)
            os.chmod(temp, stat.S_IMODE(source.stat().st_mode) & 0o777)
            os.replace(temp, dest)
        finally:
            temp.unlink(missing_ok=True)
        print(f"[RESTORED] {relative}")
    print(f"Changed/needed: {len(pending)}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("template", "plan", "restore"))
    parser.add_argument("root", type=Path)
    parser.add_argument("home", type=Path)
    parser.add_argument("--backup", type=Path)
    args = parser.parse_args()
    try:
        if args.mode == "template":
            template(args.root, args.home)
        elif args.mode == "plan":
            restore(args.root, args.home)
        else:
            if args.backup is None:
                parser.error("restore requires --backup")
            restore(args.root, args.home, args.backup)
    except (OSError, ValueError) as error:
        parser.exit(1, f"[FAIL] {error}\n")


if __name__ == "__main__":
    main()
