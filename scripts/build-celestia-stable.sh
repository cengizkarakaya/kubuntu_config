#!/usr/bin/env bash
# Optional, pinned source build of stable Celestia 1.6.4 (GLUT).
# Keeps upstream checkout untouched: failed Autotools builds do not corrupt it.
set -Eeuo pipefail

mode="${1:---plan}"
case "$mode" in
  --plan|--build) ;;
  *) echo "Usage: bash $0 --plan | --build" >&2; exit 2 ;;
esac
(( EUID != 0 )) || { echo 'Never run this installer as root.' >&2; exit 2; }

TAG=1.6.4
# Upstream source revision verified from the official tagged checkout.
SOURCE_COMMIT=315b2d798496898c69240ec68e2059bd7d8c246e
SOURCE="$HOME/.local/opt/celestia-source-$TAG"
PREFIX="$HOME/.local/opt/celestia-stable"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/kubuntu-config"
packages=(
  build-essential git autoconf automake libtool pkg-config
  gettext autopoint
  freeglut3-dev libglu1-mesa-dev libgl-dev libpng-dev libjpeg-dev
)

echo "Celestia $TAG (official stable source; GLUT UI)."
printf 'Source: %s\nPrefix: %s\n' "$SOURCE" "$PREFIX"
printf 'Required APT packages: %s\n' "${packages[*]}"
if [[ "$mode" == --plan ]]; then
  echo 'Dry-run: no software, packages or source files changed.'
  echo 'This version uses gettext/autopoint for AM_PO_SUBDIRS and AM_GNU_GETTEXT.'
  echo 'Generated Autotools files will be isolated in a new temporary build tree.'
  echo 'Check packages: apt-cache policy gettext autopoint freeglut3-dev'
  echo 'To build: bash scripts/build-celestia-stable.sh --build'
  exit 0
fi

# Check all packages with APT before installing any of them. Never remove others.
sudo apt-get update
apt-get -s install --no-remove --no-install-recommends "${packages[@]}" || {
  echo '[FAIL] APT simulation failed; no packages installed by this script.' >&2
  exit 1
}
sudo apt-get install -y --no-remove --no-install-recommends "${packages[@]}"

# Preserve any generated files left in SOURCE by previous attempts. Only read
# the committed upstream tree via git archive; never git clean/reset it.
mkdir -p "$(dirname "$SOURCE")"
if [[ -e "$SOURCE" && ! -d "$SOURCE/.git" ]]; then
  echo "[FAIL] Source path is occupied but is not a Git checkout: $SOURCE" >&2
  exit 1
fi
if [[ ! -d "$SOURCE/.git" ]]; then
  git clone --depth 1 --branch "$TAG" \
    https://github.com/CelestiaProject/Celestia.git "$SOURCE"
fi
actual_commit="$(git -C "$SOURCE" rev-parse HEAD)"
tag_commit="$(git -C "$SOURCE" rev-parse "$TAG^{commit}")"
if [[ "$actual_commit" != "$SOURCE_COMMIT" || "$tag_commit" != "$SOURCE_COMMIT" ]]; then
  echo '[FAIL] Celestia checkout does not match the verified stable release commit.' >&2
  echo "       Expected: $SOURCE_COMMIT" >&2
  echo "       HEAD:     $actual_commit; tag: $tag_commit" >&2
  exit 1
fi

mkdir -p "$CACHE"
BUILD="$(mktemp -d "$CACHE/celestia-$TAG-build.XXXXXXXX")"
cleanup() {
  rc=$?
  trap - EXIT
  if (( rc == 0 )); then
    rm -rf -- "$BUILD"
  else
    echo "[FAIL] Celestia build ended with exit code $rc." >&2
    echo "       Build directory retained for troubleshooting: $BUILD" >&2
    echo "       Upstream source checkout was not modified." >&2
  fi
  exit "$rc"
}
trap cleanup EXIT

# Export only Git-tracked files from the verified upstream tag. Autoreconf,
# libtoolize and configure operate on the throwaway copy, not SOURCE.
git -C "$SOURCE" archive --format=tar "$TAG" | tar -xf - -C "$BUILD"
cd "$BUILD"
libtoolize --copy --force
autoreconf -fi
./configure --prefix="$PREFIX" --with-glut
make -j "${CELESTIA_BUILD_JOBS:-4}"
make install

if [[ ! -x "$PREFIX/bin/celestia" ]]; then
  echo "[FAIL] Compiled executable missing: $PREFIX/bin/celestia" >&2
  exit 1
fi
echo "[OK] Installed $PREFIX/bin/celestia"
echo 'Run: ~/.local/opt/celestia-stable/bin/celestia'
echo 'Then: python3 scripts/install-astronomy-launchers.py --check'
echo '      python3 scripts/install-astronomy-launchers.py --install'
echo '[WARN] Real GUI/OpenGL operation still requires a host test.'
