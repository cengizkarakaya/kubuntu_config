# Agent instructions: Kubuntu_Config

Use this repository to prepare the user's Kubuntu desktop safely, not as a
collection of shell commands to run unreviewed.

The rules below are mandatory; optional profiles remain explicitly opt-in.

## 1. Safety and execution

- Run as an ordinary user, never `sudo bash bootstrap.sh`. Use sudo only
  where the existing scripts request it for APT/OS changes.
- Alacritty KWin placement is opt-in via `hosts/configure-alacritty-window.sh`.
  Require explicit locally chosen UUID, position and size after reviewing display
  layout; never run during bootstrap or sysup. Keep host values private.
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

## 2. Version, provenance and package policy

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
- The configured KDE palette is BreezeDark. Retain
  KubuntuNord as an installed alternate palette; do not reselect it.
- Preserve a plausible existing user-local ble.sh; fresh installations use
  signed APT. Report the local provider as unverified, never as an audited
  stable release. Do not automatically install or upgrade development builds.
- Use native KWin window management. Never install or re-enable Polonium,
  Kröhnkite, or another automatic tiling script. Remove legacy Polonium
  only through `plasma/disable-polonium.sh`.
- Install no other optional app plugins/extensions unless explicitly approved.
- Do not silently switch APT apps to Flatpak/AppImage/Snap or third-party PPAs,
  force incompatible dependency upgrades, change Kubuntu release, or compile
  arbitrary repository HEAD.

## 3. Desktop, scientific software and launcher recovery

- The core bootstrap remains limited to the base manifest. Only `--with-science`
  installs the optional signed APT profile in `packages/science-apt.txt`.
  Always run a full APT simulation with no removals first. In particular,
  never install `quantum-espresso-data` alongside `quantum-espresso-data-sssp`.
- OpenFOAM and native ROS 2 installation are deferred. ROS 2 Lyrical is opt-in through the Docker Compose development profile under robotics/ros2; KiCad large 3D models and external
  AppImages, Conda environments, FreeCAD StepUp and special vendor software
  require separate explicit installation and verification.
- Firefox is the preferred default browser if its desktop entry is available;
  Brave remains available but must not replace the user's default browser.
- `scripts/menu-backup.sh --capture` saves user menu files privately.
  `--prepare-private` makes a portable copy outside Git. Never publish either
  snapshot, even after manual review. Restore only after checking the plan;
  preserve conflicting files in dated backups and rebuild the KDE cache.
  Never overwrite arbitrary home/config files.
- Document settings whose exact on-machine values are unknown as manual
  verification items, not as invented kwinrc/kscreenlockerrc edits.

## 4. Optional astronomy simulators

- Celestia, Gaia Sky, OpenSpace installations are opt-in; never add large
  builds or datasets to the default bootstrap or sysup. On 14 November 2026,
  Gaia Sky upstream v3.9.2 was newer than Flathub v3.8.0; document this
  channel difference rather than pretending Flathub is the newest upstream.
- Celestia's last released stable GitHub tag is 1.6.4; the 1.7 OBS AppImage
  and daily builds are experimental and must not be installed automatically.
- OpenSpace stable 0.22.1 requires a complex Linux source build (CMake 4+,
  GCC 15+, OpenGL 4.6); the upstream Linux binary is not available as an
  official stable download. A source-build script is not proof of on-host
  success.
- Use `scripts/install-astronomy-launchers.py --check` before `--install`.
  Preserve Stellarium and KStars in the user's existing root Astronomy submenu.
  Never generate a launcher for a missing binary or commit private menu backups.

## 5. Robotics: ROS 2 Docker development (opt-in)

- ROS 2 Lyrical development images require on-host validation; do not claim success until `bash scripts/ros2-env.sh up` and `check` succeed there.
- Keep `~/Workspaces/Robotics/tio_ws` and `rova_ws` outside the Git repo.
  Maintain non-root container UID/GID parity to avoid root-owned files.
- Initial Compose setup must not enable GPU, X11/Wayland, Docker socket,
  privileged containers, USB device access, host networking or DDS discovery
  onto the local network. Enable these only as separately reviewed stages.
- A rootful Docker Engine is in use; the wrapper explicitly uses sudo instead
  of adding the user to the Docker group. It does not install Docker Engine.

## 6. Robotics: GPU-accelerated RViz2 GUI overlay

- Validate NVIDIA Container Toolkit and Docker GPU access on each target host.
  A successful nvidia-smi container test does not prove RViz2/OpenGL rendering.
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

## 7. Robotics: TIO description template

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

## 8. Robotics: rqt and PlotJuggler desktop integration

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

## 9. Networking: optional monitoring profile

- Sniffnet, RustNet, iperf3 and NetAlertX are an explicitly opt-in profile:
  `bash scripts/install-network-monitoring.sh install`. Do not add NetAlertX
  Docker startup to full bootstrap or background sysup.
- Use the current official non-prerelease GitHub .deb assets and verify the
  published SHA-256 digest with `scripts/latest-release.sh`; perform a
  no-removals APT simulation and check package name, architecture and version.
  Do not add unsupported PPAs or confuse manually installed .deb with an
  APT repository update channel.
- NetAlertX must use rootful Docker through explicit sudo, never the docker
  group, privileged mode, host Docker socket, GPU or personal filesystem mounts.
  Host networking and NET_ADMIN/NET_RAW are deliberate for LAN discovery; the
  web listener defaults to localhost only. Review separate API exposure.
- NetAlertX uses a reviewed stable version and immutable GHCR image index digest.
  Review upstream stable release changes and digest together before explicit
  `netalertx.sh update`; never silently switch back to `latest` or auto-merge
  Docker bumps. Verify API exposure and runtime health on the host.
- Private discovery results and settings are stored in the Docker named volume,
  never commit them to the public repo. `down` must not delete this volume.
- `sysup apply` covers iperf3 via APT; updating manually installed GitHub
  .deb packages or Docker images uses the explicit optional script. Do not
  falsely imply ongoing automatic updates or host installation from Git commits.
- Verify by on-host execution and UI device discovery. Static CI is not
  evidence of live packet capture, LAN scan accuracy or Docker runtime health.
- Upstream v26.10.28 GraphQL binds 0.0.0.0:20212 independently of nginx
  LISTEN_ADDR. With UFW inactive, an added UFW deny rule does not protect it.
  The optional `netalertx-api-guard.sh enable` installs a narrow, persistent
  root-owned nftables input rule for non-loopback TCP/20212, without enabling
  UFW or changing other firewall chains or Docker bridges. Never run the guard
  automatically on bootstrap, via sysup, or by git pull; never flush the full
  nftables ruleset. Static CI cannot prove remote network isolation.

## 10. Private backup and reproducibility

- Inventory, Conda recovery and Restic backup are explicit opt-in tools; never run them automatically via bootstrap or sysup. Plans must not write files or change system state.
- Store actual host exports, explicit Conda locks, inventory and personal recovery records outside the public Git checkout. Only curated generic dependency manifests and procedures belong in Git. Never stage personal host exports or credentials.
- Never overwrite an existing Conda environment; verify new environments on the host before calling recovery successful. Do not fabricate missing build flags or package lists.
- Restic requires a reviewed private manifest and separate mounted backup filesystem; confirm physical media independence. Never automate pruning or restore over live data. Real backup, integrity check and staging restore require host verification.

## 11. Repository changes and validation

- Treat shfmt formatting differences as advisory; parser failures are blocking. Do not bulk-reformat scripts or Arch-parity dotfiles, and retain independent behavioral tests.

- Review Bandit findings under [Python security policy](docs/python-security.md); do not introduce blanket security rule exclusions or install CI dependencies through bootstrap/sysup.

- Preserve the reviewed Bash execution modes in `policy/bash-modes.toml`. Fail-fast entrypoints, explicit status collectors and sourced helpers have different requirements; run `scripts/check-bash-modes.py` and its tests. Never blindly add errexit to a sourced file or status collector.

- Check the Git index with `python3 -B scripts/check-privacy.py --index` before commit; CI scans the committed tree. Never publish actual personal records or a denylist of real identifiers. Follow [privacy policy](docs/privacy-policy.md). Install local privacy hooks only on explicit request; never overwrite existing hooks or publish the private denylist.

- Keep changes narrowly scoped, preserve independent policy and behavioral tests,
  run CI before merging, and document failures and untested host behavior.
- Keep the public README as an entry point; detailed procedures live in
  docs/workstation-reference.md and the linked guides. Review documentation links.
- Never rewrite history or create a host-verified tag without recorded host evidence.
