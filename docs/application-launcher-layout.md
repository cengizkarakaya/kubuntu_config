# KDE Application Launcher — suggested category layout

Example categories for a scientific workstation, not a record of installed applications. Capture actual personal menu files privately using `scripts/menu-backup.sh`.

| Category | Examples |
| --- | --- |
| Science and mathematics | Solvers, plotting and numerical tools |
| Astronomy | Sky maps and simulators |
| Engineering and electronics | CAD, EDA and circuit simulation |
| Robotics | Robot simulation and development tools |
| Development | Editors, terminals and debugging tools |

Use KDE Menu Editor to organize applications that are actually installed. Compare desktop IDs and Exec commands before hiding duplicates. Do not uninstall software just to reorganize the menu. Keep the actual category layout in private recovery storage.

## Optional astronomy simulators

An Astronomy submenu can contain Stellarium and KStars. The opt-in
`scripts/install-astronomy-launchers.py --check | --install` discovers
installed Celestia, Gaia Sky and OpenSpace and inserts only their available
desktop IDs into **the existing root Astronomy menu**. The live KMenuEdit
file is privately backed up before modification; this is not an automatic
bootstrap step. See `docs/astronomy-simulators.md` for safe installation
channels, source-build caveats and launcher verification.


## Optional ROS 2 launchers

A root Robotics group may contain Webots. The **opt-in** `scripts/install-ros2-launchers.py` adds eight
entries: ROS 2 Development (Terminal), ROS 2 GUI — Start / Refresh,
RViz2, rqt, rqt Graph, rqt Console, rqt Image View, and PlotJuggler.
The script checks the actual live menu, preserves Webots and makes a
private backup before updating. It is not run automatically and must
not be confused with installation of the applications themselves.

Full installer guide: `docs/ros2-gui-launchers.md`.

## Portable private snapshots

Capture with `bash scripts/menu-backup.sh --capture`, then prepare a separate
private portable copy with `--prepare-private`. The latter converts the source
HOME path into the literal marker `@HOME@`; this is not anonymization.
Keep both directories outside Git and include them in reviewed encrypted
backups. See [private menu recovery](../backups/application-launcher/README.md).
Preview with `--plan-restore`; `--restore` requires typed confirmation and
backs up conflicts. Executables and icons must exist on the target workstation.
A real KDE launcher test is still necessary.
