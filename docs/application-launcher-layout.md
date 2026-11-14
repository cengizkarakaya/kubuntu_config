# KDE Application Launcher — observed layout (14 Nov 2026)

Human-readable transcription of the provided KMenuEdit screenshots. This is **not** the real .menu/.desktop backup; for exact restoration capture files on the original PC using `scripts/menu-backup.sh`.

| Category | Visible applications and groups |
| --- | --- |
| Physics | Quantum ESPRESSO (Terminal), LAMMPS (Terminal), openEMS (Python Terminal), GNU Radio Companion, ElmerGUI, CalculiX, CalculiX GraphiX, AppCSXCAD, OMEdit, OMNotebook, OMShell, OMShell-terminal, Gmsh |
| Mathematics | GNU Octave, Cantor, Qalculate!, FEniCSx (Python Terminal), ParaView, GeoGebra Classic 6, SageMath (Terminal), LabPlot, LibreOffice Math |
| Astronomy | Stellarium, KStars |
| Engineering | FreeCAD, OrcaSlicer, LibreOffice Draw, MeshLab |
| Coding | sigrok-cli, VS Code URL Handler, Helix (terminal), VS Code, Alacritty, Konsole, Cool Retro Term, Wireshark, Kate |
| Robotics | Webots |
| Electronics | KiCad submenu, QElectroTech-2, Qucs-S, PulseView, sigrok-cli, QElectroTech, SimulIDE, Arduino IDE |
| Scientific Visualization & GIS | QGIS |
| Education | Calibre, Zotero, E-book editor, E-book viewer |
| Graphics | Kdenlive, Blender, GIMP, Inkscape, Krita, Gwenview, ImageMagick |
| Internet | Bluetooth tools, KDE Connect, Remmina, Firefox, Brave, pCloud, LocalSend, NeoChat, qBittorrent, Thunderbird, Cloudflare WARP and more |
| Multimedia | VLC, Strawberry, HandBrake, Haruna, mpv |
| Office | Obsidian, Okular, LibreOffice applications, Skanpage, LRF viewer, TeXInfo/TeXdoctk |
| System / Utilities | KDE configuration, Discover, system diagnostic utilities, Ark, Filelight, Kate, KCalc, KeePassXC, KRename, Spectacle and more |

KiCad submenu already contains: KiCad, Schematic Editor (Standalone), PCB Editor (Standalone), PCB Calculator, Image Converter, Gerber Viewer. StepUp belongs inside **FreeCAD**, not as a new launcher.

## Optional category cleanup (NOT automatically applied)

- ParaView: Mathematics -> Scientific Visualization & GIS.
- Gmsh, ElmerGUI and CalculiX: Physics -> Engineering.
- GNU Radio Companion: Physics -> Electronics.
- Wireshark: Coding -> Internet (optional; Coding is also reasonable for protocol development).
- LibreOffice Math: keep Office entry; remove or hide redundant Mathematics entry only if it is really a duplicate.
- LibreOffice Draw: keep Office entry, hide redundant Engineering entry only after comparing launcher commands.
- Investigate QElectroTech / QElectroTech-2 and duplicate Discover/Software Sources before hiding: names alone do NOT prove the actions are identical.
- CLI utilities such as sigrok-cli can be hidden from the menu if they are normally invoked in Alacritty.

**Do not remove installed software to clean a menu.** Use KDE Menu Editor's hide/visibility setting and compare Exec/desktop IDs first. The backup tool records the user's actual launcher files and menu structures; the markdown is an independent recovery reference if the exact export was missed.
