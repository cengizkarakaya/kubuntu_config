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

## Optional Alacritty placement on the dual-monitor desktop

Once KDE has configured the displays as **Samsung 2560x1440 on the left**
and **LG 3440x1440 on the right**, restore the tested native KWin
Alacritty window rule:

```bash
bash hosts/configure-alacritty-lg.sh
```

- Rule UUID: `6a0f76f7-a826-4eef-a335-97d1c23633ba`
- Match: Alacritty (`wmclassmatch=1`, `types=1`)
- Initial position: `2600,40` (global desktop coordinates)
- Initial size: `1732,1260`
- `positionrule=3`, `sizerule=3` (Apply Initially);
  `ignoregeometry=true`, `ignoregeometryrule=2`
- The script preserves other rules and the `[General] rules` index,
  takes a dated backup before changes, and asks KWin to reload.
- Re-running it with the same settings is a no-op; it never installs an
  automatic tiling extension.

**This is host-specific and is not run by bootstrap or sysup.**
Do not apply these coordinates with a different monitor arrangement,
scaling, or resolution. The rule restores a fixed initial layout,
not the last geometry from every application close.
