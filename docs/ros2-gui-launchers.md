# ROS 2 Lyrical GUI tools and KDE Application Launcher

This is an **opt-in** extension for the previously tested Docker ROS 2
environment on Kubuntu 26.10. The user has confirmed:
- ROS 2 Lyrical `dev` Compose service: functional.
- NVIDIA Toolkit 1.19.1, RTX 4080 SUPER and hardware OpenGL 4.6 inside
  Docker: functional.
- RViz2 GUI and TIO robot description visualization: functional.

The `rqt` and PlotJuggler additions are **not verified on the workstation
until the user rebuilds the GUI image**. No native ROS 2, Qt, NVIDIA driver or
external APT source is installed on Kubuntu.

## ROS GUI packages

`robotics/ros2/Dockerfile.rviz` installs these ROS Lyrical packages:
- `ros-lyrical-rqt`, `ros-lyrical-rqt-graph`,
  `ros-lyrical-rqt-console`, `ros-lyrical-rqt-image-view`,
  `ros-lyrical-rqt-topic`.
- `ros-lyrical-plotjuggler-ros`, which depends on the matching ROS
  PlotJuggler application and ROS topic/rosbag plugins.

The ROS-linked PlotJuggler uses the **PlotJuggler 3.x** line. Do not confuse it
with standalone PlotJuggler 4 or install external website binaries. Read
upstream release notes at the original `PlotJuggler/PlotJuggler` GitHub
repository; its maintainers currently warn against a lookalike .com domain.

The viewer still runs as an unprivileged UID/GID-matched container user.
It shares ROS 2 `dev`'s local discovery/IPCs and has NVIDIA/XWayland access
but no Docker socket or host networking. The standard headless `dev` image
is not changed by this GUI-only package set.

## Rebuild and verify

Close RViz2/rqt/PlotJuggler windows before rebuilding:

```bash
cd ~/kubuntu_config
git pull --ff-only
bash scripts/ros2-env.sh rviz-stop
bash scripts/ros2-env.sh rviz-up
bash scripts/ros2-env.sh rviz-check
bash scripts/ros2-env.sh check
```

Note: `rviz-up` explicitly rebuilds/recreates the GUI viewer and may
recreate `dev` due to its shared network and IPC dependencies.
`rviz-check` now verifies `rqt_gui`, `rqt_graph`, `rqt_console`,
`rqt_image_view`, `rqt_topic`, `plotjuggler` and
`plotjuggler_ros` package indexes, along with NVIDIA OpenGL.

If APT in the container reports missing/conflicting packages, preserve
the output; do not force package overwrites or alter host APT packages.

## KDE Application Launcher integration

The user's actual KMenuEdit export already contains a root **Robotics**
group with a **Webots** entry. A safe, opt-in installer preserves that group,
appends exactly eight desktop entries, and backs up the menu before changes.
No KMenuEdit reset or replay of the old menu snapshot is needed.

```bash
cd ~/kubuntu_config
python3 scripts/install-ros2-launchers.py --check
python3 scripts/install-ros2-launchers.py --install
```

**Do not use sudo** with this script. It creates:
- `~/.local/bin/kubuntu-ros2-launcher` (simple Alacritty wrapper).
- `~/.local/share/applications/kubuntu-ros2-*.desktop` (8 launchers).
- Additional `<Filename>` elements inside *existing* Robotics
  `<Include>` and `<Layout>` sections of
  `~/.config/menus/applications-kmenuedit.menu`.

The installer aborts before changing anything if the expected live
Robotics/Webots group is missing or it would overwrite an existing
customized launcher. It refuses symlink targets. When changes are needed,
the original menu is backed up privately under
`~/.local/state/kubuntu-config/ros2-menu-before-<timestamp>/`.
The command `kbuildsycoca6 --noincremental` refreshes the KDE app menu.

Expected Robotics submenu:

```text
Robotics
├── Webots                        (already installed)
├── ROS 2 Development (Terminal)
├── ROS 2 GUI — Start / Refresh
├── RViz2 (ROS 2)
├── rqt (ROS 2)
├── rqt Graph (ROS 2)
├── rqt Console (ROS 2)
├── rqt Image View (ROS 2)
└── PlotJuggler (ROS 2)
```

Each launcher opens an **Alacritty window** so the rootful Docker daemon's
`sudo` password prompt and subsequent application logs are visible. The
launchers do not add the user to the root-equivalent Docker group.
The graphical apps require that GUI container is already running; after
a reboot/desktop re-login, first click **ROS 2 GUI — Start / Refresh**.
The **ROS 2 Development (Terminal)** entry uses the existing `dev`
service; if `dev` is stopped, start it using `bash scripts/ros2-env.sh up`.

## Manual commands (without the app menu)

```bash
bash scripts/ros2-env.sh rviz
bash scripts/ros2-env.sh rqt
bash scripts/ros2-env.sh rqt-graph
bash scripts/ros2-env.sh rqt-console
bash scripts/ros2-env.sh rqt-image
bash scripts/ros2-env.sh plotjuggler
```

Persistent GUI preferences live outside Docker at:

```text
~/Workspaces/Robotics/rviz2-config/   # RViz2
~/Workspaces/Robotics/ros-gui-config/ # Qt/rqt/PlotJuggler preferences
```

Back up those folders separately before formatting.

## Save the updated user menu safely

**Do not automatically push** the entire `.menu` or `.desktop` collection
to this **public** GitHub repository. To update the previously captured
launcher backup after visually confirming the eight entries:

```bash
bash scripts/menu-backup.sh --capture
bash scripts/menu-backup.sh --stage-repo    # interactive PUBLISH confirmation
git diff -- backups/application-launcher/snapshot
git status --short
# Review ALL files for private paths/tokens before git add/commit/push.
```

The installer itself and its predictable desktop definitions are already
tracked, so a complete reinstallation can regenerate them without uploading
the live private KMenuEdit files.

## Quick validation in TIO

Start `bash scripts/ros2-tio.sh run` in one Alacritty terminal.
Open **rqt Graph** from the Robotics menu to inspect publishers/subscribers,
then open **rqt** and locate its Topic Monitor plugin. PlotJuggler's ROS 2
topic subscriber becomes useful when real numeric sensor topic data is
available. The TIO description demo publishes state and TF, not real
IMU/motor telemetry.

The tools are considered fully installed only once the GUI image builds,
`rviz-check` passes, and the apps actually open from the KDE menu.
