"""Private local recovery artifacts. Never publish raw captures."""

import datetime
import os
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def private_root(kind):
    state = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")
    path = (state / "kubuntu-config" / kind).resolve()
    if path == ROOT or ROOT in path.parents:
        raise ValueError("Private state must be outside the Git repository")
    return path


def new_snapshot(kind):
    root = private_root(kind)
    root.mkdir(parents=True, mode=0o700, exist_ok=True)
    if root.stat().st_uid != os.getuid() or root.stat().st_mode & 0o077:
        raise ValueError(f"Private state directory must be owned by you and mode 0700: {root}")
    stamp = datetime.datetime.now(datetime.UTC).strftime("%Y%m%dT%H%M%SZ")
    return Path(tempfile.mkdtemp(prefix=stamp + "-", dir=root))


def write_private(path, content):
    with path.open("x", encoding="utf-8") as handle:
        handle.write(content)


def ordinary_user():
    if os.geteuid() == 0:
        raise ValueError("Run as the ordinary desktop user, not root")
