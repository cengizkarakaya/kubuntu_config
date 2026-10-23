# Arch_Config parity audit

**Baseline**: [Arch_Config commit 56c882a](https://github.com/cengizkarakaya/Arch_Config/tree/56c882afbd385a905b419193aa72520a688d56ea)

Audit compares the *committed configuration files*. It does **not** prove
that all GUI applications have identical preferences after a live KDE session
or that all plugin APIs remain compatible in new Yazi versions.

| Configuration | Comparison to Arch |
| --- | --- |
| Alacritty | Byte-for-byte same |
| Bat | Byte-for-byte same |
| Bottom | Byte-for-byte same |
| Git | Byte-for-byte same |
| Helix config + languages | Byte-for-byte same |
| Readline | Byte-for-byte same |
| Starship | Byte-for-byte same |
| Herdr replaces Zellij | Zellij KDL configuration is no longer installed; Herdr uses its own settings |
| Yazi init.lua | Byte-for-byte same |
| Yazi keymap.toml | Byte-for-byte same |
| Yazi package.toml (10 plugins + Nord flavor) | Byte-for-byte same |
| Yazi theme.toml | Byte-for-byte same |
| Yazi yazi.toml | Same except `/usr/bin/helix` -> `hx` for Kubuntu |
| Yazi rg/fzf helper | Same search workflow; `hx` (or `helix`) replaces Arch absolute Helix path |
| Fastfetch | Same except Arch logo becomes Ubuntu logo |
| Nord colors and appearance | Adapted to KDE/Qt + GTK; not byte-for-byte desktop files |
| KDE shortcuts, tiling, panels | Adapted from Hyprland to Plasma/Polonium; exact equivalence impossible |
| Zathura | Original Arch file present in Arch_Config but not installed/managed by current Kubuntu manifest |
| Other GUI application preferences | No portable Arch dotfiles for them in baseline; defaults controlled by their package/profile |

## Yazi: exactly restored

The Yazi manifest retains pinned revisions and hashes for
`git`, `full-border`, `toggle-pane`, `smart-enter`, `jump-to-char`,
`smart-filter`, `smart-paste`, `chmod`, `mount`, `diff`
and `AdithyanA2005/nord` flavor. `ya pkg install` installs all exactly
from `package.toml`. It will **not** update them to latest master by default.

`scripts/yazi-rg` is installed at `~/.local/bin/yazi-rg` to satisfy the
original `g r` mapping. Requires `rg`, `fzf`, `bat`, `hx`.
The official Yazi build also requires the `file` command, now in APT list.

## Polonium requirements

Polonium **latest stable GitHub release at install time** (not a fixed version).
The official release archive is validated by its published SHA-256 and
the embedded KWin metadata.

| Dependency | Source / check |
| --- | --- |
| Plasma 6.4+ and Wayland | Kubuntu desktop, checked before Polonium install |
| `kpackagetool6`, `unzip`, `kwriteconfig6`, `plasmashell` | KDE and APT manifest; checked at installation |
| Official `polonium.kwinscript` | GitHub newest stable release with SHA-256 asset digest and KWin ID/version validation |
| Node/npm/esbuild/kwin-api | **Not needed** for the published stable KWin archive; do not compile arbitrary HEAD |
| DBus saver | Optional upstream feature, not installed by default |
| Other KWin add-ons | None; Polonium is the requested KWin script |

CI validates the actual newest stable release archive. It cannot prove
real KWin/Wayland window behaviors without a logged-in Plasma desktop.

## Intentionally unchanged

The rest of the application's package selection, Brave and VS Code signing,
OS/driver/EFI policy, standard desktop paths and no-other-app-plugins policy
remain as previously configured.
