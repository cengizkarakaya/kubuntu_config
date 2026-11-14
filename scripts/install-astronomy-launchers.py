#!/usr/bin/env python3
"""Opt-in, non-destructive Astronomy launchers for Plasma 6 / KMenuEdit.

Only installed applications receive menu entries. Does not install software.
Always run --check before --install, as the regular desktop user.
"""
from __future__ import annotations

import argparse
from datetime import datetime
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import tempfile

HOME = Path.home()
DATA = Path(os.environ.get("XDG_DATA_HOME", str(HOME / ".local/share")))
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", str(HOME / ".config")))
STATE = Path(os.environ.get("XDG_STATE_HOME", str(HOME / ".local/state"))) / "kubuntu-config"
MENU = CONFIG / "menus/applications-kmenuedit.menu"
APP_DIR = DATA / "applications"
WRAP_DIR = HOME / ".local/bin"
CELESTIA_APPIMAGE = HOME / ".local/opt/celestia/Celestia.AppImage"
OPENSPACE_ROOT = HOME / ".local/opt/openspace"
GAIA_ID = "space.gaiasky.GaiaSky.desktop"
ASTRONOMY = re.compile(r"(?ms)^ <Menu>\n  <Name>Astronomy</Name>\n.*?^ </Menu>")


def atomic_write(path: Path, value: str, permissions: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=".astronomy.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as file:
            file.write(value)
        os.chmod(tmp, permissions)
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)


def gaia_available() -> bool:
    if not shutil.which("flatpak"):
        return False
    result = subprocess.run(["flatpak", "info", "--user", "space.gaiasky.GaiaSky"],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                            check=False)
    if result.returncode:
        return False
    return any((root / GAIA_ID).is_file() for root in (
        DATA / "flatpak/exports/share/applications",
        HOME / ".local/share/flatpak/exports/share/applications",
        Path("/var/lib/flatpak/exports/share/applications"),
    ))


def celestia_executable() -> str | None:
    if CELESTIA_APPIMAGE.is_file() and os.access(CELESTIA_APPIMAGE, os.X_OK):
        return str(CELESTIA_APPIMAGE)
    return shutil.which("celestia")


def openspace_executable() -> Path | None:
    executable = OPENSPACE_ROOT / "bin/OpenSpace"
    if executable.is_file() and os.access(executable, os.X_OK):
        return executable
    return None


def desktop_text(title: str, detail: str, wrapper: Path) -> str:
    return ("[Desktop Entry]\nType=Application\n"
            f"Name={title}\nComment={detail}\n"
            f"Exec={wrapper}\nTryExec={wrapper}\n"
            "Icon=applications-science\nTerminal=false\nCategories=Science;\n"
            "StartupNotify=true\nX-Kubuntu-Astronomy-Managed=true\n")


def patch_menu(old: str, ids: list[str]) -> str:
    found = ASTRONOMY.findall(old)
    if len(found) != 1:
        raise ValueError("Expected one root Astronomy menu in KMenuEdit; no changes.")
    old_group = found[0]
    if "KStars.desktop" not in old_group or "Stellarium.desktop" not in old_group:
        raise ValueError("Astronomy group no longer matches the observed layout.")
    new_group = old_group
    for section in ("Include", "Layout"):
        opening, closing = f"  <{section}>", f"  </{section}>"
        if new_group.count(opening) != 1 or new_group.count(closing) != 1:
            raise ValueError(f"Expected a unique {section} section in Astronomy.")
        pre, tail = new_group.split(closing, 1)
        insert = "".join(f"   <Filename>{item}</Filename>\n"
                         for item in ids if f"<Filename>{item}</Filename>" not in
                         pre.split(opening, 1)[1])
        new_group = pre + insert + closing + tail
    return old.replace(old_group, new_group, 1)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--check", action="store_true")
    group.add_argument("--install", action="store_true")
    args = parser.parse_args()
    if os.geteuid() == 0:
        print("[FAIL] Run as regular user, not sudo.", file=sys.stderr)
        return 2
    if not MENU.is_file() or MENU.is_symlink():
        print(f"[FAIL] Live KMenuEdit menu not found: {MENU}", file=sys.stderr)
        return 2

    targets: list[tuple[Path, str, int]] = []
    ids: list[str] = []
    gaia = gaia_available()
    if gaia:
        ids.append(GAIA_ID)

    celestia = celestia_executable()
    if celestia:
        wrapper = WRAP_DIR / "kubuntu-astronomy-celestia"
        text = "#!/usr/bin/env bash\nset -Eeuo pipefail\n"
        if celestia == str(CELESTIA_APPIMAGE):
            text += 'exec "$HOME/.local/opt/celestia/Celestia.AppImage" "$@"\n'
        else:
            text += f'exec "{celestia}" "$@"\n'
        targets.append((wrapper, text, 0o755))
        ident = "kubuntu-astronomy-celestia.desktop"
        targets.append((APP_DIR / ident,
                        desktop_text("Celestia", "3D universe explorer", wrapper), 0o644))
        ids.append(ident)

    openspace = openspace_executable()
    if openspace:
        wrapper = WRAP_DIR / "kubuntu-astronomy-openspace"
        text = ('#!/usr/bin/env bash\nset -Eeuo pipefail\n'
                'cd "$HOME/.local/opt/openspace"\n'
                'exec ./bin/OpenSpace "$@"\n')
        targets.append((wrapper, text, 0o755))
        ident = "kubuntu-astronomy-openspace.desktop"
        targets.append((APP_DIR / ident,
                        desktop_text("OpenSpace", "Scientific universe visualization", wrapper), 0o644))
        ids.append(ident)

    old = MENU.read_text(encoding="utf-8")
    try:
        new = patch_menu(old, ids)
    except ValueError as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 2

    for path, desired, _mode in targets:
        if path.is_symlink() or (path.exists() and not path.is_file()):
            print(f"[FAIL] Unsafe existing path: {path}", file=sys.stderr)
            return 2
        if path.exists() and path.read_text(encoding="utf-8") != desired:
            print(f"[FAIL] Refusing to overwrite a modified file: {path}", file=sys.stderr)
            return 2

    print(f"Gaia Sky Flatpak: {'ready' if gaia else 'missing / desktop export not found'}")
    print(f"Celestia binary: {celestia or 'missing'}")
    print(f"OpenSpace binary: {openspace or 'missing'}")
    print(f"Astronomy entries: {', '.join(ids) if ids else '(none)'}")
    print(f"KMenuEdit update needed: {new != old}")
    if args.check:
        print("[OK] Read-only check complete.")
        return 0
    if not ids:
        print("[FAIL] None of the three applications is installed.", file=sys.stderr)
        return 1

    if old != new:
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
        backup = STATE / f"astronomy-menu-before-{stamp}" / MENU.name
        backup.parent.mkdir(parents=True, exist_ok=False)
        shutil.copy2(MENU, backup)
        print(f"[BACKUP] {backup}")
    for path, desired, permissions in targets:
        if not path.exists():
            atomic_write(path, desired, permissions)
            print(f"[CREATED] {path}")
    if old != new:
        atomic_write(MENU, new, stat.S_IMODE(MENU.stat().st_mode))
        print("[UPDATED] Existing Astronomy category; Stellarium/KStars preserved.")
    if shutil.which("kbuildsycoca6"):
        result = subprocess.run(["kbuildsycoca6", "--noincremental"], check=False)
        if result.returncode:
            print("[WARN] KDE cache update failed. Retry manually.", file=sys.stderr)
    print("[OK] Astronomy launchers integrated without changing other menu categories.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
