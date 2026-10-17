# Arch to KDE shortcut inventory

Arch_Config authoritative file: hypr/.config/hypr/bindings.lua
Plasma shortcut installer: plasma/shortcuts.sh. Kröhnkite actions are in upstream res/shortcuts.qml, patched at install.

| Arch action | Plasma 6 implementation | Status |
| --- | --- | --- |
| Meta+Return terminal | Alacritty .desktop through KGlobalAccel services | configured; test after relogin |
| Meta+B browser | Brave through KGlobalAccel services | configured; test after relogin |
| Meta+E file manager | Dolphin through KGlobalAccel services | configured; test after relogin |
| Meta+Space launcher | KRunner native shortcut | inspect; do not steal key without checking layout |
| Meta+Q close | KWin Window Close | configured |
| Meta+F fullscreen | KWin Window Fullscreen | configured |
| Meta+Shift+F float | Kröhnkite Toggle Float, locally remapped | configured by patched build |
| Meta+H/J/K/L focus | Kröhnkite FocusLeft/Down/Up/Right | upstream default |
| Meta+Shift+H/J/K/L move | Kröhnkite ShiftLeft/Down/Up/Right | upstream default |
| Meta+R resize submap | unsupported; cannot replicate modal Hyprland keymap | Meta+Ctrl+H/J/K/L resize in Kröhnkite |
| Meta+1..0 workspaces | KWin switch desktop 1..10 | configured |
| Meta+Shift+1..0 move desktop | KWin window to desktop 1..10 | configured |
| Meta+M power | KDE LogoutPrompt through desktop launch | configured; verify command works |
| Print area to clipboard | Spectacle native | verify manually |
| Shift+Print save area | Spectacle native | verify manually |
| Meta+Ctrl+L lock | KDE native screen lock (usually Meta+L) | manually assign if desired |
| Meta+N notifications | KDE notification history, action-dependent | manual KDE shortcut |
| Meta+Shift+N DND | KDE notifications DND toggle | manual KDE shortcut |
| Meta+W wallpaper | KDE desktop contextual UI | manual action |

Key conflicts: Krohnkite upstream owns Meta+Return (set master), Meta+F (toggle float), Meta+M (monocle) and Meta+R (rotate). Script patches these defaults before compiling to protect the Arch keymap. If installing Krohnkite manually, repeat this patch in KDE Shortcuts.

KGlobalAccel is stateful under Plasma Wayland. Script edits kglobalshortcutsrc but does NOT claim that the active session has reloaded everything. KDE System Settings > Keyboard > Shortcuts is authoritative. After logout/login, resolve remaining conflicts there.
