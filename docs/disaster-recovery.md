# Disaster recovery checklist

This is a procedure, not a verified bare-metal image or a guarantee of recovery.
No disk, EFI, driver or firmware changes are automated here.

## Before failure / before a clean installation

- Record the known-working Git commit and Kubuntu release.
- Run the private [inventory capture](../inventory/README.md) and
  [Conda exports](../conda/README.md). Resolve failed source queries.
- Review the [manual build records](../builds/README.md); fill only confirmed details.
- Capture the KDE launcher layout privately. Publish only separately reviewed and sanitized entries.
- Confirm actual personal paths (projects, source code, profiles, databases and media).
- Follow the [encrypted backup guide](backup-and-recovery.md); keep the password safe
  independently, verify the backup, and perform a real sample restore into an empty staging directory.
- Back up Docker volumes separately with applications stopped or consistent export methods.
- Keep a second independent/offline copy of critical work; confirm backup media remains readable.
- Never assume a Git repository contains personal data or that a successful CI run proves recoverability.

## On the replacement system

1. Confirm the intended disk and OS independently; do not erase the backup device.
2. Install Kubuntu and configure the supported graphics driver manually.
3. Clone this repository, inspect the intended commit, read AGENTS.md and the version policy.
4. Follow the [reinstall guide](reinstall-2026.md); install core and optional science profiles explicitly.
5. Restore Conda environments only from reviewed exports, and install manual software using the build records.
6. Restore personal files into an empty staging directory first; inspect and transfer selectively.
7. Restore KDE launcher templates only after executable installation and a read-only preview.
8. Restore ROS workspaces and Docker volumes explicitly; verify runtime behavior and networking separately.
9. Capture a new inventory and compare against the saved one; investigate differences rather than blindly downgrading.
10. Run verify.sh, version-audit.sh, the relevant scientific smoke tests and real KDE GUI checks.
11. Record date, hardware/OS, commit, actual acceptance commands and unresolved issues.

A restoration is not complete merely because applications start: verify critical
projects, numerical results, media, profiles and robotics workflows. Never
apply a host-specific configuration or an old device identity blindly.
