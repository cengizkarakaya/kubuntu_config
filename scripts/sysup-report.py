#!/usr/bin/env python3
"""Read-only local version snapshots for sysup; no network or package changes."""
import json
import os
import shutil
import subprocess
import sys

STAGES = {'apt_upgrade', 'flatpak', 'snap', 'rustup', 'helix', 'bottom', 'herdr', 'codex'}
BINARIES = {'helix': 'hx', 'bottom': 'btm', 'herdr': 'herdr', 'codex': 'codex'}


def run(*args):
    env = dict(os.environ, LC_ALL='C')
    result = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                            text=True, errors='replace', timeout=30, check=False, env=env)
    if result.returncode:
        raise RuntimeError(f'{args[0]} exited {result.returncode}: {result.stderr.strip()[:160]}')
    return result.stdout


def record(version='', revision=''):
    return {'version': version.strip(), 'revision': revision.strip()}


def inventory(stage):
    items = {}
    if stage == 'apt_upgrade':
        for line in run('dpkg-query', '-W', '-f=${binary:Package}\\t${Version}\\n').splitlines():
            name, sep, version = line.partition('\\t')
            if sep and name:
                items[name] = record(version)
    elif stage == 'flatpak':
        # `active` is the installed commit, so same-version rebuilds count too.
        output = run('flatpak', 'list', '--user', '--columns=ref:full,version:full,active:full')
        for line in output.splitlines():
            columns = line.split('\\t')
            if len(columns) < 3:
                columns = line.split(None, 2)
            if len(columns) >= 3 and columns[0].startswith(('app/', 'runtime/')):
                items[columns[0]] = record(columns[1], columns[2])
    elif stage == 'snap':
        for line in run('snap', 'list').splitlines()[1:]:
            fields = line.split()
            if len(fields) >= 3:
                items[fields[0]] = record(fields[1], fields[2])
    elif stage == 'rustup':
        for line in run('rustup', 'toolchain', 'list').splitlines():
            name = line.split()[0]
            if name == 'no':
                continue
            version = run('rustup', 'run', name, 'rustc', '--version').strip()
            items[name] = record(version)
    else:
        binary = BINARIES[stage]
        path = shutil.which(binary)
        if path:
            version = run(path, '--version').splitlines()[0].strip()
            items[binary] = record(version)
    return items


def capture(stage):
    if stage not in STAGES:
        raise ValueError('unsupported sysup stage')
    try:
        return {'status': 'ok', 'items': inventory(stage)}
    except (OSError, RuntimeError, subprocess.TimeoutExpired, IndexError) as exc:
        return {'status': 'unavailable', 'items': {}, 'error': str(exc)[:240]}


def display(entry, other):
    version = entry.get('version') or 'sürüm belirtilmemiş'
    revision = entry.get('revision') or ''
    if revision and (entry.get('version') == other.get('version')):
        return f'{version} [rev {revision[:12]}]'
    return version


def compare(stage, before_path, after_path):
    try:
        with open(before_path, encoding='utf-8') as handle:
            before = json.load(handle)
        with open(after_path, encoding='utf-8') as handle:
            after = json.load(handle)
        if before.get('status') != 'ok' or after.get('status') != 'ok':
            errors = [snapshot.get('error', '') for snapshot in (before, after)
                      if snapshot.get('status') != 'ok']
            return {'status': 'unavailable', 'changes': [], 'error': '; '.join(errors)[:240]}
        old, new = before['items'], after['items']
        changes = []
        for name in sorted(old.keys() | new.keys()):
            a, b = old.get(name), new.get(name)
            if a == b:
                continue
            kind = 'installed' if a is None else ('removed' if b is None else 'updated')
            changes.append({'name': name, 'kind': kind,
                            'before': display(a, b or {}) if a else '—',
                            'after': display(b, a or {}) if b else '—'})
        return {'status': 'ok', 'changes': changes, 'checked': len(new)}
    except (OSError, ValueError, KeyError, TypeError) as exc:
        return {'status': 'unavailable', 'changes': [], 'error': str(exc)[:240]}


def main(argv):
    if len(argv) == 3 and argv[1] == 'capture':
        output = capture(argv[2])
    elif len(argv) == 5 and argv[1] == 'compare' and argv[2] in STAGES:
        output = compare(argv[2], argv[3], argv[4])
    else:
        raise SystemExit('usage: sysup-report.py capture STAGE | compare STAGE BEFORE AFTER')
    json.dump(output, sys.stdout, ensure_ascii=False, separators=(',', ':'))
    print()


if __name__ == '__main__':
    main(sys.argv)
