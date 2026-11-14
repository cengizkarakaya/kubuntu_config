# Scientific software and KDE Application Launcher

This workstation has a separately maintained scientific/engineering stack. The
general `bootstrap.sh` deliberately does **not** compile or reinstall these
large, manually managed applications. This document records the verified
workstation inventory and restores the user-level KDE launchers where possible.

## Workstation inventory (12 November 2026)

| Application | Observed installation / launcher source | Interface |
| --- | --- | --- |
| LabPlot | APT, included in `packages/apt.txt` | Native GUI |
| Cantor | APT, included in `packages/apt.txt` | Native GUI |
| ParaView 6.1.1 | Installed system command / desktop entry | GUI, OpenGL |
| GNU Radio 3.10.12 | Installed system command / desktop entry | GNU Radio Companion GUI |
| Qalculate! Qt 5.11 | Installed system command / desktop entry | GUI |
| OpenModelica 1.27.2 | Installed OMEdit desktop entry | GUI |
| KStars | User Flatpak, `org.kde.kstars` | GUI |
| CalculiX 2.21 | Solver command (ccx) | Command line |
| CalculiX GraphiX (CGX) | `calculix-cgx`, installed on host | GUI |
| Webots R2025a | Official extracted distribution / existing desktop entry | GUI |
| Elmer FEM 26.2.1 | `~/.local/opt/elmer-26.2.1` | ElmerGUI + solver |
| openEMS 0.37.0 | `~/.local/opt/openEMS` | AppCSXCAD + Python |
| SageMath | `~/.local/opt/miniforge3/envs/sage` | Interactive terminal |
| FEniCSx 0.11.0 | `~/.local/opt/miniforge3/envs/fenicsx` | Python terminal |

The installed versions and paths above are a **host snapshot**, not upstream
latest-version guarantees, nor proof that all sample simulations have passed.

## Create / check KDE Plasma 6 launchers

Run as the desktop user, never with `sudo`:

```bash
cd ~/kubuntu_config
bash scripts/setup-scientific-launchers.sh --check
bash scripts/setup-scientific-launchers.sh --install
kbuildsycoca6 --noincremental
```

The script checks visible desktop entries under XDG user/system and Flatpak
application directories before adding anything. It does **not** overwrite
existing `.desktop` files or wrappers, install software, update drivers, or
change KWin configuration.

On the tested host, eight scientific apps already had system/Flatpak entries.
Seven managed user entries were required, with corresponding wrappers:

```text
~/.local/share/applications/kubuntu-science-cgx.desktop
~/.local/share/applications/kubuntu-science-calculix-terminal.desktop
~/.local/share/applications/kubuntu-science-elmergui.desktop
~/.local/share/applications/kubuntu-science-appcsxcad.desktop
~/.local/share/applications/kubuntu-science-sage.desktop
~/.local/share/applications/kubuntu-science-fenicsx.desktop
~/.local/share/applications/kubuntu-science-openems-python.desktop

~/.local/bin/kubuntu-science-launchers/
```

Managed `.desktop` entries use `Categories=Science;` to avoid the
`Education;Science;` duplicate-main-category hint from
`desktop-file-validate`. Existing user entries are intentionally preserved:
re-running `--install` does not rewrite any manual edits.

The specific wrapper logic matters:

- **ElmerGUI:** locates `edf/egini.xml`, exports `ELMER_HOME` and
  `ELMERGUI_HOME`, and starts via `QT_QPA_PLATFORM=xcb`.
- **AppCSXCAD:** runs via `QT_QPA_PLATFORM=xcb`.
- **SageMath / FEniCSx:** activate their separate Miniforge Conda environments.
- **openEMS Python:** uses the dedicated openEMS virtual environment.
- **CalculiX:** uses the command-line solver; CGX is a separate GUI entry.

GUI launchers cannot be manufactured for command-line-only solvers. Terminal
entries make the latter accessible from the same KDE menu without implying a
native GUI exists.

## Validate entries and diagnose missing menu items

```bash
desktop-file-validate ~/.local/share/applications/kubuntu-science-*.desktop

for desktop in ~/.local/share/applications/kubuntu-science-*.desktop; do
    [[ -f "$desktop" ]] || continue
    exec_path=$(sed -n 's/^TryExec=//p' "$desktop" | head -n 1)
    [[ -x "$exec_path" ]] && echo "OK: $desktop" || echo "MISSING: $exec_path"
done

gio launch ~/.local/share/applications/kubuntu-science-elmergui.desktop
```

On this workstation, the `TryExec` checks passed for all seven managed
entries; `gio launch` opened ElmerGUI, and the entries became visible in KDE
Application Launcher after category adjustment and cache rebuild. The command
is `gio launch`; do not assume `kioclient6` is installed.

If the entries exist but do not appear, first run `kbuildsycoca6
--noincremental` and search in KRunner / KDE Application Launcher. Do not
reset Plasma, replace NVIDIA drivers, or delete unrelated menu entries to fix
this issue.

## Reproducibility boundaries

1. Install the actual scientific software **before** generating launchers.
   Absent executables are reported as missing.
2. Native APT / Flatpak applications usually provide their own launcher.
3. Elmer, openEMS, Webots, SageMath and FEniCSx were installed using separate
   manual build/Conda steps; those exact source builds and Conda environment
   lockfiles are **not** yet encoded in this repository. The launcher script
   is not a substitute for their installation.
4. GPU and numerical validation are separate from menu visibility. In
   particular, openEMS/Elmer numerical workflows need application-level tests.

To migrate to a new machine with changed installation directories, update the
corresponding wrapper assumptions in
`scripts/setup-scientific-launchers.sh` after the new software is installed.

## Additions observed 13–14 November 2026

The category screenshots show QGIS, Octave, GeoGebra (Firefox web launcher),
Stellarium, LAMMPS, Quantum ESPRESSO, QElectroTech, PulseView, Qucs-S and
Arduino IDE. Screenshots establish menu entries, **not numerical test success**.
Quantum ESPRESSO APT packages and SSSP library were independently confirmed
installed by the user; `pw.x` was available. PulseView's Demo device was
visible. The OpenFOAM phase was deferred.

Use `packages/science-apt.txt` via `scripts/install-science.sh --plan` and
`--install` for the ordinary Ubuntu-signed packages. This profile is optional
and is not the source-build or Conda installation workflow. KStars is added to
`packages/flatpak.tsv`. KiCad 3D models are large and remain manually opt-in.

For **exact user category organization and custom shortcuts**, see
`docs/application-launcher-layout.md` and
`scripts/menu-backup.sh`. The latter captures a private snapshot locally,
which must be reviewed and committed on the actual Kubuntu machine before it
can be restored from GitHub.
