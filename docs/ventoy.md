# Ventoy — portable multiboot USB tool

## Workstation inventory

- Purpose: Windows 11 installation on a separate SSD and reusable Linux/rescue ISO media.
- Channel: official portable Linux release (manual restore procedure; actual installed channel/path/version not independently verified).
- Suggested extraction directory: `~/Applications/ventoy-<version>`.
- Upstream: [official download page](https://www.ventoy.net/en/download.html) and [official GitHub releases](https://github.com/ventoy/Ventoy/releases).
- No APT/Flatpak/Snap manifest entry, automatic bootstrap stage, or sysup update hook. No binaries, ISO images, device identifiers or private data are committed.

## Restore the host-side utility

1. Open the official download page and choose the latest trusted stable Linux release (not a prerelease). Download `ventoy-<version>-linux.tar.gz` and obtain its published SHA-256 from the official release.
2. Before extracting, compare the full output of `sha256sum ventoy-<version>-linux.tar.gz` with the official published value. Stop on missing or mismatched verification data. Do not execute unverified files.
3. As the normal desktop user, extract the verified archive under `~/Applications`. Replace VERSION below with the verified release version; run from the archive's download directory.

```bash
VERSION='<verified-version>'
mkdir -p "$HOME/Applications"
tar -xzf "ventoy-${VERSION}-linux.tar.gz" -C "$HOME/Applications"
cd "$HOME/Applications/ventoy-${VERSION}"
./VentoyGUI.x86_64
```

The upstream GUI may request administrator authorization. Extracting the archive installs no bootloader and does not prepare a USB disk. Do not run bootstrap as root.

## Prepare a USB device — manual, destructive first installation

**Initial Ventoy installation erases the selected drive.** Back up its files elsewhere first. Disconnect unrelated removable storage and identify the intended device by model, size and transport before choosing it in the GUI:

```bash
lsblk -o NAME,PATH,SIZE,MODEL,TRAN,FSTYPE,LABEL,MOUNTPOINTS
lsusb -t
```

Use a reliable USB device connected directly to a rear motherboard port rather than an unreliable hub. Stop on USB reset, protocol or I/O errors. Do not select the system NVMe or the Windows target SSD.

For a UEFI setup, review these GUI choices:

- Partition style: GPT.
- Secure Boot Support: enabled; keep platform Secure Boot policy unchanged. Some firmware may require Ventoy's documented key enrollment procedure; review it separately before accepting any key.
- Show All Devices: off.
- Main data partition: default exFAT; Ventoy also creates its small EFI partition.

Select Install only after reviewing the correct USB device and the data-loss warning. Follow the [official usage instructions](https://www.ventoy.net/en/doc_start.html). No repository script initializes or formats a disk.

Copy the official Windows 11 ISO to the main Ventoy partition as a normal file. Compare its SHA-256 with Microsoft's published value and compare the copied file with the source hash. Safely eject the USB using KDE before unplugging. Repeated I/O errors or incomplete copies invalidate the media until resolved.

## Boot and verify

Use the firmware's documented boot-menu key to select the UEFI USB entry. Confirm that the Ventoy menu displays the expected ISO and that it boots. Do not start Windows installation until the correct separate destination SSD and backups have been confirmed. See the repository's dual-boot section for the post-install GRUB procedure.

To read the installed Ventoy USB version, use the GUI's Device version field or the official CLI list operation (replace the placeholder with the verified **whole USB device**, never the system disk):

```bash
sudo sh Ventoy2Disk.sh -l /dev/sdX
```

The command is run from the verified extracted release directory. Do not copy the placeholder literally.

## Updates and recovery

- Download and verify the latest official stable archive again. Extract it separately; do not overwrite or delete an existing working copy until the new utility is verified.
- Host tool version and USB-installed version are different. Updating the archive alone does not update the USB.
- Back up the USB, confirm device identity and use the upstream GUI **Update** action (not Install). It is designed to preserve the data partition, but backups are still required. Stop on any I/O error.
- sysup manages its existing channels only; Ventoy updates are manual and optional.
- Verification remains a host-side task: verify archive hash, GUI launch, USB Device version, copied ISO hash and actual UEFI boot. Record these results privately.
