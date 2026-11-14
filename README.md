# Kubuntu_Config — reproducible KDE Plasma 6 workstation

A KDE Plasma port of [Arch_Config](https://github.com/cengizkarakaya/Arch_Config)
(reference commit `56c882afbd385a905b419193aa72520a688d56ea`).
Designed for Kubuntu 26.04+ with **Plasma Wayland** (26.10 preferred for testing).
No partitioning, UEFI/GRUB, kernel, NVIDIA driver or firmware mutation.

## Install on a fresh Kubuntu desktop

Log in as your **normal user**, select **Plasma (Wayland)** at the login screen,
back up personal configurations, ensure at least 8 GiB of free disk space, and use
a reliable network. Do not run the bootstrap with sudo.

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/cengizkarakaya/kubuntu_config.git
cd kubuntu_config
bash bootstrap.sh --core-only   # fast first stage: Brave for ChatGPT
bash bootstrap.sh               # install/update core packages, theme and native KDE settings
bash bootstrap.sh --with-science # OPTIONAL: signed scientific/electronics package profile
bash verify.sh
```

`bootstrap.sh` is **fail-fast**: if a required APT/Flatpak/Rust/theme/component
cannot be installed or verified, it exits nonzero and names the failed stage.
Rerun the same command after resolving the error. It uses an exclusive lock to
prevent concurrent bootstraps. Run logs and APT availability diagnostics go to
`~/.local/state/kubuntu-config/`; no silent missing-app success.

To preserve existing Plasma settings during troubleshooting, use
`bash bootstrap.sh --skip-plasma` and `bash verify.sh --skip-plasma`.
The default installation uses native KWin without an automatic tiler.
`--core-only` is deliberately limited to prerequisites and Brave.

## What is installed

- `packages/apt.txt`: CLI and terminal emulators (Alacritty plus optional-use Cool Retro Term), KDE (including `kde-spectacle`), graphic/engineering (including LabPlot and Cantor), desktop and virtualization applications
- `scripts/install-helix.sh`: newest verified official stable Helix release with runtime assets (not available as Kubuntu 26.10 APT package)
- `scripts/install-bottom.sh`: newest verified official stable Bottom (btm) release (not available as Kubuntu 26.10 APT package)
- `packages/flatpak.tsv`: Obsidian, Zotero, OrcaSlicer and LocalSend
- `scripts/install-rust.sh`: stable Rust via existing or APT-provided rustup; missing rustup is a hard error with manual recovery guidance
- `scripts/setup-yazi-apt.sh`: official signed stable Yazi APT source (Yazi is not in the default Kubuntu archive)
- `scripts/install-herdr.sh`: newest official STABLE Herdr Linux release, verified against GitHub-published SHA-256
- `dotfiles/`: portable Alacritty, Bat, Bottom, Fastfetch, Git, Helix, Readline, Starship, Yazi; installed by GNU Stow without overwriting existing files
- `scripts/install-yazi-plugins.sh`: restores all 10 Arch Yazi plugins and the pinned Nord flavor through `ya pkg install`; `scripts/yazi-rg` restores search hotkey functionality
- `shell/interactive.bash`: Arch-like aliases sourced from `~/.bashrc`
- `themes/`: Nord KDE colors, KDE general interface font at **12 pt** (FiraCode Nerd Font), unchanged 10 pt monospace/GTK fonts, and newest stable SHA-256-verified Nerd Font
- `plasma/`: preserves the KDE virtual desktops and shortcuts; removes legacy user-installed Polonium when migrating to native KWin
- `scripts/sysup`: interactive and detached systemd-supervised maintenance; per-stage checkpoint/retry/error reports, firmware *report only*
- `scripts/configure-sddm-numlock.sh`: enables Num Lock on the SDDM login screen (X11 and KWin/Wayland greeters)
- `verify.sh`: local package inventory, dotfile links, native KWin state and add-on policy
- `scripts/version-audit.sh`: fail-fast online check against current APT candidates, Flathub stable commits and GitHub release versions

**Cool Retro Term:** The standard Kubuntu APT manifest installs
`cool-retro-term` alongside Alacritty. This is an optional-use retro
CRT-styled terminal (phosphor glow, scanlines, screen curvature), not a
replacement for Alacritty or Bash. The Ubuntu 26.10 repository currently
packages stable `1.2.0+ds2-4.1`; the upstream 2.0 series is beta, so
do not switch to prereleases or add external repositories automatically.
Start with `cool-retro-term` or find **Cool Retro Term** in the KDE
Application Launcher. Configure its visual effects through the terminal's
context menu. Its shell uses the existing Bash configuration.

LabPlot and Cantor are installed together through APT. On this workstation,
LabPlot 2.12.1 crashed at startup until Cantor was installed.

**Yazi is the only exception to the no-optional-add-ons policy.**
Its 10 pinned plugins, Nord flavor, Lua setup, search helper and shortcuts
are restored from Arch_Config. Other optional application/editor extensions
remain disabled. Previously installed user extensions are not uninstalled.
Required system dependencies and Flatpak runtimes may still be installed.
No third-party automatic KWin tiling script is installed. See `applications/README.md`.

## Post-format recovery: KDE menu, science tools, Firefox default

The November 2026 workstation expansion is documented in
[**post-format restore guide**](docs/reinstall-2026.md) and
[**Application Launcher category inventory**](docs/application-launcher-layout.md).

On the existing PC **before formatting**, privately capture current KMenuEdit
entries and optionally stage a carefully reviewed snapshot for GitHub:

```bash
bash scripts/menu-backup.sh --capture
bash scripts/menu-backup.sh --stage-repo    # only after manual privacy review; public repo
```

Then review the snapshot files and explicitly `git add`, `git commit`, `git push`.
**The repository does not yet contain the actual local snapshot** until this is
done from the PC. After reinstalling, use `--plan-restore` then `--restore`
to restore the tracked files safely. Neither capture nor restore backs up
Firefox profiles, passwords, monitor hardware identity or any personal data.

The optional `packages/science-apt.txt` profile covers recent APT applications
(QGIS, Octave, Stellarium, LAMMPS, Quantum ESPRESSO + SSSP,
QElectroTech, PulseView, SimulIDE and related tools).
Use `bash scripts/install-science.sh --plan` for a transaction simulation
or `bash bootstrap.sh --with-science` for an explicit full install.
Large KiCad 3D packages, OpenFOAM, ROS 2 and externally built applications
are **not** installed automatically. KStars is in the user Flatpak manifest.

**Firefox is preferred as the default browser when a valid Firefox desktop
entry exists.** Brave remains an installed optional browser (legacy core
prerequisite); the setup no longer resets the default to Brave.

## Scientific and engineering applications (optional)

The host has a separate, manually managed scientific stack (ParaView, GNU
Radio, Qalculate! Qt, OpenModelica/OMEdit, KStars, CalculiX/CGX, Webots,
Elmer FEM, openEMS, SageMath and FEniCSx, alongside APT-managed LabPlot and
Cantor). To **check or create KDE Application Launcher entries** for software
already installed on the machine:

```bash
bash scripts/setup-scientific-launchers.sh --check
bash scripts/setup-scientific-launchers.sh --install
```

This user-scoped script avoids duplicate system/Flatpak entries and does not
overwrite existing custom shortcuts. CLI-only solvers receive interactive
terminal entries, not imaginary GUIs. The script **does not install** scientific
software; large source builds and Conda environments are not part of the
default `bootstrap.sh` or `sysup` workflows unless the opt-in
`--with-science` APT profile is explicitly requested. See
[scientific software inventory and launcher details](docs/scientific-software.md)
for tested host paths, validation commands and reproduction limits.

## Native KWin and Arch key bindings

The workstation uses KDE's built-in floating windows, quick tiling and
optional native tiling editor. Automatic Polonium tiling was removed after
causing window placement and focus issues on the dual-monitor setup.

On existing systems, `bash plasma/disable-polonium.sh` backs up
`~/.config/kwinrc`, disables Polonium and removes only the user-installed
Polonium KWin script if present. It does not restart KWin, change monitor
settings or touch NVIDIA drivers. Sign out and back in after migration.

`plasma/shortcuts.sh` retains application shortcuts Meta+Enter, Meta+B,
Meta+E, Meta+M, desktop switching and Meta+Q. Meta+F now maximizes
while keeping the KDE panel visible; Meta+Shift+F enters true fullscreen.
Borderless Alacritty windows can be moved with Meta+left mouse drag or
resized with Meta+right mouse drag. Previously provided H/J/K/L tiling
shortcuts are no longer installed. Configure any replacements
in **System Settings > Keyboard > Shortcuts**. See `plasma/shortcuts.md`.

## SDDM login-screen Num Lock

Full bootstrap enables Num Lock at the SDDM password screen using the
configuration verified on the workstation:

- `/etc/sddm.conf` -> `[General] Numlock=on`
- `/var/lib/sddm/.config/kcminputrc` -> `[Keyboard] NumLock=0`

The script uses `kwriteconfig6` to preserve unrelated configuration,
runs the second write as the `sddm` account, verifies both values and
never restarts SDDM or KWin. Rerun it standalone with
`bash scripts/configure-sddm-numlock.sh` (as a regular user; sudo is
invoked only for the relevant configuration writes). The greeter must be
tested on a real login screen; static CI cannot confirm keyboard state.

## Latest stable version policy (important)

The bootstrap no longer treats "already installed" as "latest":

- **APT apps (including Brave and VS Code):** `apt-get update`, install/upgrade
  every manifest package to the newest **candidate in the configured signed
  Kubuntu or vendor repository**; compare installed version with `apt-cache
  policy` and fail if outdated.
- **Flathub apps:** install or upgrade every app even when already installed;
  compare installed and remote stable commits.
- **Herdr / Nerd Font:** resolve latest official *stable* GitHub
  release **at install time**. Require SHA-256 asset digest, download over
  HTTPS, verify its contents/version before replacing existing software.
- **Rust:** update the stable toolchain and selected components.
- **Yazi:** install newest signed stable Yazi package, **preserve the exact
  ten Arch_Config plugins and Nord flavor with locked revisions**, per your
  existing preference. Other app add-ons stay disabled.
- **Nordic GTK/Nordzy icons:** existing selected and pinned source snapshots
  are kept intentionally to preserve the specified Nord appearance.

**Limitation:** the newest package inside Ubuntu's supported APT archive is
not necessarily the newest upstream release. Without changing distro,
introducing unverified PPAs, installing conflicting AppImages/Flatpaks or
building everything from source, no script can safely guarantee "absolute
upstream latest" for every KDE and creative app. AI agents MUST check official
vendor release information before promising that, and report discrepancies.
Do not silently substitute third-party repositories or beta builds.

`scripts/version-audit.sh` provides a strict installed-vs-configured-repository
check after bootstrap. GitHub release lookups can fail due to rate limits or
network outages; bootstrap then **fails rather than installing unverifiable
binaries**. Installed versions can change after the audit as new releases
appear. See `docs/version-policy.md` and `AGENTS.md`.

VS Code and Brave are installed from their official signed repositories.
Flatpak apps use the Flathub remote in **user** scope. GitHub release assets (Herdr and FiraCode) are resolved at runtime
and checked against their published SHA-256. Nordic GTK/icon source snapshots
remain deliberately pinned to preserve your existing look. This does not establish a third-party
security audit of all npm packages or visual plugins.

```bash
sysup check          # inspect pending updates
sysup apply          # interactive maintenance, leave terminal open
sysup auto           # detached, noninteractive systemd service
sysup status         # progress and last stage result
sysup logs           # recent terminal logs and system journal
bash verify.sh       # read-only inventory verification
bash scripts/dualboot-diagnostics.sh
```

NVIDIA installation and CUDA remain **outside bootstrap**. Run
`bash scripts/gpu-diagnostics.sh` for safe, read-only NVIDIA/Vulkan/OpenGL
inventory. This is not a real Blender OptiX, CUDA, NVENC or multimonitor
stability test; validate these in the applications manually. Static checks do not prove application-level GPU acceleration.

## Host constraints and dual boot

Workstation: i5-13600K, MSI MAG Z790, 64 GB, RTX 4080 SUPER; Kubuntu on
Samsung 990 Pro 2 TB; optional later Windows 11 on a separate 512 GB SSD.
Neither operating-system disk is touched by this repository. Configure the
3440x1440 and 2560x1440 displays in KDE's actual display UI.
See `hosts/home-desktop.md`.
The optional `hosts/configure-alacritty-lg.sh` script restores the tested
Alacritty KWin placement for this specific two-monitor arrangement; it is
not run by the general bootstrap or sysup.

After Windows is installed, use the read-only diagnostics first. The
`scripts/configure-dualboot.sh` command is dry-run by default and only
allows GRUB OS probing after verifying Windows and an explicit typed
confirmation. It never installs GRUB or modifies partitions. Always back up
EFI and personal data before editing boot settings.

## Reliable sysup maintenance (interactive and detached)

After updating this repository, refresh the installed command **without running
the full desktop bootstrap**:

```bash
cd ~/kubuntu_config
git pull --ff-only
bash -n scripts/sysup
install -Dm755 scripts/sysup ~/.local/bin/sysup
sysup doctor
sysup check
```

The standard `sysup` or `sysup apply` remains **interactive**: it shows the
cached APT upgrade simulation, asks for approval on the controlling TTY, and
allows configuration questions. **Keep that terminal open.** If the terminal
is closed, the interactive process may be interrupted; use the detached mode
when this is a concern.

```bash
sysup auto             # one explicit noninteractive run, detached under systemd
sysup status           # colored stage summary and live unit state
sysup summary          # colored final summary (also after terminal closes)
sysup logs             # latest interactive log, automatic unit journal (sudo)
sysup cancel           # request stop after the CURRENT stage completes
sysup resume --auto    # retry only incomplete/failed automatic stages
sysup resume           # same approach for interactive runs
```

`sysup auto` authenticates with sudo, copies the supervisor to the
**root-owned** `/usr/local/libexec/kubuntu-sysup`, and launches a **transient
system systemd service**. It survives closing Alacritty (but not shutdown).
Root-managed APT and Snap run with system privileges; Flatpak, Rustup and
GitHub-based installers run under the desktop user's UID and HOME. No timers
or unattended recurring updates are installed. Each run has an exclusive
maintenance lock shared with `bootstrap.sh` (using `flock --close` to
prevent inherited lock handles).

Automatic APT uses Debconf's noninteractive frontend and retains existing
conffiles in ambiguous cases; some third-party maintainer scripts can still
fail. **Neither `sysup cancel` nor retry forcibly terminates APT/dpkg**:
cancellation is deferred to a stage boundary. An administrator forcing
`systemctl stop`, logging out of the interactive session, rebooting or
losing power during a package operation is not guaranteed safe. If an APT
transaction was interrupted, inspect `sysup doctor` and repair the package
manager manually before resuming. Never delete dpkg lockfiles.

A network preflight resolves each service's DNS name with a 15-second limit
and bounded 5/15/30-second retries. APT installation is **never blindly
repeated**; `apt-get update` uses standard safe fetch retries. Independent
ecosystems continue even if another fails, with a nonzero overall result.
Flatpak warnings that indicate unresolved remote references are not reported
as clean success. Standard Ubuntu **phased updates remain phased**; the
script does not override the distribution rollout policy.

At the end of an interactive update, sysup prints an aligned, color-coded
**final summary**: each stage's success, failure or skip, elapsed time,
overall outcome, warning/failure counts and log location. When updates run
under systemd, the service journal intentionally contains the same summary
**without ANSI color codes**. Use `sysup summary` to read the latest saved
summary in color from Alacritty after closing the original terminal.
`sysup status` shows the colored summary for finished runs and also queries
the systemd unit state; while a run is active it shows live JSON status.
Automatic summaries are written to a user-readable `summary.json` in the
root-owned system state directory; package-manager logs remain separately
protected. A successful stage means its command completed successfully; it
does not prove that any package actually changed version.

Checkpoint files and JSONL events reside under
`~/.local/state/kubuntu-config/` for interactive runs and
`/var/lib/kubuntu-sysup/uid-<UID>/` for detached runs. Automatic execution
logs are also available in the system journal. `resume` first runs
`dpkg --audit` and reuses only stages recorded successful; it does **not**
resume a half-executed dpkg transaction. The `doctor` command performs
read-only checks of package configuration, process state, DNS, and snapshot
capabilities. **Automatic rollback is intentionally not implemented.**
Btrfs/Timeshift snapshots require separate backup configuration and a tested
manual restore plan before they can be relied on.

`bash tests/test-sysup.sh` exercises error isolation, checkpoint resume and
safe deferred cancellation with mocked package-manager commands, without
performing actual updates. GitHub CI cannot test a real Kubuntu systemd
session, package maintainer scripts, DNS outages or full filesystem rollback.
Verify the detached mode on the target desktop before relying on it.

## CI, limitations and recovery

GitHub Actions checks shell syntax, failure modes, GitHub release signatures/digests,
latest stable Herdr assets, native KWin policy, and the Yazi add-on inventory.
It **does not** run a genuine Kubuntu 26.10 Wayland login with the installed
NVIDIA driver. Actual KWin behavior, Flatpak portals, plugins from previous
installations, and application rendering still need target-machine smoke tests.

On failures read `~/.local/state/kubuntu-config/bootstrap-*.log`.
Stow refuses unmanaged files rather than replacing them. KDE shortcut
config has backups under `~/.local/state/kubuntu-config/backups/`.
Run `bash bootstrap.sh` again when the failed dependency is resolved.

## Arch configuration parity

Arch_Config baseline is pinned at commit
`56c882afbd385a905b419193aa72520a688d56ea`.
Alacritty, Bat, Bottom, Git, Helix, Readline and Starship dotfiles are
byte-for-byte identical. Herdr replaces Zellij; Zellij's KDL config is not migrated. Yazi's `init.lua`, `keymap.toml`,
`package.toml` and `theme.toml` are byte-for-byte identical.
Yazi's `yazi.toml` differs only by using `hx` in place of
`/usr/bin/helix` (Ubuntu executable compatibility); its functional settings
are preserved. The `yazi-rg` script likewise uses `hx` with `helix`
fallback instead of assuming the Arch path.
Fastfetch differs only in the OS logo `arch` -> `ubuntu`.
Hyprland, Waybar, Fuzzel and other compositor/desktop-specific settings
cannot be copied verbatim into KWin/Plasma. Zathura's Arch config is
not part of the present installed-app manifest; no unrelated app was added.
See `docs/arch-parity.md`.

## eza, zoxide, interactive Bash and Alacritty quick test

The Alacritty TOML (Nord palette, FiraCode Nerd Font Mono, window padding,
cursor and selection) remains **unchanged from Arch_Config**.
It intentionally uses `[window] decorations = "None"`. In KDE,
hold **Meta** and drag with the **left mouse button** anywhere in the window
to move it without a titlebar; use `decorations = "Full"` only if a visible
titlebar is preferred.
The Bash integration now includes all original eza aliases
(`ls`, `ll`, `la`, `lt`, `tree`), `zoxide init bash` for `z`/`zi`,
and the full Nord FZF color and symbol preferences.

**Bash autosuggestions (ble.sh):** The `ble.sh` package is in the APT
manifest for fresh installations. The interactive Bash integration loads
`~/.local/share/blesh/ble.sh` first if the user already installed it
there (preserving the working user-local version); otherwise it loads
`/usr/share/blesh/ble.sh` from Ubuntu. It only activates on a real
terminal, enables `complete_auto_complete=1` with a 100 ms delay, and
shows suggestions in grey (`fg=242`). The obsolete
`complete_auto_history` setting is intentionally not used.
This is Bash behavior, not an Alacritty setting. After a repository pull,
run `bash scripts/setup-shell.sh` and open a **new Alacritty terminal**.
Check `echo "$BLE_VERSION"`, `echo "${BLE_ATTACHED:-0}"`, and
`bleopt complete_auto_complete`. Typing the start of a previously used
command should show its suggested remainder; the right arrow accepts it.
No existing `~/.bashrc` or `~/.blerc` settings are overwritten.

After pulling repo updates, **do not rerun the full bootstrap** merely
to refresh Bash aliases. Run:

```bash
bash scripts/setup-shell.sh
bash scripts/check-shell-terminal.sh
```

The second command actually starts an interactive Bash subprocess to check
that `~/.bashrc` loads the aliases and zoxide functions, validates the
Alacritty TOML, font, launcher and recorded Meta+Return binding. A **real
key press** in Plasma is still required to confirm global shortcut activation.
See `plasma/shortcuts.md`.
