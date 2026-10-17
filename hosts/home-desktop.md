# Host: home desktop (not the original Arch laptop)

- Board: MSI MAG Z790 TOMAHAWK MAX WIFI
- CPU: Intel Core i5-13600K
- RAM: 64 GB
- GPU: NVIDIA RTX 4080 SUPER
- Linux drive: Samsung 990 Pro 2 TB; independent Kubuntu installation
- Future Windows 11 drive: separate 512 GB SSD
- Displays: LG 3440x1440 + Samsung 2560x1440

No host-specific fstab, UUID, SDDM/Greetd, laptop brightness, tlp,
systemd-boot, GRUB, firmware or NVIDIA version is imported from Arch.
Use KDE System Settings > Display and Monitor to save outputs with their real
connector IDs, position and refresh rate. Avoid hard-coded HDMI/DP aliases.
NVIDIA: use the Ubuntu-provided recommendation only if missing/broken:
ubuntu-drivers devices; sudo ubuntu-drivers install (only after review).
Do not run a second GPU installer from this repository.

Windows 11 future setup:
- Back up both drives and EFI data before installation.
- Prefer UEFI; physically disconnect Linux SSD during Windows installation if
  feasible, or explicitly target the intended 512 GB drive.
- After installation restore Kubuntu Boot Manager in UEFI if Windows changed order.
- Windows entry in GRUB is not guaranteed without OS probing / EFI inspection.
- See scripts/dualboot-diagnostics.sh for read-only commands.
