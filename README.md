# Kubuntu_Config — reproducible KDE Plasma 6 workstation

A KDE Plasma port of [Arch_Config](https://github.com/cengizkarakaya/Arch_Config)
(reference commit `56c882afbd385a905b419193aa72520a688d56ea`).
Designed for Kubuntu 26.04+ with Plasma Wayland; 26.10 is the preferred target.
See the [compatibility matrix](docs/compatibility.md) for actual verification
limits, not a blanket support guarantee.

**Safety:** Run as the ordinary desktop user. No automatic partitioning,
EFI/GRUB, kernel, NVIDIA driver or firmware changes. This repository is public;
never commit personal backups, secrets or unreviewed exports.

## Install on a fresh Kubuntu desktop

Before installing, read [AGENTS.md](AGENTS.md), the [version policy](docs/version-policy.md)
and [recovery checklist](docs/disaster-recovery.md). Back up personal data,
select Plasma (Wayland), ensure at least 8 GiB free space and reliable networking.

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/cengizkarakaya/kubuntu_config.git
cd kubuntu_config
bash bootstrap.sh --core-only     # prerequisites + Brave only
bash bootstrap.sh                 # core desktop, packages and native KDE
bash bootstrap.sh --with-science  # optional signed science profile
bash verify.sh
bash scripts/version-audit.sh
```

Bootstrap is fail-fast, uses an exclusive lock and records logs under
`~/.local/state/kubuntu-config/`. Resolve failures before retrying; never
run it with sudo. Use `--skip-plasma` on bootstrap and verify to preserve
existing Plasma settings. Do not rerun full bootstrap for a single application.

## What is installed

The authoritative manifests are [APT](packages/apt.txt),
[Flatpak](packages/flatpak.tsv) and optional [science APT](packages/science-apt.txt).
Native KWin, BreezeDark KDE colors, pinned Arch-compatible Yazi plugins and remaining Nord appearance assets are preserved.
Official stable releases are verified where available; no unauthorized optional
plugins or automatic tiling scripts. Details: [workstation reference](docs/workstation-reference.md#what-is-installed).

### FreeCAD

User-scope Flathub; see [migration and verification](docs/workstation-reference.md#freecad).
No automatic removal of the old APT copy.

### Anki (spaced-repetition learning)

User-scope Flathub; see [installation and verification](docs/workstation-reference.md#anki-spaced-repetition-learning).
Personal flashcards and media are separate from the package manifest.

## Maintenance

```bash
sysup check
sysup apply
sysup summary
bash verify.sh
bash scripts/version-audit.sh
```

`sysup apply` is interactive; `sysup auto` uses a detached systemd service.
Firmware is report-only. See the [maintenance reference](docs/workstation-reference.md#reliable-sysup-maintenance-interactive-and-detached)
and [command guide](docs/commands.md) for recovery, cancellation and logs.

## Documentation

| Area | Guide |
| --- | --- |
| Complete workstation reference | [Detailed installation and maintenance](docs/workstation-reference.md) |
| Reinstallation | [Post-format guide](docs/reinstall-2026.md) |
| KDE menus | [Launcher layout and portable snapshots](docs/application-launcher-layout.md) |
| Native KWin and shortcuts | [Shortcuts](plasma/shortcuts.md) |
| Arch parity | [Arch configuration parity](docs/arch-parity.md) |
| Host hardware and monitors | [Optional host configuration](hosts/README.md), [hardware diagnostics](docs/hardware-diagnostics.md) |
| Dual boot and USB preparation | [Ventoy](docs/ventoy.md), [dual boot constraints](docs/workstation-reference.md#host-constraints-and-dual-boot) |
| Science and engineering | [Science tools](docs/scientific-software.md), [build records](builds/README.md), [Conda](conda/README.md) |
| Astronomy | [Celestia, Gaia Sky and OpenSpace](docs/astronomy-simulators.md) |
| Robotics | [ROS 2](robotics/ros2/README.md), [GUI](docs/ros2-gui-launchers.md), [TIO](robotics/tio_description/README.md) |
| Network | [Network monitoring](docs/network-monitoring.md) |
| Recovery | [Inventory](inventory/README.md), [Restic](docs/backup-and-recovery.md), [disaster recovery](docs/disaster-recovery.md) |
| Security and testing | [Agent rules](AGENTS.md), [CI policy](docs/ci-policy.md), [secret scanning](docs/secret-scanning.md), [privacy policy](docs/privacy-policy.md) |
| Versions and history | [Changelog](CHANGELOG.md), [compatibility](docs/compatibility.md), [release policy](docs/release-policy.md) |

## Optional profiles

Science packages, ROS 2 Docker, RViz2, TIO, astronomy source builds,
NetAlertX, dual boot configuration, Conda and Restic require explicit
opt-in. Follow the corresponding guide; a Git pull alone does not activate
a profile or install software.

## CI, limitations and recovery

CI runs independent policy and private-data tests, Python compilation and Ruff, ShellCheck, Gitleaks, mocked safety tests
and selected upstream installation checks. CI success is not a physical
workstation test. Run the on-host checks in the relevant guides before
declaring an application or a recovery workflow verified.

For historical detail and all former README sections, use the
[workstation reference](docs/workstation-reference.md). Commands in that
reference are still run from the repository root unless stated otherwise.
