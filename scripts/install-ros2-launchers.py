#!/usr/bin/env python3
"""Safely install user-scoped KDE launchers for Docker-based ROS 2 Lyrical.

Preserves the user's custom KMenuEdit Robotics category and existing entries.
Run with --check (read-only) before --install. Never use sudo on this installer.
"""
from __future__ import annotations

import argparse
import datetime
import os
from pathlib import Path
import re
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent
HOME = Path.home()
APP_DIR = Path(os.environ.get("XDG_DATA_HOME", str(HOME / ".local/share"))) / "applications"
CONFIG_DIR = Path(os.environ.get("XDG_CONFIG_HOME", str(HOME / ".config")))
MENU = CONFIG_DIR / "menus/applications-kmenuedit.menu"
WRAPPER = HOME / ".local/bin/kubuntu-ros2-launcher"
STATE = Path(os.environ.get("XDG_STATE_HOME", str(HOME / ".local/state"))) / "kubuntu-config"
# ID, display name, short description, icon, ROS helper mode
APPLICATIONS = (
    ("ros2-terminal", "ROS 2 Development (Terminal)", "ROS 2 Lyrical Docker terminal", "utilities-terminal", "shell"),
    ("ros2-gui-start", "ROS 2 GUI — Start / Refresh", "Start ROS GUI container and refresh XWayland login", "system-run", "rviz-up"),
    ("ros2-rviz", "RViz2 (ROS 2)", "3D robot visualization on NVIDIA GPU", "applications-graphics", "rviz"),
    ("ros2-rqt", "rqt (ROS 2)", "ROS 2 graphical tools and plugins", "applications-science", "rqt"),
    ("ros2-rqt-graph", "rqt Graph (ROS 2)", "Inspect ROS nodes and topics", "applications-development", "rqt-graph"),
    ("ros2-rqt-console", "rqt Console (ROS 2)", "Inspect and filter ROS log messages", "dialog-information", "rqt-console"),
    ("ros2-rqt-image", "rqt Image View (ROS 2)", "Inspect ROS camera topics", "image-x-generic", "rqt-image"),
    ("ros2-plotjuggler", "PlotJuggler (ROS 2)", "Plot ROS 2 sensor telemetry", "office-chart-line", "plotjuggler"),
)
IDS = tuple("kubuntu-" + row[0] + ".desktop" for row in APPLICATIONS)
ROBOTICS_MENU = re.compile(r"(?ms)^ <Menu>\n  <Name>Robotics</Name>\n.*?^ </Menu>")


def wrapper_text() -> str:
    repo = shlex.quote(str(ROOT))
    return (
        "#!/usr/bin/env bash\n"
        "# Managed by kubuntu_config/scripts/install-ros2-launchers.py\n"
        "set -Eeuo pipefail\n"
        f"ROOT={repo}\n"
        'mode="${1:-}"\n'
        'if ! command -v alacritty >/dev/null; then echo "Alacritty is required." >&2; exit 1; fi\n'
        'case "$mode" in\n'
        '  shell) exec alacritty --title "ROS 2 Development" -e bash "$ROOT/scripts/ros2-env.sh" shell ;;\n'
        '  rviz-up) exec alacritty --hold --title "ROS 2 GUI - Start" -e bash "$ROOT/scripts/ros2-env.sh" rviz-up ;;\n'
        '  rviz|rqt|rqt-graph|rqt-console|rqt-image|plotjuggler)\n'
        '    exec alacritty --hold --title "ROS 2 - $mode" -e bash "$ROOT/scripts/ros2-env.sh" "$mode" ;;\n'
        '  *) echo "Unsupported ROS launcher mode: $mode" >&2; exit 2 ;;\n'
        'esac\n'
    )


def desktop_text(row: tuple[str, str, str, str, str]) -> str:
    ident, title, desc, icon, action = row
    # Freedesktop Exec syntax quotes the executable path; does not use a shell.
    quoted = str(WRAPPER).replace("\\", "\\\\").replace('"', '\\"').replace("$", "\\$")
    return (
        "[Desktop Entry]\n"
        "Type=Application\n"
        f"Name={title}\n"
        f"Comment={desc}\n"
        f"Exec=\"{quoted}\" {action}\n"
        f"TryExec={WRAPPER}\n"
        f"Icon={icon}\n"
        "Terminal=false\n"
        "Categories=Education;Science;\n"
        "StartupNotify=true\n"
        "X-Kubuntu-ROS2-Managed=true\n"
    )


def patched_robotics_menu(contents: str) -> str:
    blocks = ROBOTICS_MENU.findall(contents)
    if len(blocks) != 1 or "webots.desktop" not in blocks[0]:
        raise ValueError(
            "Expected one root Robotics group containing Webots in the live "
            "KMenuEdit menu; no menu changes made. Inspect with kmenuedit."
        )
    original = blocks[0]
    revised = original
    for section in ("Layout", "Include"):
        closing = "  </" + section + ">"
        if revised.count(closing) != 1:
            raise ValueError(f"Robotics menu lacks a unique {section} section")
        to_insert = "".join(
            "   <Filename>" + name + "</Filename>\n"
            for name in IDS
            if "<Filename>" + name + "</Filename>" not in revised.split(closing, 1)[0].split("<" + section + ">", 1)[-1]
        )
        revised = revised.replace(closing, to_insert + closing, 1)
    return contents.replace(original, revised, 1)


def atomic_write(path: Path, content: str, mode: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tempname = tempfile.mkstemp(prefix=".ros2.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as out:
            out.write(content)
        os.chmod(tempname, mode)
        os.replace(tempname, path)
    finally:
        if os.path.exists(tempname):
            os.unlink(tempname)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    actions = parser.add_mutually_exclusive_group(required=True)
    actions.add_argument("--check", action="store_true", help="Read-only plan")
    actions.add_argument("--install", action="store_true", help="Install after safety checks")
    args = parser.parse_args()
    if os.geteuid() == 0:
        print("[FAIL] Run as the desktop user; never use sudo.", file=sys.stderr)
        return 2
    if args.install and not shutil.which("alacritty"):
        print("[FAIL] Alacritty is required for sudo-aware graphical launchers.", file=sys.stderr)
        return 2
    if not MENU.is_file() or MENU.is_symlink():
        print(f"[FAIL] KMenuEdit Robotics menu not found as a normal file: {MENU}", file=sys.stderr)
        return 2
    old_menu = MENU.read_text(encoding="utf-8")
    try:
        new_menu = patched_robotics_menu(old_menu)
    except ValueError as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 2
    targets = [(WRAPPER, wrapper_text(), 0o755)] + [
        (APP_DIR / ident, desktop_text(row), 0o644)
        for row, ident in zip(APPLICATIONS, IDS)
    ]
    for path, desired, _mode in targets:
        if path.is_symlink() or (path.exists() and not path.is_file()):
            print(f"[FAIL] Unsafe existing launcher path: {path}", file=sys.stderr)
            return 2
        if path.exists() and path.read_text(encoding="utf-8") != desired:
            print(f"[FAIL] Existing customized launcher differs; refusing overwrite: {path}",
                  file=sys.stderr)
            return 2
    print(f"Robotics menu: {MENU}")
    print(f"Existing Webots entry preserved; {len(APPLICATIONS)} ROS 2 entries planned.")
    print(f"Menu update needed: {old_menu != new_menu}")
    for path, _content, _mode in targets:
        print(f"  {'existing' if path.exists() else 'create'} {path}")
    if args.check:
        print("[OK] Check only: no files changed.")
        return 0

    # Preserve the original user-managed menu before any changes.
    if old_menu != new_menu:
        stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
        backup_dir = STATE / ("ros2-menu-before-" + stamp)
        backup_dir.mkdir(parents=True, exist_ok=False)
        backup_path = backup_dir / MENU.name
        shutil.copy2(MENU, backup_path)
        print(f"[BACKUP] Original menu: {backup_path}")
    for path, desired, perms in targets:
        if not path.exists():
            atomic_write(path, desired, perms)
            print(f"[CREATED] {path}")
    if new_menu != old_menu:
        perms = stat.S_IMODE(MENU.stat().st_mode)
        atomic_write(MENU, new_menu, perms)
        print("[UPDATED] Existing Robotics group; Webots preserved.")
    if shutil.which("kbuildsycoca6"):
        r = subprocess.run(["kbuildsycoca6", "--noincremental"], check=False)
        if r.returncode:
            print("[WARN] KDE menu cache refresh failed; log out/in or rerun kbuildsycoca6.")
    print("[OK] ROS 2 desktop launchers installed. Use Robotics in Application Launcher.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
