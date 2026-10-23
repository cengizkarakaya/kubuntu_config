#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# Strict audit: current configured stable repositories only. This does NOT
# claim Debian/Ubuntu package versions equal every developer's upstream release.
failures=0
check() { echo "[OK] $*"; }
problem() { echo "[FAIL] $*" >&2; ((failures+=1)); }
while IFS= read -r pkg; do
  [[ -n "$pkg" && "$pkg" != \#* ]] || continue
  installed="$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || true)"
  candidate="$(apt-cache policy "$pkg" 2>/dev/null | awk '$1=="Candidate:" {print $2;exit}')"
  if [[ -z "$installed" || -z "$candidate" || "$candidate" == "(none)" ]]; then
    problem "APT $pkg version could not be resolved"
  elif dpkg --compare-versions "$installed" lt "$candidate"; then
    problem "APT $pkg: installed $installed is older than current repository candidate $candidate"
  else
    check "APT $pkg: $installed (candidate $candidate)"
  fi
done < <(sed 's/#.*$//;s/^[[:space:]]*//;s/[[:space:]]*$//;/^$/d' "$ROOT/packages/apt.txt")
for pkg in brave-browser code; do
  installed="$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || true)"
  candidate="$(apt-cache policy "$pkg" 2>/dev/null | awk '$1=="Candidate:" {print $2;exit}')"
  if [[ -z "$installed" || -z "$candidate" || "$candidate" == "(none)" ]]; then
    problem "$pkg signed APT version could not be resolved"
  elif dpkg --compare-versions "$installed" lt "$candidate"; then
    problem "$pkg installed $installed is older than candidate $candidate"
  else check "$pkg installed $installed (candidate $candidate)"; fi
done
while IFS=$'\t' read -r app name; do
  [[ -n "$app" && "$app" != \#* ]] || continue
  local_sha="$(flatpak info --user --show-commit "$app" 2>/dev/null || true)"
  remote_sha="$(flatpak remote-info --user --show-commit flathub "$app" 2>/dev/null || true)"
  if [[ -n "$local_sha" && "$local_sha" == "$remote_sha" ]]; then
    check "Flathub $app: latest stable commit ${local_sha:0:12}"
  else problem "Flathub $app: installed commit differs from stable remote or remote unavailable"; fi
done < "$ROOT/packages/flatpak.tsv"
herdr_asset='herdr-linux-x86_64'
case "$(uname -m)" in aarch64|arm64) herdr_asset='herdr-linux-aarch64';; esac
for spec in "herdrdev/herdr $herdr_asset" 'zeroxoneafour/polonium polonium.kwinscript' 'ryanoasis/nerd-fonts FiraCode.tar.xz'; do
  read -r repo asset <<< "$spec"
  line="$(bash "$ROOT/scripts/latest-release.sh" "$repo" "$asset")" || {
    problem "GitHub stable release lookup failed: $repo"; continue;
  }
  IFS=$'\t' read -r tag url sha <<< "$line"
  case "$repo" in
    herdrdev/herdr)
      actual="$("$HOME/.local/bin/herdr" --version 2>/dev/null || true)"
      [[ "$actual" == "herdr ${tag#v}" ]] && check "Herdr $actual latest stable" || problem "Herdr $actual differs from GitHub $tag"
      ;;
    zeroxoneafour/polonium)
      metadata="${XDG_DATA_HOME:-$HOME/.local/share}/kwin/scripts/polonium/metadata.json"
      if [[ "${KUBUNTU_SKIP_PLASMA:-0}" == 1 ]]; then
        echo "[SKIP] Polonium version not checked (explicit --skip-plasma)"
      elif [[ -f "$metadata" ]] &&
        python3 - "$metadata" "${tag#v}" <<'PY'
import json,sys
with open(sys.argv[1],encoding="utf-8") as f: x=json.load(f)
assert x.get("KPlugin",{}).get("Id")=="polonium" and x["KPlugin"].get("Version")==sys.argv[2]
PY
      then check "Polonium $tag latest stable"
      else problem "Polonium metadata version differs from GitHub $tag"; fi
      ;;
    ryanoasis/nerd-fonts)
      stamp="$HOME/.local/share/fonts/FiraCodeNerd/.kubuntu-config-version"
      [[ "$(cat "$stamp" 2>/dev/null || true)" == "$tag" ]] &&
        check "FiraCode Nerd Font $tag latest stable" ||
        problem "FiraCode Nerd Font installed revision older/untracked than $tag"
      ;;
  esac
done
# Extra official stable binary releases on Kubuntu 26.10.
case "$(uname -m)" in
  x86_64|amd64) arch=x86_64 ;;
  aarch64|arm64) arch=aarch64 ;;
  *) arch=''; problem 'Unsupported architecture for Helix/Bottom version audit' ;;
esac
if [[ -n "$arch" ]]; then
  tag="$(bash "$ROOT/scripts/latest-release.sh" helix-editor/helix "helix-{tag}-$arch-linux.tar.xz" | cut -f1)" || {
    problem 'Helix stable release lookup failed'; tag='';
  }
  if [[ -n "$tag" ]]; then
    current="$("$HOME/.local/bin/hx" --version 2>/dev/null || true)"
    if [[ "$current" == *"$tag"* && -d "$HOME/.config/helix/runtime" ]]; then
      check "Helix $tag and runtime"
    else
      problem "Helix installed version/runtime differs from official stable $tag"
    fi
  fi
  tag="$(bash "$ROOT/scripts/latest-release.sh" ClementTsang/bottom "bottom_$arch-unknown-linux-gnu.tar.gz" | cut -f1)" || {
    problem 'Bottom stable release lookup failed'; tag='';
  }
  if [[ -n "$tag" ]]; then
    current="$("$HOME/.local/bin/btm" --version 2>/dev/null || true)"
    if [[ "$current" == *"$tag"* ]]; then
      check "Bottom $tag current"
    else
      problem "Bottom version differs from official stable $tag"
    fi
  fi
fi
if ((failures)); then
  echo "[FAIL] $failures version mismatches. Stable releases can change while bootstrap runs." >&2
  exit 1
fi
echo '[OK] All configured install channels match their latest stable versions.'
echo '[INFO] Upstream-vs-Ubuntu package age is not guaranteed; use release/vendor verification before changing channels.'
