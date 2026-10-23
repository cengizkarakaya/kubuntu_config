# Latest stable installation policy

The goal is **newest verifiable stable version available from an approved,
compatible installation channel at the time of installation** — NOT
unconditionally replacing every Ubuntu package with upstream development HEAD.

| Source | Installation behavior | Guarantee |
| --- | --- | --- |
| Kubuntu APT | Refresh and install/upgrade every listed package | Latest candidate in supported enabled apt repositories |
| Official Brave and VS Code signed APT | Refresh official signed channel even if already installed | Latest stable candidate in vendor repository |
| Yazi signed stable APT | Always configure official stable channel | Latest candidate in signed Yazi repo (subject to APT priorities) |
| Flathub | Install/update every listed app and compare remote commits | Latest Flathub stable branch that host supports |
| Herdr | GitHub `releases/latest` + SHA256, architecture-aware | Latest official stable published binary |
| Polonium | GitHub `releases/latest` + SHA256 + KWin metadata | Latest stable KWin script, subject to Plasma version |
| FiraCode Nerd Font | GitHub `releases/latest` + SHA256 | Latest stable font archive |
| Rust | `rustup update stable` + components | Latest supported Rust stable toolchain |
| Arch Yazi plugins + Nord flavor | Pinned `package.toml` `rev` and `hash` | Intentionally reproducible, **not newest upstream** |
| GTK Nordic and Nordzy-dark icon assets | Pinned Git source revisions | Intentionally preserved Nordic appearance |

## For AI agents installing this workstation

1. Before changes: read `AGENTS.md`, `README.md`, the manifests,
   `docs/arch-parity.md` and this file. Ask for confirmation before
   changing **installation channel**, core KDE version, driver, display,
   disk/EFI, firmware, adding PPAs or upgrading Kubuntu releases.
2. Verify OS version and KDE Wayland session; inspect `apt-cache policy`,
   Flatpak remote refs and latest official publisher release.
3. Report meaningful mismatches where official latest stable upstream
   is newer than the candidate in Kubuntu's archive; **never claim upstream
   parity without comparison**.
4. If a compatible official newer package needs a new channel, present its
   risks and request approval instead of silently installing third-party
   binaries. Maintain native KDE packages unless channel migration is approved.
5. Run `bash bootstrap.sh`; if failures occur, inspect the named stage and
   `~/.local/state/kubuntu-config/bootstrap-*.log`. Do not ignore a failure
   or falsely report installation complete.
6. Run `bash verify.sh` and `bash scripts/version-audit.sh`.
   Test Wayland/Polonium shortcuts, Herdr, NVIDIA acceleration,
   Flatpak sandbox portals, and application launches on the real PC.
7. Leave Yazi's ten locked plugins, flavor and hotkeys intact unless
   explicitly instructed to update them.

## Constraints

The date of GitHub metadata lookup is the runtime timestamp; the repository
does not hard-code a "latest" version. Outages, rate-limits, untrusted/missing
hashes or incompatible releases must cause **clear failure**, not automatic
downgrades or unverified installation. Some applications (especially creative
apps and KDE components) release more frequently than Ubuntu packages.
The automatic bootstrap deliberately stays within trusted distribution or
publisher channels.

The on-host audit guarantees the configured-channel candidate only.
It **cannot** guarantee each upstream latest patch matches the stable Kubuntu
platform. Any claim of universal "upstream latest" without checking each
vendor's current release would be inaccurate.
