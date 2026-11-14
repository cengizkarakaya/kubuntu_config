#!/usr/bin/env python3
"""Apply the exact GDAL 3.13 const-correctness fix to OpenSpace v0.22.1.

The fix is constrained to one Git-tracked source file. It never runs git reset
or git clean. It tolerates the exact same patch on subsequent Ninja resumes,
but rejects any other changes to the checked-out source.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import sys

RELATIVE = "modules/globebrowsing/globebrowsingmodule.cpp"

OLD_PARAMETER = "parseSubDatasets(char** subDatasets,"
NEW_PARAMETER = "parseSubDatasets(const char* const* subDatasets,"
OLD_METADATA = 'char** subDatasets = GDALGetMetadata(dataset, "SUBDATASETS");'
NEW_METADATA = 'const char* const* subDatasets = GDALGetMetadata(dataset, "SUBDATASETS");'


def git(root: Path, *args: str, capture: bool = False) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["git", "-C", str(root), *args],
        check=False,
        capture_output=capture,
        text=True,
    )


def expected_change(upstream: str) -> str:
    if upstream.count(OLD_PARAMETER) != 1 or upstream.count(OLD_METADATA) != 1:
        raise ValueError(
            "Upstream OpenSpace v0.22.1 GDAL declarations changed; refusing patch"
        )
    if NEW_PARAMETER in upstream or NEW_METADATA in upstream:
        raise ValueError("The upstream source is already patched; review first")
    return upstream.replace(OLD_PARAMETER, NEW_PARAMETER, 1).replace(
        OLD_METADATA, NEW_METADATA, 1
    )


def patch(root: Path) -> str:
    target = root / RELATIVE
    if root.is_symlink() or target.is_symlink() or not target.is_file():
        raise ValueError("Missing or unsafe OpenSpace source file")
    baseline = git(root, "show", f"HEAD:{RELATIVE}", capture=True)
    if baseline.returncode:
        raise ValueError("Cannot retrieve OpenSpace upstream source from Git")
    if git(root, "diff", "--cached", "--quiet").returncode:
        raise ValueError("Staged changes detected; refusing source patch")
    other = git(
        root, "diff", "--quiet", "--", ".", f":(exclude){RELATIVE}"
    )
    if other.returncode:
        raise ValueError("Other tracked source changes found; refusing patch")
    original = baseline.stdout
    expected = expected_change(original)
    current = target.read_text(encoding="utf-8")
    if current == expected:
        return "[OK] OpenSpace GDAL patch already applied; resuming existing build."
    if current != original:
        raise ValueError(
            "OpenSpace source has unexpected modifications; refusing to overwrite."
        )
    target.write_text(expected, encoding="utf-8")
    return (
        "[PATCH] GDAL 3.13 const-correctness: metadata and parser signatures "
        "now use const char* const*."
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="OpenSpace Git working tree")
    args = parser.parse_args()
    try:
        print(patch(args.source.expanduser().resolve()))
    except ValueError as error:
        print(f"[FAIL] {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
