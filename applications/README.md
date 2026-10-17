# Application extension policy

No optional add-ons for Krita, GIMP, Blender, FreeCAD, KiCad, Joplin,
Thunderbird, Calibre, Kdenlive or VS Code are installed automatically.

**Exception explicitly requested:** Yazi's 10 plugins and Nord flavor from
the pinned `Arch_Config` repository are installed with `ya pkg install`
using the original `package.toml`. The `init.lua`, keymap and theme are
restored from Arch. The ripgrep/fzf shortcut helper is included.

**Polonium 1.2.1** is required for KDE tiling, not a general application
plugin. System package dependencies and Nordic appearance assets are installed.

Existing user-installed application extensions are not removed.
