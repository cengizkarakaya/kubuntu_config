# Kubuntu_Config

Kubuntu / KDE Plasma 6 home desktop configuration, based on the preferences recorded in [Arch_Config](https://github.com/cengizkarakaya/Arch_Config).

## Usage
1. Install Kubuntu normally; boot into Plasma and connect to the network.
2. Run these commands as your normal user (not root):

    sudo apt update && sudo apt install -y git
    git clone https://github.com/cengizkarakaya/kubuntu_config.git
    cd kubuntu_config
    bash bootstrap.sh
    bash verify.sh

3. Log out and in; configure the remaining keyboard shortcuts in System Settings > Keyboard > Shortcuts per plasma/shortcuts.md, and manually install application add-ons as listed in applications/addons.tsv.

## Design
- Safe, idempotent-ish core (APT/Flatpak), conditional KDE configuration; no auto repartition/EFI/GRUB edits.
- Brave installed at the beginning using the official signed APT repository.
- GNU Stow for portable dotfiles; never symlink the entire KDE configuration directory.
- Existing user config files are not overwritten by Stow.
- Sources of record: packages/apt.txt, packages/flatpak.tsv, applications/addons.tsv, plasma/shortcuts.md.
- Run ~/.local/bin/sysup to update APT and Flatpak. Review firmware updates before applying. Application plugins require their own updater.
- Not all third-party plugins can be safely installed unattended; addon inventory shows these as manual tasks, not completed installations.
- Tiling: Polonium is a candidate for Plasma 6.7 Wayland; currently manual compatibility verification/install is required; bootstrap does NOT silently claim to have activated it.
- Nord look: safe KDE Breeze Dark + Nord cyan accent; full Nordic GTK / Nordzy icons manual pending source verification.
- NVIDIA RTX 4080 SUPER: use Ubuntu Drivers tool; bootstrap does not hardcode driver versions.
- Future Windows 11 on separate 512 GB SSD: manually install in UEFI mode, check EFI/GRUB boot order; no bootloader modifications in bootstrap.

## Current limitations
This repository is an initial automation baseline and is **not yet a completed or machine-tested reproduction**. Key gaps: guaranteed Polonium tiling setup, full native KDE shortcut mapping, desktop panel geometry, exact Nordic theme/font installation, program plugins requiring manual app-level integration, and end-to-end smoke tests. Verify script marks missing components. Note that Ubuntu versions can package different versions or names; review bootstrap warnings.
