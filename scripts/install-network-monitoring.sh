#!/usr/bin/env bash
# Optional, reviewed network-monitoring profile. No changes during 'plan'.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ACTION="${1:-plan}"
[[ $# -le 1 ]] || { echo 'Usage: bash scripts/install-network-monitoring.sh [plan|install|update|verify]' >&2; exit 2; }
case "$ACTION" in plan|install|update|verify) ;; *) echo "[FAIL] Unknown action: $ACTION" >&2; exit 2;; esac
(( EUID != 0 )) || { echo '[FAIL] Run as the desktop user; never sudo bash.' >&2; exit 2; }
[[ "$(uname -s)" == Linux ]] || { echo '[FAIL] Linux required' >&2; exit 2; }
[[ -r /etc/os-release ]] && source /etc/os-release
[[ "${ID:-}" == ubuntu ]] || { echo '[FAIL] This profile targets Kubuntu (Ubuntu base)' >&2; exit 2; }

verify_one() {
    local pkg="$1" bin="$2" version
    version="$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || true)"
    [[ -n "$version" ]] || { echo "[FAIL] Missing APT package: $pkg" >&2; return 1; }
    command -v "$bin" >/dev/null 2>&1 || { echo "[FAIL] Missing executable: $bin" >&2; return 1; }
    echo "[OK] $pkg $version ($(command -v "$bin"))"
    if command -v getcap >/dev/null 2>&1; then
        local capability
        capability="$(getcap "$(command -v "$bin")" 2>/dev/null || true)"
        if [[ "$capability" == *cap_net_raw* ]]; then
            echo "[OK] $bin capture capability: $capability"
        else
            echo "[WARN] $bin: CAP_NET_RAW not present; capture may require explicit permission configuration."
        fi
    fi
}

case "$ACTION" in
    plan)
        cat <<'PLAN'
Network monitoring (OPTIONAL, not part of bootstrap):
  - iperf3: official Ubuntu APT repository
  - Sniffnet: official latest stable GitHub Linux .deb, SHA-256 verified
  - RustNet: official latest stable GitHub Linux .deb, SHA-256 verified
  - NetAlertX: official GHCR image via Docker Compose, host networking,
               persistent named volume and localhost-bound web UI
No third-party APT repository, Docker group membership or system settings change.
PLAN
        echo 'To install: bash scripts/install-network-monitoring.sh install'
        exit 0
        ;;
    verify)
        dpkg-query -W -f='${Version}\n' iperf3
        command -v iperf3 >/dev/null
        verify_one sniffnet sniffnet
        verify_one rustnet-monitor rustnet
        bash "$ROOT/scripts/netalertx.sh" check
        exit 0
        ;;
esac

case "$(dpkg --print-architecture)" in
    amd64) arch=amd64 ;;
    arm64) arch=arm64 ;;
    *) echo '[FAIL] Only amd64/arm64 are supported by this optional profile' >&2; exit 2 ;;
esac
for cmd in curl sha256sum dpkg-deb apt-get sudo python3; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "[FAIL] Missing dependency: $cmd" >&2; exit 1; }
done
sudo -v
echo '==> Installing/updating iperf3 and Linux capability tools from Ubuntu APT'
sudo apt-get update
sudo apt-get install -y --no-remove --no-install-recommends iperf3 libcap2-bin

work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT

install_official_deb() {
    local repo="$1" asset="$2" package="$3" tag url digest version installed file
    local meta arch_in_package name_in_package package_version
    meta="$(bash "$ROOT/scripts/latest-release.sh" "$repo" "$asset")"
    IFS=$'\t' read -r tag url digest <<< "$meta"
    [[ -n "$tag" && -n "$url" && -n "$digest" ]] || { echo "[FAIL] Bad release metadata for $package" >&2; return 1; }
    version="${tag#v}"
    installed="$(dpkg-query -W -f='${Version}' "$package" 2>/dev/null || true)"
    if [[ "$installed" == "$version" || "$installed" == "$version"-* || "$installed" == "$version"+* ]]; then
        echo "[OK] $package $installed: official stable $tag already installed"
        return 0
    fi
    if [[ -n "$installed" ]] && dpkg --compare-versions "$installed" gt "$version"; then
        echo "[FAIL] Installed $package $installed is newer than upstream $version; refusing downgrade" >&2
        return 1
    fi
    file="$work/$asset"
    echo "==> Downloading $package $tag from $repo"
    curl --proto '=https' --tlsv1.2 -fL --retry 3 --connect-timeout 15 "$url" -o "$file"
    printf '%s  %s\n' "$digest" "$file" | sha256sum -c -
    name_in_package="$(dpkg-deb -f "$file" Package)"
    package_version="$(dpkg-deb -f "$file" Version)"
    arch_in_package="$(dpkg-deb -f "$file" Architecture)"
    [[ "$name_in_package" == "$package" && "$arch_in_package" == "$arch" ]] || {
        echo "[FAIL] Wrong package name/architecture in $asset: $name_in_package $arch_in_package" >&2; return 1;
    }
    [[ "$package_version" == "$version" || "$package_version" == "$version"-* || "$package_version" == "$version"+* ]] || {
        echo "[FAIL] $package version $package_version does not match upstream $tag" >&2; return 1;
    }
    # Simulate before privileged installation; forbid package removals.
    apt-get -s --no-remove install "$file" >/dev/null || {
        echo "[FAIL] APT simulation rejected $package (dependencies or removals)" >&2; return 1;
    }
    sudo apt-get install -y --no-remove --no-install-recommends "$file"
    installed="$(dpkg-query -W -f='${Version}' "$package" 2>/dev/null || true)"
    [[ "$installed" == "$package_version" ]] || {
        echo "[FAIL] $package version verification failed: installed=$installed expected=$package_version" >&2; return 1;
    }
    echo "[OK] Installed $package $installed via checksum-verified official .deb"
}

install_official_deb GyulyVGC/sniffnet "Sniffnet_LinuxDEB_${arch}.deb" sniffnet
install_official_deb domcyrus/rustnet "Rustnet_LinuxDEB_${arch}.deb" rustnet-monitor

verify_one sniffnet sniffnet
verify_one rustnet-monitor rustnet

if [[ "$ACTION" == update ]]; then
    bash "$ROOT/scripts/netalertx.sh" update
else
    bash "$ROOT/scripts/netalertx.sh" up
fi
echo '[OK] Network monitoring profile applied. See docs/network-monitoring.md for access and scanning setup.'
