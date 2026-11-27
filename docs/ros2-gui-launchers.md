# ROS 2 Lyrical GUI tools and KDE Application Launcher

This is an **opt-in** extension for the Docker ROS 2 environment. Validate the
CLI service, NVIDIA container access, hardware OpenGL, RViz2 and the robot
description on the target workstation. Rebuild the GUI image before testing
rqt and PlotJuggler. No native ROS 2, Qt, NVIDIA driver or external APT source
is installed on Kubuntu.

## ROS GUI packages

`robotics/ros2/Dockerfile.rviz` installs these ROS Lyrical packages:
- `ros-lyrical-rqt`, `ros-lyrical-rqt-graph`,
  `ros-lyrical-rqt-console`, `ros-lyrical-rqt-image-view`,
  `ros-lyrical-rqt-topic`.
- `ros-lyrical-rqt-plot`: supported live numeric ROS topic plotting.
- `ros-lyrical-plotjuggler` (PlotJuggler 3.17.2): CSV and generic
  data visualization. The Lyrical `plotjuggler_ros` binary package is not
  available; **ROS topic subscriber / rosbag plugins are NOT installed**.

The ROS-distributed PlotJuggler here uses the **PlotJuggler 3.x** line.
ROS streaming requires the missing `plotjuggler_ros` plugin, so the
initial installation is **not** a ROS-integrated PlotJuggler. For live
ROS telemetry use `rqt` → Plugins → Visualization → Plot (rqt_plot).
A separately reviewed source build or PlotJuggler 4 integration can be
added later. Do not confuse this with PlotJuggler 4 or install unknown
third-party packages. Read
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
`rqt_image_view`, `rqt_topic`, `rqt_plot` and
`plotjuggler` package indexes, along with NVIDIA OpenGL.
It prints a non-fatal warning if `plotjuggler_ros` remains unavailable.

If APT in the container reports missing/conflicting packages, preserve
the output; do not force package overwrites or alter host APT packages.

## KDE Application Launcher integration

The installer requires a root **Robotics** group containing a **Webots** entry. A safe, opt-in installer preserves that group,
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
├── Webots                        (prerequisite)
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
then open **rqt** and locate its Topic Monitor plugin. For live numeric ROS sensor topics, use **rqt → Plugins → Visualization
→ Plot**. PlotJuggler itself can inspect exported CSV or other supported
offline data; native ROS topic subscription requires a future
`plotjuggler_ros` plugin build. The TIO description demo publishes state and TF, not real
IMU/motor telemetry.

The tools are considered fully installed only once the GUI image builds,
`rviz-check` passes, and the apps actually open from the KDE menu.

## Upstream PlotJuggler Lyrical packaging issue (14 November 2026)

The first `rviz-up` following Stage 6 failed with
`E: Unable to locate package ros-lyrical-plotjuggler-ros`.
This is an upstream ROS Lyrical binary packaging problem, reported as
`PlotJuggler/plotjuggler-ros-plugins#119` (opened May 29, 2026).
The ROS binary build references a removed rosbag2 header:
`rosbag2_cpp/typesupport_helpers.hpp`.

The source package is **indexed** by ROS but is **not available as a
binary APT package** for the Lyrical base image. The official status page
for Lyrical does show `plotjuggler` 3.17.2 and `rqt_plot` 1.7.6.
The Dockerfile now installs those and does not require the unavailable
plugin or assert `ros2 pkg prefix plotjuggler_ros`. No host
Kubuntu package repair is required. The old RViz2 image remains available
until the corrected new image builds successfully.

On the workstation, after pulling the fix:

```bash
cd ~/kubuntu_config
git pull --ff-only
bash scripts/ros2-env.sh rviz-up
bash scripts/ros2-env.sh rviz-check
python3 scripts/install-ros2-launchers.py --check
python3 scripts/install-ros2-launchers.py --install
```

If there is any further `E: Unable to locate package ...` message,
do not guess a replacement package or install mismatched ROS distributions;
share the full container build output.

Upstream:
- GitHub PlotJuggler ROS plugin issue #119.
- ROS Lyrical package status at `repo.ros2.org/status_page/ros_lyrical_default.html`.

## Fix: rviz-check embedded Bash quotation (14 November 2026)

A prior `rviz-check` wrapper could report a `bash -c` syntax error because warning
messages used *single quotes inside an outer single-quoted* `bash -lc`
argument. The helper now uses double quotes within that argument.
An automated regression test checks the **embedded Bash argument** as well
as the wrapper, to catch quoting issues that plain `bash -n` misses.

After pulling the fix, rerun only `bash scripts/ros2-env.sh rviz-check`;
the Docker image does **not** need rebuilding. The KDE launchers can then
be installed with `python3 scripts/install-ros2-launchers.py --check`
followed by `--install` as the normal desktop user.
