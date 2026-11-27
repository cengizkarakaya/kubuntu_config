# Astronomy: Celestia, Gaia Sky and OpenSpace on Kubuntu 26.10

This is a **separate, opt-in** scientific visualization profile. It is not
part of the core `bootstrap.sh`, `--with-science`, `sysup`, or automatic
NVIDIA updates. All commands below run as the **desktop user**. Do not run the
scripts with `sudo`; they request sudo only for signed Ubuntu APT operations.

## Exact version / channel status (checked 14 November 2026)

| Application | Installation choice | Limitations |
| --- | --- | --- |
| Gaia Sky | Maintained user Flatpak, `space.gaiasky.GaiaSky` | Flathub had v3.8.0 when checked; developer offers v3.9.2 (27 October 2026). The installer tracks Flathub stable, NOT necessarily the newest upstream release. |
| Celestia | Official tagged **stable 1.6.4** source, built locally with GLUT | Stable release is older and its GLUT interface is limited. Celestia 1.7 Qt6 builds/OBS AppImage are development/experimental; intentionally not auto-installed or mixed into the 26.10 APT sources. |
| OpenSpace | Official stable **releases/v0.22.1** source, built locally | Official stable Linux binary is not published. Pinned 0.22.1 build requires CMake >=4, GCC >=13, Qt >=6.8, GDAL and OpenGL 4.6, many libraries, >30 GiB free. Kubuntu 26.10 has not been verified locally. This build has NOT been verified on the target machine. |

Sources:
- [Gaia Sky official downloads](https://gaiasky.space/downloads/)
- [Gaia Sky Flatpak installation](https://gaia.ari.uni-heidelberg.de/gaiasky/docs/master/Installation.html)
- [Celestia official Linux install guide](https://github.com/CelestiaProject/Celestia/blob/master/INSTALL.md)
- [Celestia GitHub stable releases](https://github.com/CelestiaProject/Celestia/releases)
- [OpenSpace release source](https://github.com/OpenSpace/OpenSpace/releases)
- [OpenSpace v0.22 Linux build requirements](https://docs.openspaceproject.com/releases-v0.22/contribute/development/compiling/)
- [OpenSpace latest/master requirements (different dependency channel)](https://docs.openspaceproject.com/latest/contribute/development/compiling/index.html)

## 1. Gaia Sky — recommended first

```bash
cd ~/kubuntu_config
bash scripts/install-astronomy-gaia.sh --plan
bash scripts/install-astronomy-gaia.sh --install
flatpak run space.gaiasky.GaiaSky
```

Gaia Sky itself downloads **astronomical datasets on first use**. Catalogs can
be large; storage requirements depend on the selections. The Flatpak automatically
exports a `.desktop` file, so the Astronomy launcher integration references that
existing ID instead of creating a duplicate launcher.

For the vendor's newer 3.9.x packages, review the official downloads, package
signatures, update behavior and the existing Flatpak before changing distribution
channel. This repository deliberately does not silently replace Flatpak with DEB.

## 2. Celestia — conservative stable build

```bash
cd ~/kubuntu_config
bash scripts/build-celestia-stable.sh --plan
bash scripts/build-celestia-stable.sh --build
```

The source is pinned to upstream tag `1.6.4` and installed only within
`~/.local/opt/celestia-stable/` (no `sudo make install`). This is the
stable **GLUT** version; it does **not** offer the contemporary Qt6 interface.
The script simulates APT installation without removals, aborting on dependency
conflicts. It explicitly installs **gettext** and **autopoint**: Celestia's
legacy `configure.ac` requires their `AM_PO_SUBDIRS` and `AM_GNU_GETTEXT`
macros. The installer also installs **liblua5.3-dev** from the signed Ubuntu
repository and verifies `lua.hpp` through the compiler using
`pkg-config --cflags lua5.3` before invoking Autotools. The
`--with-lua` configure flag explicitly retains CELX (.celx) scripting,
rather than disabling Lua to avoid compile errors.
Its Git checkout is verified against the pinned source commit.
To recover safely from failed prior `autoreconf` attempts, it exports a clean
copy of the tagged files via `git archive` to a temporary build directory.
Before running Autotools, the script applies a narrow, verified fix to the
**temporary copy** of Celestia 1.6.4's legacy `KDE_CHECK_QT_JPEG` macro in
`acinclude.m4`: a misplaced `fi` inside `AC_CACHE_VAL` causes generated
`configure` syntax errors with modern Autoconf 2.72/2.73. The patch is
guarded by an exact macro-pattern match and fails closed if upstream sources
change. The generated `configure` undergoes `sh -n` validation before it
is executed; an invalid file leaves the build directory intact for diagnosis.
It **does not** run `git clean` or `git reset` on the original checkout,
and preserves failed temporary builds for investigation. It does not add OBS
repositories. Compilation on 26.10 remains to be verified against the actual
NVIDIA/OpenGL setup.

**Future option, not automated:** The Celestia maintainers offer
[experimental 1.7 Qt6 AppImages](https://github.com/CelestiaProject/Celestia/blob/master/INSTALL.md)
from openSUSE Build Service. If the user separately chooses the experimental
channel after testing and verifying its provenance, save the executable at
`~/.local/opt/celestia/Celestia.AppImage` and mark it executable. The
KDE launcher installer recognizes this path, but intentionally does not
download experimental builds.

## 3. OpenSpace — advanced native source build

```bash
cd ~/kubuntu_config
bash scripts/build-openspace.sh --plan
bash scripts/build-openspace.sh --check-apt  # APT simülasyonu: paket değiştirmez
bash scripts/build-openspace.sh --build
```

The script checks at least 30 GiB free space and the **existing CMake
(>=4.0) and GCC (>=13)** *before installing any APT packages*. It simulates
APT changes without removals, installs official Ubuntu `qt6-base-dev`,
`libgdal-dev` and the other dependencies documented for **OpenSpace 0.22**,
then validates **Qt6Core >=6.8** and GDAL through pkg-config *before* cloning
large submodules. It clones the official stable tag `releases/v0.22.1`
with submodules and builds in `~/.local/opt/openspace/build`, expecting
`~/.local/opt/openspace/bin/OpenSpace`.

**Do not mix documentation channels:** The newer `latest` OpenSpace guide
requires GCC >=15 and uses vcpkg/presets, while the pinned 0.22.1 source
tree still uses Git submodules and the 0.22-specific Qt/GDAL requirements.
Version numbers above are tailored to the **pinned tag**, not to master.

### Kubuntu 26.10 JACK2 dependency conflict (15 November 2026)

On the user's Kubuntu 26.10 host, a first `--build` attempt stopped safely
during APT simulation: `libmpv-dev` depends on virtual `libjack-dev`.
APT picked the JACK1 development package `libjack-dev` and proposed removing
both installed `libjack-jackd2-0` (amd64) and `libjack-jackd2-0:i386` to
replace them with `libjack0` and `libjack0:i386`.

OpenSpace's installer now **explicitly requests `libjack-jackd2-dev`**, which
also satisfies the virtual JACK development dependency while remaining
compatible with existing JACK2 runtime libraries. This avoids deliberately
replacing either the native or the 32-bit JACK library. APT's
`--no-remove` protection remains mandatory.

**Always run `bash scripts/build-openspace.sh --check-apt` before `--build`
on this workstation**. The check simulates the entire APT transaction
without root privileges or package changes and fails if removal would still
be required. If it fails, keep the current audio packages and inspect
the complete solver output; **do not use `--allow-remove-essential`,
`--force-yes`, `apt autoremove` or manual JACK1 replacement**.

### GDAL 3.13 C++ compatibility and incremental resume (15 November 2026)

The user's Kubuntu 26.10/OpenSpace v0.22.1 source build reached Ninja step
`[4550/5534]` and failed in `modules/globebrowsing/globebrowsingmodule.cpp`
because current GDAL 3.13 returns `CSLConstList` (`const char* const*`)
from `GDALGetMetadata`, whereas the pinned source declared `char**`.
The local `parseSubDatasets(char**, ...)` parameter also needs to accept
the const-qualified string list.

A narrowly scoped, source-verified compatibility patch is now applied
to this exact OpenSpace tagged checkout by
`scripts/patch-openspace-gdal.py`:
- Convert the `GDALGetMetadata` result to `const char* const*`.
- Convert `parseSubDatasets` argument to `const char* const*`.
- **Do not use `-fpermissive`**, cast away const, or downgrade GDAL.
- Refuse to overwrite any unexpected changes **to the targeted GDAL source
  file**, including staged changes to that file.
- Preserve and **ignore unrelated tracked changes** in the OpenSpace checkout
  (CMake/code generation can modify other tracked files during normal builds).
  The patch does not reset, remove, stage, or overwrite those files.
- Permit this exact same patch on subsequent runs without overwriting it.

The patch intentionally modifies only that one tracked source file within
`~/.local/opt/openspace`; this is expected and does **not** affect
`kubuntu_config` itself. The build script recognizes the approved change
on rerun. It does not run `git reset` or `git clean`.

**Update 15 November 2026:** The original implementation incorrectly aborted
when *other* tracked files were modified in the checkout:
`[FAIL] Other tracked source changes found; refusing patch`. This is
too strict for an in-progress OpenSpace/CMake build. The patch now checks
only its own target and leaves unrelated worktree/index changes untouched.
It still refuses to overwrite the GDAL source if that file differs from the
exact upstream or approved patched content.

**For an existing, partially built source checkout**, after updating the
`kubuntu_config` repo and confirming `build/build.ninja` exists:

```bash
cd ~/kubuntu_config
bash scripts/build-openspace.sh --resume
```

`--resume` checks disk space, existing CMake/GCC/Qt/GDAL support, source
tag and patch integrity, then invokes only the existing Ninja build. It
skips sudo/APT, Git cloning/submodule updates, and CMake reconfiguration.
Ninja recompiles the changed target and builds the remaining objects
incrementally; other, already compiled objects are retained. More
unrelated compilation errors are possible and should be diagnosed from the
new log, without wiping the existing build directory.

**Important:** OpenSpace's large dependency graph and build flow may be
incompatible with Kubuntu 26.10; do not consider the installation complete until
the executable runs and shows its Launcher. Upstream requires a recent compiler
and CMake; no third-party compiler repositories, prerelease binaries or nightly
releases are used. Downloaded datasets add ~10+ GiB after compilation.

If compilation fails, keep the output and investigate that exact error; do not
force an APT upgrade or swap the graphics driver. The published third-party
OpenSpace-AppImage daily builds are **not** substituted automatically.

## 4. Put the installed apps in the existing KDE Astronomy submenu

The host's KMenuEdit tree already contains:
`Astronomy → Stellarium, KStars`.

Run **after** installing each application:

```bash
cd ~/kubuntu_config
python3 scripts/install-astronomy-launchers.py --check
python3 scripts/install-astronomy-launchers.py --install
kbuildsycoca6 --noincremental
```

The launcher script:
- Detects Gaia Sky's existing user Flatpak desktop ID, rather than duplicating it.
- Detects the stable Celestia binary, an existing `celestia` in `PATH`,
  or a manually approved AppImage at the documented location.
- Detects OpenSpace only when `~/.local/opt/openspace/bin/OpenSpace` is executable.
- **Creates no fake desktop entries** for software that is not actually installed.
- Only changes the existing root Astronomy `Include` and `Layout` sections
  in the live `~/.config/menus/applications-kmenuedit.menu`.
- Preserves KStars, Stellarium, Webots and unrelated menu categories.
- Stores a private, timestamped pre-edit backup under
  `~/.local/state/kubuntu-config/astronomy-menu-before-*/`.
- Refuses to overwrite a modified launcher or a non-matching KMenuEdit menu.
- Is safe to rerun (idempotent). It does not publish private menu data to GitHub.

Verify after installation:

```bash
flatpak info --user space.gaiasky.GaiaSky
test -x ~/.local/opt/celestia-stable/bin/celestia && echo 'Celestia binary ready'
test -x ~/.local/opt/openspace/bin/OpenSpace && echo 'OpenSpace binary ready'
gio launch ~/.local/share/applications/kubuntu-astronomy-celestia.desktop
gio launch ~/.local/share/applications/kubuntu-astronomy-openspace.desktop
```

The last two `gio launch` commands require the corresponding program to be
installed and menu launcher to have been created; otherwise they fail normally.
Graphical behavior must be checked interactively in KDE Wayland.

## Source control and reproducibility boundaries

The repository tracks **scripts, stable tags, installed-file conventions and
menu logic**; it does **not** commit built executables, Flatpak cache, large
astronomical datasets or copies of private live KDE menus.

The optional astronomy profile is intentionally separate from default core
bootstrap. It must be invoked explicitly on each newly installed workstation.
After a successful install, capture a private application launcher snapshot with
`bash scripts/menu-backup.sh --capture`. Do not publish it without reviewing
all menu contents, since this repository is public.

If the local `kubuntu_config` worktree has uncommitted files, do not switch
branches or pull until they are reviewed and saved.
