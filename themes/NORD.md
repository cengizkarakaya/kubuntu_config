# Nord theme contract

From Arch_Config at commit 56c882afbd385a905b419193aa72520a688d56ea:
background #20242C, cyan #88C0D0, blue #81A1C1, FiraCode Nerd Font 10,
Nordic GTK, Nordzy-dark icons, Nordzy-cursors-white and 5/20px tiling gaps.

Installed automatically:
- Auditable KDE/Qt6 color-scheme themes/KubuntuNord.colors
- Nerd Fonts FiraCode v3.5.1 with pinned SHA-256, placed under user font directory
- Nordic GTK pinned revision, installed by git archive (no untrusted install scripts)
- KDE native color and font keys; regular KWin compositor (no extra effect package)
- Pinned Nordzy-dark SVG icons, installed locally without running upstream installer

Not automatically installed:
- Nordzy cursor and third-party Plasma global theme from KDE Store:
  compatibility and installer payload must be reviewed before activation.
  Fallback for the cursor is KDE's built-in Breeze cursor; Nordzy-dark icons are installed separately.
- Global Plasma theme, panel layout, monitor positioning: manage with KDE Settings.
  Never symlink ~/.config/plasmashellrc, kscreen profiles or plasma-org.kde.plasma.desktop-appletsrc.

Sources: https://github.com/EliverLara/Nordic
https://github.com/MolassesLover/Nordzy-icon
https://github.com/ryanoasis/nerd-fonts/releases/tag/v3.5.1
