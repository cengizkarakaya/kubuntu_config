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
bash bootstrap.sh               # complete setup, including pinned Polonium
bash verify.sh
```

`bootstrap.sh` is **fail-fast**: if a required APT/Flatpak/Rust/theme/component
cannot be installed or verified, it exits nonzero and names the failed stage.
Rerun the same command after resolving the error. It uses an exclusive lock to
prevent concurrent bootstraps. Run logs and APT availability diagnostics go to
`~/.local/state/kubuntu-config/`; no silent missing-app success.

For an X11 troubleshooting session, or a workstation where you do **not** want
KWin changes, use `bash bootstrap.sh --skip-plasma` then
`bash verify.sh --skip-plasma`. This **does not** enable Polonium.
`--core-only` is deliberately limited to prerequisites and Brave.

## What is installed

- `packages/apt.txt`: CLI, KDE, graphic/engineering, desktop and virtualization applications
- `packages/flatpak.tsv`: Joplin, Zotero, OrcaSlicer and LocalSend
- `scripts/install-rust.sh`: stable Rust via existing or APT-provided rustup; missing rustup is a hard error with manual recovery guidance
- `scripts/setup-yazi-apt.sh`: official signed stable Yazi APT source (Yazi is not in the default Kubuntu archive)
- `scripts/install-zellij.sh`: pinned Zellij 0.45.1 compiled through Cargo in user scope (not an Ubuntu APT package)
- `dotfiles/`: portable Alacritty, Bat, Bottom, Fastfetch, Git, Helix, Readline, Starship, Yazi, Zellij; installed by GNU Stow without overwriting existing files
- `scripts/install-yazi-plugins.sh`: restores all 10 Arch Yazi plugins and the pinned Nord flavor through `ya pkg install`; `scripts/yazi-rg` restores search hotkey functionality
- `shell/interactive.bash`: Arch-like aliases sourced from `~/.bashrc`
- `themes/`: pinned Nord KDE colors, GTK Nordic, Nordzy-dark icons and verified Nerd Font
- `plasma/`: ten workspaces, KWin shortcuts and **Polonium 1.2.1**, built from pinned upstream source
- `scripts/sysup`: interactive OS/App/Rust updates, firmware *report only*
- `verify.sh`: strict package inventory, dotfile links, local KWin metadata and no-add-on policy; reports untestable session behaviors

**Yazi is the only exception to the no-optional-add-ons policy.**
Its 10 pinned plugins, Nord flavor, Lua setup, search helper and shortcuts
are restored from Arch_Config. Other optional application/editor extensions
remain disabled. Previously installed user extensions are not uninstalled.
Required system dependencies and Flatpak runtimes may still be installed.
**Polonium** is the sole deliberately installed KWin script, explicitly requested
as the window tiler. See `applications/README.md`.

## Polonium and Arch key bindings

Official upstream: https://github.com/zeroxoneafour/polonium
Stable: `v1.2.1`; source pinned to
`3638b1625e95877f93279527de3b82b9b09aff3a`.
Build uses `npm ci --ignore-scripts` and local esbuild in an unprivileged
temporary directory. No latest-HEAD scripts, automatic development snapshots
or arbitrary remote install commands. Requires Plasma >=6.4, Wayland, `kpackagetool6`, `zip`, `unzip`,
`make`, `npm`, and a supported Node.js release. The old Kröhnkite installation is disabled (and user-installed
script package removed if present) after Polonium installs successfully.

Polonium's own H/J/K/L focus, Shift+H/J/K/L move and Ctrl+H/J/K/L resize
preserve the familiar Arch pattern. `plasma/shortcuts.sh` writes KDE-global
shortcut *configuration* with an automatic dated backup. **KGlobalAccel may
not load file-written shortcuts in the running Wayland session.**
After installing, **log out and log in**, and test keys in
`System Settings > Keyboard > Shortcuts`. If needed, bind application launch
shortcuts in the GUI; the repository does not kill/restart KDE's shortcut daemon.

Polonium 1.2.1 does **not** claim parity with every Kröhnkite behavior, nor
with Hyprland's modal resize submap or exact 5/20px tiling gaps. See
`plasma/shortcuts.md`.

## Package health and updates

The Yazi repository is the upstream project's official stable channel,
and its downloaded signing key is confined to that repository via `Signed-By`.
Zellij is not sourced from an unreviewed third-party APT mirror: it is
installed as pinned crate `zellij 0.45.1` with `cargo install --locked`.
The Cargo build may be resource-intensive; it is user-scoped and its failure
stops bootstrap rather than being hidden.

The APT installer resolves names before installation and tries one transaction;
if dependency resolution fails, it falls back to individual installs to give
a precise failure report. It verifies *every* manifest package via dpkg.
If a package no longer exists in your chosen Kubuntu release, bootstrap reports
it as FAIL rather than falsely declaring complete setup.

VS Code and Brave are installed from their official signed repositories.
Flatpak apps use the Flathub remote in **user** scope. Downloads from GitHub
for appearance assets and Polonium are pinned to revisions; the Nerd Font archive
is additionally checked against its SHA256. This does not establish a third-party
security audit of all npm packages or visual plugins.

```bash
sysup                # only after a successful installation; interactive
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

After Windows is installed, use the read-only diagnostics first. The
`scripts/configure-dualboot.sh` command is dry-run by default and only
allows GRUB OS probing after verifying Windows and an explicit typed
confirmation. It never installs GRUB or modifies partitions. Always back up
EFI and personal data before editing boot settings.

## CI, limitations and recovery

GitHub Actions checks shell syntax and static no-add-on/Polonium invariants.
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
Alacritty, Bat, Bottom, Git, Helix, Readline, Starship and Zellij dotfiles are
byte-for-byte identical. Yazi's `init.lua`, `keymap.toml`,
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
