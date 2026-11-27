# Kubuntu 26.10 workstation: recovery guide

This guide describes reproducible configuration and optional recovery steps. This is **not** a bit-for-bit machine image. The repo is **public**. Never commit credentials, browser profiles, VPN identities, private Wi-Fi data, tokens, or complete HOME backups.

## Recommended workflow

Before reinstalling, follow the [disaster recovery checklist](disaster-recovery.md), including private inventory, Conda exports, manual build records and a verified encrypted backup.

On the **current** machine, before reinstalling Kubuntu:

```bash
cd ~/kubuntu_config
git pull --ff-only
bash scripts/menu-backup.sh --capture
bash scripts/menu-backup.sh --prepare-private
```

Review the private capture and portable copy, then include them in an independent
encrypted backup. Do not publish them. See [private menu recovery](../backups/application-launcher/README.md).

After a fresh installation, recover the private portable snapshot into its XDG
state location before planning or restoring the menu:

```bash
sudo apt-get update
sudo apt-get install -y git curl
cd ~
git clone https://github.com/cengizkarakaya/kubuntu_config.git
cd kubuntu_config
bash bootstrap.sh --with-science           # core apps + signed science profile
bash scripts/menu-backup.sh --plan-restore  # inspect personal-menu file replacements
bash scripts/menu-backup.sh --restore       # explicitly confirm; backups conflicts
bash scripts/setup-scientific-launchers.sh --check
bash verify.sh
```

If the reviewed private portable menu snapshot has already been recovered, `bash bootstrap.sh --with-science --restore-launchers` can perform the menu restore as part of installation, with interactive confirmation. Do not use that flag before the snapshot exists. On an existing system, **do not rerun full bootstrap just to adjust the menu**. Use the dedicated scripts.

`bootstrap.sh` **still installs Brave** as part of its historical prerequisites, but `scripts/setup-defaults.sh` now prefers Firefox when its .desktop entry exists. Firefox itself may be provided by Kubuntu as a Snap, so verify the actual `firefox` installation and default browser after installation. KStars is now in the Flatpak manifest (`org.kde.kstars`).

## Reproducible signed APT science profile (opt-in)

`packages/science-apt.txt` covers the newly added QGIS, SimulIDE, Wireshark, Octave (+ control/signal), Stellarium, LAMMPS (+ examples), Quantum ESPRESSO (+ SSSP), QElectroTech (+ examples/data), PulseView, sigrok-cli, ngspice and KiCad basic libraries. The separate installer simulates the **whole transaction before installing** and refuses removals:

```bash
bash scripts/install-science.sh --plan
bash scripts/install-science.sh --install
```

**Quantum ESPRESSO packaging gotcha:** `quantum-espresso-data-sssp` *conflicts* with `quantum-espresso-data`. Install **only** SSSP alongside `quantum-espresso` using `--no-install-recommends`; verify package availability and solver operation on the target machine.

Very large, nonessential KiCad 3D models and demonstration/docs packages are in `packages/science-large-optional.txt` and are **not** automatically installed. OpenFOAM was explicitly deferred. ROS 2 and Gazebo were deferred.

## Hardware diagnostics

`inxi`, `rasdaemon` and `ddcutil` are included in the core manifest. Check package versions, service state, RAS records and display access as described in [hardware-diagnostics.md](hardware-diagnostics.md). Keep actual device identifiers and diagnostics private.

## Non-APT installations: restore separately and verify

- **Ventoy**: restore separately from the official verified Linux archive; see [ventoy.md](ventoy.md). Never initialize a USB disk automatically.

- **Qucs-S**: obtain and verify the official release, then check the launcher. This repository does not automatically download or execute unverified AppImages. `ngspice` is covered by APT.
- **GeoGebra Classic 6**: Firefox URL launcher for `https://www.geogebra.org/classic`; online use, not a native offline GeoGebra install. Restore custom .desktop from a reviewed menu backup.
- **FreeCAD KiCad StepUp**: FreeCAD Addon Manager > KiCadStepUp. Optional; verify the addon and import locally. Do not silently install arbitrary FreeCAD add-ons.
- **Webots**, **openEMS**, **Elmer FEM**, **SageMath**, **FEniCSx**, **OpenModelica**: existing manual/system installs require explicit vendor-specific restore work. Their original archives, Conda environment exports and full build recipes are not in this repository; `scripts/setup-scientific-launchers.sh` only creates relevant entries **after the executables exist**. See `docs/scientific-software.md`.
- **Cloudflare WARP**: may contain network/account state and is intentionally not enrolled in bootstrap. Reconnect through official setup when required.

## KDE settings that need manual verification

- Multi-monitor placement and specific display identities: configure through System Settings > Display Configuration. Do not restore an old `kscreen` configuration blindly on a changed GPU/display setup.
- Review KDE KWin Edge Barrier and Corner Barrier settings in the GUI when using multiple displays; do not invent `kwinrc` values.
- Review screen locking and power management locally; do not disable security by default in bootstrap.
- Terminal: Bash eza aliases, zoxide, Starship, FZF, `ble.sh` and Alacritty setup are already encoded by `shell/interactive.bash` and existing installer scripts. Existing `~/.bashrc` is not overwritten.
- `sysup` process-supervised updates and SDDM Num Lock/native KWin setup are already in the repository; don't duplicate them in extra scripts.
- App-specific GUI settings (Firefox profile, QGIS projects, KiCad custom libraries, FreeCAD Addon Manager content, Octave user config, Webots worlds) are **not** backed up by the launcher snapshot.

## Verification after restore

```bash
bash verify.sh
bash scripts/version-audit.sh
bash scripts/install-science.sh --plan
command -v qgis octave stellarium lmp pw.x qelectrotech pulseview sigrok-cli ngspice
flatpak info --user org.kde.kstars
kbuildsycoca6 --noincremental
```

Run GUI and numerical smoke tests on the actual machine; static presence/version checks cannot prove a Qt/Wayland application opens correctly, or that scientific computation converged. If a package candidate disappears on a later Kubuntu release, STOP and review the signed repository; do not add incompatible PPAs automatically.

## ROS 2 Lyrical Docker development

The ROS 2 base image and talker/listener communication were verified on the
actual machine. A reproducible **development environment** was subsequently
added under `robotics/ros2`. Unlike the old disposable test container, the
TIO/ROVA workspace sources are persistent host bind mounts. See
[`robotics/ros2/README.md`](../robotics/ros2/README.md).

After Docker Engine + Compose is installed and functioning on the rebuilt
host, run `bash scripts/ros2-env.sh plan`, `up` and `check`. The custom
image has **not yet** been exercised on the real Kubuntu system. RViz2,
Gazebo Jetty, GPU passthrough, Rust `rclrs`, Nav2, MoveIt2 and Raspberry Pi
DDS networking are future independent stages, not automatic installers.

### ROS 2 Docker build package-conflict fix (14 Nov 2026)

The initial Compose image build failed because Ubuntu `vcstool` tried to
overwrite `/usr/bin/vcs` from `python3-vcstool` already installed in
the ROS base image. `colcon` was likewise unnecessary: `python3-colcon-core`
already provided the CLI. The Dockerfile now selects the Python/ROS packages
and verifies both commands, without modifying the Kubuntu host packages.
After pulling, retry `bash scripts/ros2-env.sh up` and `check`. The corrected
image must still be tested on the actual workstation.

### RViz2 NVIDIA GUI overlay

Check NVIDIA driver and Container Toolkit compatibility locally. Verify Docker
GPU access with `sudo docker run --rm --runtime=nvidia --gpus all ubuntu:26.04 nvidia-smi`.
Run `bash scripts/ros2-env.sh check` for the CLI development environment.

An optional graphical ROS image and Compose overlay are supplied under
`robotics/ros2/Dockerfile.rviz` and `robotics/ros2/compose.rviz.yaml`.
This configuration has **not yet been built or visually tested** on the host.
Reinstall the signed Ubuntu `nvidia-container-toolkit` package on the new
host (after verifying NVIDIA drivers), configure the Docker runtime with
`sudo nvidia-ctk runtime configure --runtime=docker`, and plan the
controlled Docker restart. Then run `rviz-plan`, `rviz-up`, `rviz-check`
and `rviz` through `scripts/ros2-env.sh` from the KDE desktop user.
The viewer uses a private Xauthority file; never commit runtime cookies.
See `robotics/ros2/README.md` for details.

### TIO URDF/Xacro starter (14 Nov 2026)

The config repository includes an **opt-in** TIO description template under
`robotics/tio_description/` and `scripts/ros2-tio.sh` commands:
`plan`, `init`, `build`, `run`, `status`.
Rebuild ROS dev + RViz2 after pulling to get Xacro/robot_state_publisher
dependencies. The `init` step will not overwrite an existing TIO project.
Robot source files, including edited Xacro, live under
`~/Workspaces/Robotics/tio_ws/src/` and must be separately backed up.
The template dimensions are tentative; robot dynamics/sensors/Gazebo remain
future independent work. See `robotics/tio_description/README.md`.

### ROS 2 tools and KDE Robotics menu shortcuts (14 Nov 2026)

The optional `robotics/ros2/Dockerfile.rviz` adds rqt (graph, console,
image view, topic and plot plugin) plus PlotJuggler 3.
Its ROS topic/rosbag plugin is **not packaged for Lyrical** as of
November 2026 (upstream issue #119); use rqt Plot for live numeric topics.
After installing the host NVIDIA runtime and restoring the ROS base
Docker environment, rebuild the GUI image with `rviz-up` and check it
with `rviz-check`.

Run `python3 scripts/install-ros2-launchers.py --check` followed by
`--install` as the desktop user to add eight application shortcuts to
the existing Robotics menu, preserving Webots. The helper backs up
the live menu before writing, and the launchers use Alacritty so sudo
prompts remain interactive. Do not run the installer from bootstrap
or with sudo. Back up `~/Workspaces/Robotics/ros-gui-config` privately.
Full steps in `docs/ros2-gui-launchers.md`.
