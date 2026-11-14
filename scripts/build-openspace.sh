#!/usr/bin/env bash
# Optional OpenSpace stable source build. No nightly binaries or untrusted PPAs.
# This build is complex, experimental on Kubuntu 26.10; run --plan first.
set -Eeuo pipefail
mode="${1:---plan}"
case "$mode" in --plan|--build) ;; *)
  echo "Usage: bash $0 --plan | --build" >&2; exit 2 ;;
esac
(( EUID != 0 )) || { echo 'Run as the regular user, never as root.' >&2; exit 2; }
TAG='releases/v0.22.1'
DEST="$HOME/.local/opt/openspace"
packages=(
  cmake build-essential git ninja-build curl zip unzip
  autoconf autoconf-archive automake libtool python3 bison flex pkg-config
  rpm dpkg perl
  libx11-xcb-dev libglu1-mesa-dev libxrender-dev libxi-dev
  libxkbcommon-dev libxkbcommon-x11-dev libwayland-dev wayland-protocols
  libx11-dev libxext-dev libxfixes-dev libxcb1-dev libxcb-glx0-dev
  libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev
  libxcb-xinput-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb-shape0-dev
  libxcb-randr0-dev libxcb-render-util0-dev libxcb-util-dev libxcb-xinerama0-dev
  libxcb-xkb-dev libxcb-cursor-dev libegl-dev libgl-dev libdbus-1-dev
  libatspi2.0-dev libxrandr-dev libxxf86vm-dev libxinerama-dev
  libxcursor-dev libmpv-dev libnss3 libnspr4
)
echo "OpenSpace stable $TAG -> $DEST"
echo 'Source: https://github.com/OpenSpace/OpenSpace'
echo 'Requires CMake >=4.0, GCC >=15, OpenGL 4.6, >=30 GiB free disk space.'
echo 'The vendor documents builds on Ubuntu 26.04, NOT yet Kubuntu 26.10.'
echo 'It will download third-party build dependencies via upstream build scripts.'
if [[ "$mode" == --plan ]]; then
  command -v cmake >/dev/null && cmake --version | head -n 1 || true
  command -v g++ >/dev/null && g++ -dumpfullversion || true
  df -h "$HOME" | tail -n 1
  printf 'APT prerequisites: %s\n' "${packages[*]}"
  echo 'Dry-run: no packages downloaded or installed.'
  echo 'To attempt a source build: bash scripts/build-openspace.sh --build'
  exit 0
fi

# Preflight prevents creating a partial installation unnecessarily.
free_kb="$(df -Pk "$HOME" | awk 'NR==2 {print $4}')"
[[ "$free_kb" =~ ^[0-9]+$ ]] && ((free_kb > 30 * 1024 * 1024)) || {
  echo '[FAIL] 30 GiB free space required for source build + dataset headroom.' >&2; exit 1;
}
if [[ -e "$DEST" && ! -d "$DEST/.git" ]]; then
  echo "[FAIL] Existing path not a Git checkout: $DEST" >&2; exit 1
fi
sudo apt-get update
apt-get -s install --no-remove --no-install-recommends "${packages[@]}" || {
  echo '[FAIL] APT simulation failed; nothing installed by this script.' >&2; exit 1;
}
sudo apt-get install -y --no-remove --no-install-recommends "${packages[@]}"
cmake_version="$(cmake --version | awk 'NR==1 {print $3}')"
gcc_version="$(g++ -dumpfullversion | cut -d. -f1)"
dpkg --compare-versions "$cmake_version" ge 4.0 || {
  echo '[FAIL] CMake 4.0+ needed; no unsupported CMake update attempted.' >&2; exit 1;
}
((gcc_version >= 15)) || {
  echo '[FAIL] GCC 15+ needed; no unapproved compiler repository added.' >&2; exit 1;
}
if [[ ! -d "$DEST/.git" ]]; then
  git clone --recursive --branch "$TAG" --single-branch \
    https://github.com/OpenSpace/OpenSpace.git "$DEST"
else
  [[ "$(git -C "$DEST" describe --tags --exact-match HEAD)" == "$TAG" ]] || {
    echo '[FAIL] Existing checkout is not the pinned stable tag.' >&2; exit 1;
  }
  git -C "$DEST" diff --quiet && git -C "$DEST" diff --cached --quiet || {
    echo '[FAIL] Existing OpenSpace checkout has local changes.' >&2; exit 1;
  }
  git -C "$DEST" submodule update --init --recursive
fi
cmake -S "$DEST" -B "$DEST/build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DOPENSPACE_HAVE_TESTS=OFF
cmake --build "$DEST/build" --parallel "${OPENSPACE_BUILD_JOBS:-6}"
test -x "$DEST/bin/OpenSpace" || {
  echo '[FAIL] OpenSpace executable was not generated in bin/OpenSpace.' >&2; exit 1;
}
echo '[OK] OpenSpace binary compiled. Integrate KDE launcher with:'
echo 'python3 scripts/install-astronomy-launchers.py --install'
echo '[WARN] Real OpenGL/UI launch and dataset download still need host verification.'
