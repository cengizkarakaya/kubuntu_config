# Arch shortcuts in native KDE Plasma 6

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
| Meta+H/J/K/L | Not installed | Former tiling-script shortcuts |
| Meta+Shift+H/J/K/L | Not installed | Former tiling-script shortcuts |
| Meta+Ctrl+H/J/K/L | Not installed | Former tiling-script shortcuts |
| Meta+Shift+Space | Not installed | Former tiling-script shortcut |
| Meta+1..0 | Switch to desktops 1..10 | KWin |
| Meta+Shift+1..0 | Send window to desktop 1..10 | KWin |
| Meta+M | Power menu | KDE application shortcut (needs live check) |
| Meta+R | Hyprland modal resize | Not available by default in native KWin |
| Print and Shift+Print | Screenshot/region | KDE Spectacle defaults; inspect GUI |

Kubuntu_Config does not install an automatic tiling script. Plasma's
built-in quick tiling (typically Meta+Left/Right) and native tiling editor
(typically Meta+T) can be configured in System Settings. No additional
H/J/K/L assignments are made, to preserve current working KDE shortcuts.

**After login:** In `System Settings > Keyboard > Shortcuts`, inspect
KWin and application launchers. A written `kglobalshortcutsrc` mapping
does not prove it is activated in the live Wayland session.

## Alacritty Meta+Enter: live activation

`Meta+Return` (Windows/Super + Enter) is a **Plasma global shortcut**,
not an Alacritty TOML key binding. The repository creates
`~/.local/share/applications/kubuntu-alacritty.desktop` and stores the requested
shortcut in `kglobalshortcutsrc`, but this alone **does not prove**
the running Wayland KGlobalAccel registered it.

After logging out and in, press **Meta+Enter**. If Alacritty does not open:
1. Open **System Settings → Keyboard → Shortcuts**.
2. Search for **Kubuntu Alacritty**. If absent, use **Add New → Application**
   and choose **Kubuntu Alacritty** (or Alacritty).
3. Assign **Meta+Enter** to the **Launch** action, and resolve any conflict
   with Konsole or another application in the GUI. Click **Apply**.
4. Press **Meta+Enter** again to test the real binding.

`bash scripts/check-shell-terminal.sh` checks the on-disk launcher and
shortcut setting; the live keyboard shortcut must still be exercised in the GUI.
Do not kill/restart KGlobalAccel or overwrite unrelated bindings.
