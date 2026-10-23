# Nord appearance contract

Arch_Config reference: commit 56c882afbd385a905b419193aa72520a688d56ea.
Background #20242C, cyan #88C0D0, blue #81A1C1, FiraCode Nerd Font 10,
Nordic GTK, Nordzy-dark icons.

Installed automatically (these are appearance assets, not application add-ons):
- Native KDE color palette in themes/KubuntuNord.colors
- Latest stable SHA-256-checked FiraCode Nerd Font (resolved when installed)
- Nordic GTK theme from pinned revision; no upstream installer execution
- Nordzy-dark SVG icon theme from pinned revision; no upstream installer execution

The Nordzy cursor and full third-party Plasma shell theme are deliberately
not installed; use built-in Breeze cursor/Plasma panel until manually reviewed.
The old Kröhnkite 5px tiling gap is NOT automatically ported: Polonium 1.2.1
uses its own layout and the repo does not invent unsupported configuration keys.

Yazi's pinned Arch_Config Nord flavor and 10 plugins are installed via
scripts/install-yazi-plugins.sh. Other optional application plugins are not.
Sources: https://github.com/EliverLara/Nordic
https://github.com/MolassesLover/Nordzy-icon
https://github.com/ryanoasis/nerd-fonts/releases/tag/v3.5.1
