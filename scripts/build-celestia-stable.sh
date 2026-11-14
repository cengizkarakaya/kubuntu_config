#!/usr/bin/env bash
# Optional, pinned source build of the last tagged stable Celestia (1.6.4).
# This legacy release uses GLUT rather than the experimental Celestia 1.7 Qt GUI.
set -Eeuo pipefail
mode="${1:---plan}"
case "$mode" in --plan|--build) ;; *)
  echo "Usage: bash $0 --plan | --build" >&2; exit 2 ;;
esac
(( EUID != 0 )) || { echo 'Never run this installer as root.' >&2; exit 2; }

TAG=1.6.4
SOURCE="$HOME/.local/opt/celestia-source-1.6.4"
PREFIX="$HOME/.local/opt/celestia-stable"
packages=(
  build-essential git autoconf automake libtool pkg-config
  freeglut3-dev libglu1-mesa-dev libgl-dev libpng-dev libjpeg-dev
)
# Package alternatives differ across Ubuntu releases; validate on the machine.
echo "Celestia $TAG (official stable source; GLUT UI)."
printf 'Source: %s\nPrefix: %s\n' "$SOURCE" "$PREFIX"
printf 'Required APT packages: %s\n' "${packages[*]}"
if [[ "$mode" == --plan ]]; then
  echo 'Dry-run: no software or packages installed.'
  echo 'Check availability: apt-cache policy freeglut3-dev'
  echo 'Then explicitly run: bash scripts/build-celestia-stable.sh --build'
  exit 0
fi
sudo apt-get update
apt-get -s install --no-remove --no-install-recommends "${packages[@]}" || {
  echo '[FAIL] APT simulation failed; no packages installed.' >&2; exit 1;
}
sudo apt-get install -y --no-remove --no-install-recommends "${packages[@]}"
mkdir -p "$(dirname "$SOURCE")"
if [[ -e "$SOURCE" && ! -d "$SOURCE/.git" ]]; then
  echo "[FAIL] Source path already occupied: $SOURCE" >&2; exit 1
fi
if [[ ! -d "$SOURCE/.git" ]]; then
  git clone --depth 1 --branch "$TAG" https://github.com/CelestiaProject/Celestia.git "$SOURCE"
else
  [[ "$(git -C "$SOURCE" describe --exact-match --tags HEAD)" == "$TAG" ]] || {
    echo '[FAIL] Existing source is not pinned at the stable tag.' >&2; exit 1;
  }
  git -C "$SOURCE" diff --quiet && git -C "$SOURCE" diff --cached --quiet || {
    echo '[FAIL] Existing source has modifications. Refusing to build it.' >&2; exit 1;
  }
fi
cd "$SOURCE"
libtoolize --copy --force
autoreconf -fi
./configure --prefix="$PREFIX" --with-glut
make -j "${CELESTIA_BUILD_JOBS:-4}"
make install
test -x "$PREFIX/bin/celestia" || {
  echo "[FAIL] Expected binary missing: $PREFIX/bin/celestia" >&2; exit 1;
}
echo "[OK] Built $PREFIX/bin/celestia. Register in menu using:"
echo 'python3 scripts/install-astronomy-launchers.py --install'
echo '[WARN] Real GUI/OpenGL operation has not been tested by this script.'
