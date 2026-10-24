# Agent instructions: Kubuntu_Config

Use this repository to prepare the user's Kubuntu desktop safely, not as a
collection of shell commands to run unreviewed.

## Mandatory version rules

- Aim for the newest **stable, trusted, Kubuntu-compatible** release available
  **when installation is run**. Distinguish latest upstream from the APT
  repository candidate; do not equate them.
- Always refresh signed APT and Flathub metadata; upgrade already installed
  apps, don't merely skip when an executable is present. Verify results using
  `scripts/version-audit.sh`. The audit is not a substitute for per-vendor
  checks of upstream releases.
- Herdr and FiraCode are looked up using GitHub `releases/latest`.
  Verify the provider URL, published SHA-256 digest and version before
  executing or installing assets. Do not use prereleases/nightlies.
- Preserve the user's Arch-compatible Yazi config and pinned ten plugins/Nord
  flavor. Preserve Nordic GTK and Nordzy icon appearance snapshots.
- Use native KWin window management. Never install or re-enable Polonium,
  Kröhnkite, or another automatic tiling script. Remove legacy Polonium
  only through `plasma/disable-polonium.sh`.
- Install no other optional app plugins/extensions unless explicitly approved.
- Do not silently switch APT apps to Flatpak/AppImage/Snap or third-party PPAs,
  force incompatible dependency upgrades, change Kubuntu release, or compile
  arbitrary repository HEAD.

## Safety and execution

- Run as an ordinary user, never `sudo bash bootstrap.sh`. Use sudo only
  where the existing scripts request it for APT/OS changes.
- Do not alter NVIDIA drivers, firmware, partition table, EFI or GRUB
  automatically. Do not remove unrelated packages or overwrite user dotfiles.
- Before execution, examine `packages/apt.txt`, `packages/flatpak.tsv`,
  `README.md`, `docs/version-policy.md`, `docs/arch-parity.md` and
  the actual target machine state.
- For each APT application, compare installed/candidate with an **official
  upstream release** when possible. If Kubuntu's candidate lags, report it
  clearly; ask permission before selecting a safe, supported alternative.
- Use `bash bootstrap.sh --core-only` for the Brave-only phase; full
  `bash bootstrap.sh` for installation. Use `--skip-plasma` when
  explicitly preserving all existing Plasma settings.
- After installing, use `bash verify.sh` and
  `bash scripts/version-audit.sh`; exercise KDE window management and
  application functions, which cannot be verified by static CI.
- Give a truthful, itemized result: installed versions, their channels,
  unmet checks, incompatibilities, and log locations. Never label a
  failed or untested operation successful.
