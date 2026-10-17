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
| Zellij (large KDL config) | Byte-for-byte same |
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

Pinned `Polonium v1.2.1`, Git commit
`3638b1625e95877f93279527de3b82b9b09aff3a`.

| Dependency | Source / check |
| --- | --- |
| Plasma 6.4+ and Wayland session | Base Kubuntu desktop and installer preflight |
| `kpackagetool6` | Explicit APT manifest (KF6 package tool) |
| `kwriteconfig6`, `plasmashell` | KDE base desktop; checked at install |
| `nodejs`, `npm` | APT manifest; Node 20.19+/22.12+/24+ checked |
| `make`, `zip`, `unzip`, `git` | Explicit APT manifest and installer checks |
| `esbuild` | Pinned upstream npm lockfile; `npm ci --ignore-scripts` |
| `kwin-api` | **Required upstream Git submodule**, pinned to `8fc04bd086a1445ea67783eaa33517b70e01c063`; fetched and verified before npm |
| DBus saver | Optional upstream feature **disabled by default** (`UseDBusSaver=false`); not required to tile windows |
| Other KWin add-ons | None; Polonium self-contained KWin script |

CI compiles the exact revision, checks the generated archive and plugin
metadata. It cannot exercise real window tiling without a Plasma Wayland
desktop session. After installation, test KWin shortcuts and monitor behavior
manually.

## Intentionally unchanged

The rest of the application's package selection, Brave and VS Code signing,
OS/driver/EFI policy, standard desktop paths and no-other-app-plugins policy
remain as previously configured.
