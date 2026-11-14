# Kubuntu 26.10 workstation: post-format restore (14 Nov 2026)

This document records the November setup and the reproducible subset of the workstation. This is **not** a bit-for-bit machine image. The repo is **public**. Never commit credentials, browser profiles, VPN identities, private Wi-Fi data, tokens, or complete HOME backups.

## Recommended workflow

On the **current** machine, before reinstalling Kubuntu:

```bash
cd ~/kubuntu_config
git pull --ff-only
bash scripts/menu-backup.sh --capture
# Inspect ~/.local/state/kubuntu-config/menu-current (particularly Exec=, URLs, paths).
bash scripts/menu-backup.sh --stage-repo   # explicit PUBLIC repository acknowledgment
git status --short
# Read ALL staged snapshot files before git add/commit/push.
git add backups/application-launcher/snapshot
git diff --cached --check
git diff --cached --stat
git commit -m 'Back up reviewed KDE Application Launcher layout'
git push
```

Do not run `--stage-repo` when .desktop files include private data. Use another **private** backup for sensitive files. The snapshot is not uploaded by merely running `--capture`. Until that separate commit is made, the actual personal KMenuEdit layout is **not stored in GitHub**. A human-readable layout is available in [application-launcher-layout.md](application-launcher-layout.md).

After a fresh installation (ideally same login name `cengiz` and same Kubuntu generation):

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

If the reviewed menu snapshot was committed earlier, `bash bootstrap.sh --with-science --restore-launchers` can perform the menu restore as part of installation, with interactive confirmation. Do not use that flag before the snapshot exists. On an existing system, **do not rerun full bootstrap just to adjust the menu**. Use the dedicated scripts.

`bootstrap.sh` **still installs Brave** as part of its historical prerequisites, but `scripts/setup-defaults.sh` now prefers Firefox when its .desktop entry exists. Firefox itself may be provided by Kubuntu as a Snap, so verify the actual `firefox` installation and default browser after installation. KStars is now in the Flatpak manifest (`org.kde.kstars`).

## Reproducible signed APT science profile (opt-in)

`packages/science-apt.txt` covers the newly added QGIS, SimulIDE, Wireshark, Octave (+ control/signal), Stellarium, LAMMPS (+ examples), Quantum ESPRESSO (+ SSSP), QElectroTech (+ examples/data), PulseView, sigrok-cli, ngspice and KiCad basic libraries. The separate installer simulates the **whole transaction before installing** and refuses removals:

```bash
bash scripts/install-science.sh --plan
bash scripts/install-science.sh --install
```

**Quantum ESPRESSO packaging gotcha:** `quantum-espresso-data-sssp` *conflicts* with `quantum-espresso-data`. Install **only** SSSP alongside `quantum-espresso` using `--no-install-recommends`; adding both packages was observed to fail. The actual November installation of `quantum-espresso 6.7-4build1`, `quantum-espresso-data-sssp 1.3.0-3build1` and `libscalapack-openmpi2.2 2.2.3-5` was confirmed by `dpkg -l`. `pw.x` resolved to `/usr/bin/pw.x`. A completed Si SCF calculation was **not** confirmed in the conversation.

Very large, nonessential KiCad 3D models and demonstration/docs packages are in `packages/science-large-optional.txt` and are **not** automatically installed. OpenFOAM was explicitly deferred. ROS 2 and Gazebo were deferred.

## Non-APT installations: restore separately and verify

- **Qucs-S**: AppImage at `~/Applications/Qucs-S/Qucs-S-26.1.1-linux-x86_64.AppImage` was configured in the menu; this repository does **not** automatically download or execute unverified AppImages. Re-download from the official release, validate authenticity, then make executable and check the launcher. `ngspice` is covered by APT.
- **GeoGebra Classic 6**: Firefox URL launcher for `https://www.geogebra.org/classic`; online use, not a native offline GeoGebra install. Restore custom .desktop from a reviewed menu backup.
- **FreeCAD KiCad StepUp**: FreeCAD Addon Manager > KiCadStepUp. Recommended, but installation and completed import were **not confirmed**. Do not silently install arbitrary FreeCAD add-ons.
- **Webots**, **openEMS**, **Elmer FEM**, **SageMath**, **FEniCSx**, **OpenModelica**: existing manual/system installs require explicit vendor-specific restore work. Their original archives, Conda environment exports and full build recipes are not in this repository; `scripts/setup-scientific-launchers.sh` only creates relevant entries **after the executables exist**. See `docs/scientific-software.md`.
- **Cloudflare WARP**: was manually used via `warp-cli`; contains network/account state and is intentionally not enrolled in bootstrap. Reconnect through official setup when required.

## KDE settings that need manual verification

- Multi-monitor placement and specific display identities: configure through System Settings > Display Configuration. Do not restore an old `kscreen` configuration blindly on a changed GPU/display setup.
- The mouse crossing between monitors was improved by disabling KDE KWin **Edge Barrier** and **Corner Barrier**. Their exact saved key names/values were not supplied in chat; do not invent `kwinrc` values. Reapply in the relevant Plasma GUI and verify actual movement.
- Screen locking/suspend behavior: the desired inactivity-lock change was discussed, but actual resulting settings were not independently verified. Use System Settings > Screen Locking / Power Management and test manually; do not disable security by default in bootstrap.
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
