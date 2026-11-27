# Scientific software and KDE Application Launcher

The general bootstrap does not compile or reinstall optional large scientific applications. Use the curated package manifests and [build guidance](../builds/README.md) for installation; keep the actual installed versions and prefixes in private inventory.

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

Depending on installed software, the managed user launchers and wrappers can include:

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

Validate TryExec, application launch and menu visibility separately on each machine. Use `gio launch`; do not assume `kioclient6` is installed.

If the entries exist but do not appear, first run `kbuildsycoca6
--noincremental` and search in KRunner / KDE Application Launcher. Do not
reset Plasma, replace NVIDIA drivers, or delete unrelated menu entries to fix
this issue.

## Reproducibility boundaries

1. Install the actual scientific software **before** generating launchers.
   Absent executables are reported as missing.
2. Native APT / Flatpak applications usually provide their own launcher.
3. Elmer, openEMS, Webots, SageMath and FEniCSx may require separate manual build or Conda steps. See [build guidance](../builds/README.md) and [Conda recovery](../conda/README.md). Keep actual build records and full locks privately.
4. GPU and numerical validation are separate from menu visibility. In
   particular, openEMS/Elmer numerical workflows need application-level tests.

To migrate to a new machine with changed installation directories, update the
corresponding wrapper assumptions in
`scripts/setup-scientific-launchers.sh` after the new software is installed.

## Optional science profile

Use `packages/science-apt.txt` via `scripts/install-science.sh --plan` and `--install` for Ubuntu-signed packages. KiCad 3D models remain separately opt-in. See [category suggestions](application-launcher-layout.md) and [private menu recovery](../backups/application-launcher/README.md). Never stage the actual menu snapshot.
