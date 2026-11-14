# Agent instructions: Kubuntu_Config

Use this repository to prepare the user's Kubuntu desktop safely, not as a
collection of shell commands to run unreviewed.

## Mandatory version rules

- Aim for the newest **stable, trusted, Kubuntu-compatible** release available
  **when installation is run**. Distinguish latest upstream from the APT
  repository candidate; do not equate them.
- Always refresh signed APT and Flathub metadata; upgrade already installed
  apps, don't merely skip when an executable is present. Verify results using
  `scripts/version-audit.sh`. The audit is not a substitute for per-vendor
  checks of upstream releases.
- Herdr and FiraCode are looked up using GitHub `releases/latest`.
  Verify the provider URL, published SHA-256 digest and version before
  executing or installing assets. Do not use prereleases/nightlies.
- Preserve the user's Arch-compatible Yazi config and pinned ten plugins/Nord
  flavor. Preserve Nordic GTK and Nordzy icon appearance snapshots.
- Use native KWin window management. Never install or re-enable Polonium,
  Kröhnkite, or another automatic tiling script. Remove legacy Polonium
  only through `plasma/disable-polonium.sh`.
- Install no other optional app plugins/extensions unless explicitly approved.
- Do not silently switch APT apps to Flatpak/AppImage/Snap or third-party PPAs,
  force incompatible dependency upgrades, change Kubuntu release, or compile
  arbitrary repository HEAD.

## Safety and execution

- Run as an ordinary user, never `sudo bash bootstrap.sh`. Use sudo only
  where the existing scripts request it for APT/OS changes.
- Host-specific Alacritty KWin placement is opt-in and may only be restored
  with `bash hosts/configure-alacritty-lg.sh` after confirming the Samsung-left,
  LG-right 6000x1440 virtual desktop layout; do not run it during bootstrap.
- Do not restart the SDDM service to apply greeter preferences; verify on the
  next normal login. Preserve unrelated entries in SDDM configuration files.
- Do not alter NVIDIA drivers, firmware, partition table, EFI or GRUB
  automatically. Do not remove unrelated packages or overwrite user dotfiles.
- Before execution, examine `packages/apt.txt`, `packages/flatpak.tsv`,
  `README.md`, `docs/version-policy.md`, `docs/arch-parity.md` and
  the actual target machine state.
- For each APT application, compare installed/candidate with an **official
  upstream release** when possible. If Kubuntu's candidate lags, report it
  clearly; ask permission before selecting a safe, supported alternative.
- Use `bash bootstrap.sh --core-only` for the Brave-only phase; full
  `bash bootstrap.sh` for installation. Use `--skip-plasma` when
  explicitly preserving all existing Plasma settings.
- After installing, use `bash verify.sh` and
  `bash scripts/version-audit.sh`; exercise KDE window management and
  application functions, which cannot be verified by static CI.
- Give a truthful, itemized result: installed versions, their channels,
  unmet checks, incompatibilities, and log locations. Never label a
  failed or untested operation successful.

## November 2026 restore profile and launcher backups

- The core bootstrap remains limited to the base manifest. Only `--with-science`
  installs the optional signed APT profile in `packages/science-apt.txt`.
  Always run a full APT simulation with no removals first. In particular,
  never install `quantum-espresso-data` alongside `quantum-espresso-data-sssp`.
- OpenFOAM and native ROS 2 installation are deferred. ROS 2 Lyrical is opt-in through the Docker Compose development profile under robotics/ros2; KiCad large 3D models and external
  AppImages, Conda environments, FreeCAD StepUp and special vendor software
  require separate explicit installation and verification.
- Firefox is the preferred default browser if its desktop entry is available;
  Brave remains available but must not replace the user's default browser.
- `scripts/menu-backup.sh --capture` saves user menu files privately. The repo
  is PUBLIC: NEVER automatically commit/push private .desktop/.menu contents.
  `--stage-repo` requires manual review and approval. Restore only after
  checking plan, preserve conflicting files in dated backups and rebuild
  the KDE cache. Never overwrite arbitrary home/config files.
- Document settings whose exact on-machine values are unknown as manual
  verification items, not as invented kwinrc/kscreenlockerrc edits.

## ROS 2 Docker development (optional, never in bootstrap)

- ROS 2 Lyrical Publisher/Subscriber worked in the user's standalone Docker
  test container. The new Compose image is **not** validated on the workstation
  until `bash scripts/ros2-env.sh up` and `check` succeed there.
- Keep `~/Workspaces/Robotics/tio_ws` and `rova_ws` outside the Git repo.
  Maintain non-root container UID/GID parity to avoid root-owned files.
- Initial Compose setup must not enable GPU, X11/Wayland, Docker socket,
  privileged containers, USB device access, host networking or DDS discovery
  onto the local network. Enable these only as separately reviewed stages.
- A rootful Docker Engine is in use; the wrapper explicitly uses sudo instead
  of adding the user to the Docker group. It does not install Docker Engine.

## GPU-accelerated RViz2 GUI overlay (Stage 4)

- The host's NVIDIA Container Toolkit 1.19.1 and Docker GPU access have
  been proven by an actual `nvidia-smi` container test. RViz2/OpenGL
  rendering has **not yet** been verified.
- Optional GUI graphics are kept in `compose.rviz.yaml`, never inserted
  into the default ROS development service. The viewer may share dev's
  network/IPC namespace but not the host network.
- Request `graphics,display,utility,compute` driver capabilities for OpenGL;
  do not confuse `nvidia-smi` success with accelerated GLX rendering.
- On KDE Wayland use `QT_QPA_PLATFORM=xcb` and a private, read-only
  Xauthority cookie. Never use blanket `xhost +`, mount user credentials
  globally, or add the desktop user to the root-equivalent Docker group.
- The GUI build, X11 authentication and hardware renderer must be tested
  interactively before claiming that RViz2 has been installed successfully.

## TIO description template (Stage 5)

- TIO's four-wheel URDF/Xacro in `robotics/tio_description` is only an
  illustrative, dimensionally provisional robot description. Do not
  present its placeholder dimensions, wheel drive or steering as finalized.
- The opt-in `scripts/ros2-tio.sh init` copies once to the host TIO source;
  never overwrite a customized `tio_ws/src/tio_description` automatically.
- Description build/launch dependencies live in the ROS 2 Docker image,
  not in host Kubuntu APT. Base image changes require a dev rebuild and
  re-launching the separately built RViz2 GUI viewer.
- Static CI verifies XML syntax and no-overwrite behavior. Real colcon,
  Xacro expansion and RViz2 visualization require interactive host tests.

## ROS 2 rqt + PlotJuggler desktop integration (opt-in)

- Keep ROS GUIs in the existing optional GPU/XWayland `rviz` Compose
  service; the headless `dev` must remain usable without GPU dependencies.
  PlotJuggler 3's Lyrical ROS plugin binary package is currently unavailable
  (upstream issue #119); **never** require it in the base GUI Dockerfile.
  Use `ros-lyrical-plotjuggler` for offline plots and
  `ros-lyrical-rqt-plot` for live ROS topic graphs. Do not install mismatched
  ROS distributions or unverified standalone packages.
- App menu entries are created **only** with
  `python3 scripts/install-ros2-launchers.py --install` by the desktop
  user, never via bootstrap or sudo. Preserve the user KMenuEdit Robotics
  category and Webots. Back up the existing .menu before patching; refuse
  conflicting files, and never commit private live menu snapshots
  automatically.
- The launchers deliberately open Alacritty to provide an interactive
  prompt for rootful Docker sudo; do not add the user to the Docker group
  or install setuid/polkit bypasses.
- CI checks installer non-destructive behavior but cannot prove actual
  GPU Qt apps open. Verify by testing rqt, rqt Graph and PlotJuggler from
  KDE after rebuilding the image and passing `rviz-check`.
