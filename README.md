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
bash bootstrap.sh               # install/update packages, theme and native KDE settings
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

- `packages/apt.txt`: CLI, KDE (including `kde-spectacle`), graphic/engineering, desktop and virtualization applications
- `scripts/install-helix.sh`: newest verified official stable Helix release with runtime assets (not available as Kubuntu 26.10 APT package)
- `scripts/install-bottom.sh`: newest verified official stable Bottom (btm) release (not available as Kubuntu 26.10 APT package)
- `packages/flatpak.tsv`: Obsidian, Zotero, OrcaSlicer and LocalSend
- `scripts/install-rust.sh`: stable Rust via existing or APT-provided rustup; missing rustup is a hard error with manual recovery guidance
- `scripts/setup-yazi-apt.sh`: official signed stable Yazi APT source (Yazi is not in the default Kubuntu archive)
- `scripts/install-herdr.sh`: newest official STABLE Herdr Linux release, verified against GitHub-published SHA-256
- `dotfiles/`: portable Alacritty, Bat, Bottom, Fastfetch, Git, Helix, Readline, Starship, Yazi; installed by GNU Stow without overwriting existing files
- `scripts/install-yazi-plugins.sh`: restores all 10 Arch Yazi plugins and the pinned Nord flavor through `ya pkg install`; `scripts/yazi-rg` restores search hotkey functionality
- `shell/interactive.bash`: Arch-like aliases sourced from `~/.bashrc`
- `themes/`: Nord KDE colors, appearance-preserving GTK/icon sources and newest stable SHA-256-verified Nerd Font
- `plasma/`: preserves the KDE virtual desktops and shortcuts; removes legacy user-installed Polonium when migrating to native KWin
- `scripts/sysup`: interactive OS/App/Rust updates, firmware *report only*
- `scripts/configure-sddm-numlock.sh`: enables Num Lock on the SDDM login screen (X11 and KWin/Wayland greeters)
- `verify.sh`: local package inventory, dotfile links, native KWin state and add-on policy
- `scripts/version-audit.sh`: fail-fast online check against current APT candidates, Flathub stable commits and GitHub release versions

**Yazi is the only exception to the no-optional-add-ons policy.**
Its 10 pinned plugins, Nord flavor, Lua setup, search helper and shortcuts
are restored from Arch_Config. Other optional application/editor extensions
remain disabled. Previously installed user extensions are not uninstalled.
Required system dependencies and Flatpak runtimes may still be installed.
No third-party automatic KWin tiling script is installed. See `applications/README.md`.

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
