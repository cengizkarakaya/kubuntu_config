# Application extension policy

No optional add-ons for Krita, GIMP, Blender, FreeCAD, KiCad, Obsidian,
Thunderbird, Calibre, Kdenlive or VS Code are installed automatically.

**Exception explicitly requested:** Yazi's 10 plugins and Nord flavor from
the pinned `Arch_Config` repository are installed with `ya pkg install`
using the original `package.toml`. The `init.lua`, keymap and theme are
restored from Arch. The ripgrep/fzf shortcut helper is included.

Native KWin tiling is used. Polonium and other automatic tiling scripts are **not** installed by this repository. System package dependencies and Nordic appearance assets remain managed by the existing setup scripts.

Existing user-installed application extensions are not removed.

KiCad StepUp is a FreeCAD workbench; it is NOT automatically installed or given
an extra Application Launcher entry. The KDE launcher snapshot workflow is
in `../docs/reinstall-2026.md` and `../backups/application-launcher/README.md`.
