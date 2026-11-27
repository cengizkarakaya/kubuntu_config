#!/usr/bin/env python3
"""Offline checker for common local Markdown links and heading anchors."""
import argparse
from collections import Counter
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import unquote, urlsplit

INLINE = re.compile(r"!?\[[^\]\n]*\]\(\s*(<[^>\n]+>|[^\s)]+)(?:\s+[^)\n]*)?\)")
REFERENCE = re.compile(r"^\s{0,3}\[[^\]\n]+\]:\s*(<[^>\n]+>|[^\s]+)")
HEADING = re.compile(r"^\s{0,3}#{1,6}\s+(.+?)\s*#*\s*$")
ANCHOR = re.compile(r"""<a\s+(?:name|id)=["']([^"']+)["']""", re.I)
FENCE = re.compile(r"^\s{0,3}(\x60{3,}|~{3,})")
CODE = re.compile(r"(\x60+).*?\1")


def visible_lines(text):
    fence = None
    for number, line in enumerate(text.splitlines(), 1):
        match = FENCE.match(line)
        if match:
            token = match.group(1)
            if fence is None:
                fence = token
            elif token[0] == fence[0] and len(token) >= len(fence) and not line[match.end():].strip():
                fence = None
            continue
        if fence is None:
            yield number, line


def anchors(text):
    result = set()
    counts = Counter()
    for _, line in visible_lines(text):
        result.update(ANCHOR.findall(line))
        match = HEADING.match(line)
        if match:
            title = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", match.group(1))
            title = re.sub(r"<[^>]*>", "", title).lower()
            slug = "".join(c for c in title if c.isalnum() or c in "-_ ")
            slug = slug.replace(" ", "-")
            count = counts[slug]
            candidate = f"{slug}-{count}" if count else slug
            while candidate in result:
                count += 1
                candidate = f"{slug}-{count}"
            counts[slug] = count + 1
            result.add(candidate)
    return result


def destinations(text):
    for number, line in visible_lines(text):
        # Do not treat example Markdown syntax inside inline code as a link.
        line = CODE.sub("CODE", line)
        for match in INLINE.finditer(line):
            yield number, match.group(1).strip("<>")
        match = REFERENCE.match(line)
        if match:
            yield number, match.group(1).strip("<>")


def check(root, paths):
    root = root.resolve()
    errors = []
    for path in paths:
        doc = root / path
        text = doc.read_text(encoding="utf-8")
        for number, link in destinations(text):
            url = urlsplit(link)
            if url.scheme or url.netloc:
                continue
            target = ((root if url.path.startswith("/") else doc.parent) /
                      unquote(url.path).lstrip("/")).resolve() if url.path else doc.resolve()
            if not target.is_relative_to(root):
                problem = "escapes repository"
            elif not target.exists():
                problem = "missing local target"
            elif url.fragment and target.suffix.lower() == ".md" and target.is_file():
                if unquote(url.fragment) in anchors(target.read_text(encoding="utf-8")):
                    continue
                problem = "missing Markdown heading anchor"
            else:
                continue
            errors.append(f"{path}:{number}: {link}: {problem}")
    return errors


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = p.parse_args()
    raw = subprocess.check_output(["git", "-C", str(args.root), "ls-files", "-z", "--", "*.md"])
    paths = [Path(x.decode()) for x in raw.split(b"\0") if x]
    if not paths:
        sys.exit("[FAIL] No tracked Markdown files")
    errors = check(args.root, paths)
    for error in errors:
        print(f"[FAIL] {error}", file=sys.stderr)
    if not errors:
        print(f"[PASS] Local links and heading anchors in {len(paths)} tracked Markdown files")
    return bool(errors)


if __name__ == "__main__":
    sys.exit(main())
