# Kubuntu_Config — reproducible KDE Plasma 6 workstation

A **Kubuntu** implementation of the **preferences** in
https://github.com/cengizkarakaya/Arch_Config (pinned reference commit:
56c882afbd385a905b419193aa72520a688d56ea). This is not a Pacman/Hyprland
transplant. Intended for a clean Ubuntu-based Kubuntu installation using KDE Plasma 6.

## Installation

Log into the KDE desktop as your normal user. Keep the computer on AC power and internet.

    sudo apt-get update && sudo apt-get install -y git
    git clone https://github.com/cengizkarakaya/kubuntu_config.git
    cd kubuntu_config
    bash bootstrap.sh
    bash verify.sh

Brave is installed immediately after minimal prerequisites. To install only Brave first:

    bash bootstrap.sh --core-only

Resume later with normal bootstrap. Safe to re-run: APT is idempotent, Flatpak
checks existing installations, portable Stow refuses conflicting files, and
Plasma script writes named KDE keys (no mass config replacement).

Run updates:

    sysup

## Repository contents

- bootstrap.sh: deterministic sequence and per-run log, no arbitrary driver/boot changes
- packages/apt.txt: KDE-native and creative workstation packages
- packages/flatpak.tsv: LocalSend, Joplin, Zotero, OrcaSlicer
- packages/optional.txt: dev/build adjuncts (review before enabling)
- applications/addons.tsv: **every requested third-party add-on** with installation channel and actual level of automation
- applications/vscode-extensions.txt: optional vetted VS Code extensions
- dotfiles/: portable Alacritty, Helix, Yazi, Zellij, Starship, Bat, Bottom, Git, Zathura and Readline snapshot from Arch_Config
- shell/interactive.bash: Arch-like bash shortcuts, sourced from Ubuntu ~/.bashrc without overwriting the file
- scripts/: Brave/VSCode repos, Rust toolchain, applications, Stow, KVM, default apps, safe updates, boot diagnostics
- plasma/: KDE native settings and Kröhnkite KWin6 build from pinned source
- themes/: KDE Nord color scheme, Nordic GTK, FiraCode Nerd Font with SHA256
- hosts/: information only; never copies /boot or /etc from Arch
- verify.sh: per-item PASS/WARN/FAIL, no changes to host
- .github/workflows/qa.yml: remote static Bash / manifest checks

## What is preserved from Arch and what is not?

Preserved: Alacritty, Helix, Yazi (plugins declared in package.toml),
Zellij, Bat, Bottom, Starship, Git, zoxide/fzf/eza CLI behavior, 10 virtual
desktops, Nord palette, FiraCode Nerd Font, most Super shortcuts, 5/20 pixel gaps.

Replaced by KDE-native counterparts: Hyprland -> KWin+Kröhnkite,
Fuzzel -> KRunner, Waybar -> Plasma panel, Thunar -> Dolphin,
Grim/Slurp -> Spectacle, Mako -> Plasma notifications,
Hyprlock/idle -> KScreenLocker/Power Management, Greetd -> SDDM.
No reflector, AUR, pacman, Hyprland Lua, TLP, systemd-boot loader entry,
Arch Intel graphics configuration, or copied host-wide dotfiles.

## Kröhnkite and keyboard shortcuts

Kröhnkite fork: https://github.com/KBeDevel/krohnkite-kwin6
Pinned at fd67a3acd0a220bb6c1f41a1c7f3cc538ef19a82.
Installer builds against the upstream npm lockfile without scripts and patches
conflicting defaults before packaging. Intended Meta+H/J/K/L focus and
Meta+Shift+H/J/K/L move are Kröhnkite native actions; Meta+Shift+F float.
See plasma/shortcuts.md for all keys and known differences. Due to Plasma 6
KGlobalAccel session state, verify shortcuts after re-login in
System Settings > Keyboard > Shortcuts; KDE UI is authoritative.
The Hyprland Meta+R modal resize submap does not have an exact KDE-native
equivalent: use Kröhnkite Meta+Ctrl+H/J/K/L (no additional daemon).

## Plugins are a separate, auditable installation phase

A Krita/Blender/FreeCAD/KiCad/Joplin plugin is not the same as installing
its host application. The TSV manifest distinguishes automatically attempted
APT components from in-app managed extensions. Third-party extensions that
depend on proprietary ABI, GPU Python wheels, per-user profiles, license or
unverified compatibility are **not installed blindly**. Manual tasks are not
marked installed. Follow applications/README.md and report from verify.sh.

Kdenlive Whisper: choose/download the model and dependencies via Kdenlive UI
when needed, rather than downloading gigabytes automatically.
GIMP 2.x plug-ins must never be injected into GIMP 3.

## Machine-specific tasks and security

Desktop hardware: MSI Z790, i5-13600K, RTX 4080 SUPER, 64GB RAM; Linux on
Samsung 990 Pro 2TB; future Windows 11 on separate 512GB drive.
Neither GRUB nor EFI partition is touched by bootstrap. Read
hosts/home-desktop.md before installing Windows; diagnose with
bash scripts/dualboot-diagnostics.sh
    bash scripts/configure-dualboot.sh           # read-only dry run, Windows first
    bash scripts/configure-dualboot.sh --apply   # opt-in only after Windows is detected. Windows selection at boot requires
the Windows installation and UEFI/GRUB discovery afterwards.

Drivers and firmware stay managed by Ubuntu; no NVIDIA runfile, no blanket
ubuntu-drivers autoinstall, no unattended fwupd flashing. Monitor arrangement
is saved in KDE UI with real display connector IDs, never copied from the laptop.
Libvirt permissions/socket configured conditionally by setup-libvirt.sh.

Backups: Stow does not overwrite user-owned dotfiles. KDE global shortcut file
is backed up to ~/.local/state/kubuntu-config/backups/ before targeted edits.
No secrets, browser profile, passwords, media libraries or SSH keys are committed.

## Verify and recovery

    bash verify.sh
    bash bootstrap.sh --skip-plasma
    bash scripts/dualboot-diagnostics.sh

Run logs: ~/.local/state/kubuntu-config/.
APT unavailable names: ~/.local/state/kubuntu-config/apt-unavailable.txt.
A FAIL is a missing core requirement; WARN means unavailable/unchecked and
must be reviewed. This code has been statically reviewed but has **not** been
run on the target PC; release-dependent KDE/global-shortcut integration and
app-specific plugins need validation in a live Kubuntu desktop.
