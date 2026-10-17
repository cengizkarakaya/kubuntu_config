# Arch shortcuts in KDE Plasma 6 + Polonium

Authoritative Arch source: `hypr/.config/hypr/bindings.lua`.
Configurator: `plasma/shortcuts.sh`. These are **desired** mappings, not verified
live registrations; KGlobalAccel on Plasma 6 Wayland can ignore file-only
updates until logout/login or explicit assignment in KDE System Settings.

| Shortcut | Behavior | Provider |
| --- | --- | --- |
| Meta+Return | Alacritty terminal | KDE application shortcut (needs live check) |
| Meta+B | Brave | KDE application shortcut (needs live check) |
| Meta+E | Dolphin | KDE application shortcut (needs live check) |
| Meta+Space | KRunner | KDE default; do not overwrite |
| Meta+Q | Close | KWin |
| Meta+F | Fullscreen | KWin |
| Meta+H/J/K/L | Focus left/down/up/right | Polonium native |
| Meta+Shift+H/J/K/L | Move window left/down/up/right | Polonium native |
| Meta+Ctrl+H/J/K/L | Resize tile | Polonium native |
| Meta+Shift+Space | Toggle active window tiling | Polonium native |
| Meta+1..0 | Switch to desktops 1..10 | KWin |
| Meta+Shift+1..0 | Send window to desktop 1..10 | KWin |
| Meta+M | Power menu | KDE application shortcut (needs live check) |
| Meta+R | Hyprland modal resize | Unsupported; use Meta+Ctrl+H/J/K/L |
| Print and Shift+Print | Screenshot/region | KDE Spectacle defaults; inspect GUI |

Polonium does not reserve Meta+Return, Meta+F, Meta+M or Meta+R in stable
1.2.1. Hence we don't patch Polonium upstream source or install a shortcut add-on.
Polonium does not provide the same floating toggle key as the old Kröhnkite.
Use its per-window `Meta+Shift+Space` tile toggle or bind an explicit
KWin floating behavior yourself after live testing.

**After login:** In `System Settings > Keyboard > Shortcuts`, inspect
KWin, Polonium and the application launchers. Resolve collisions in the GUI.
A written `kglobalshortcutsrc` key is **not** proof of an active hotkey.
