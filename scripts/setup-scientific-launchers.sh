#!/usr/bin/env bash
# Scientific and engineering KDE Plasma launchers, user scope only.
# Usage: bash scripts/setup-scientific-launchers.sh --check | --install
set -euo pipefail

mode="${1:---check}"
if [[ "$mode" != --check && "$mode" != --install ]]; then
  printf 'Usage: bash %s --check | --install\n' "$0" >&2
  exit 2
fi

app_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
wrapper_dir="$HOME/.local/bin/kubuntu-science-launchers"
made=0 existing=0 missing=0

declare -a visible_desktops=()
for path in \
  "$app_dir" \
  /usr/local/share/applications \
  /usr/share/applications \
  "$HOME/.local/share/flatpak/exports/share/applications" \
  /var/lib/flatpak/exports/share/applications; do
  [[ -d "$path" ]] || continue
  for desktop in "$path"/*.desktop; do
    [[ -f "$desktop" ]] || continue
    # Include only desktop entries that are normally visible in the app menu.
    if grep -Eqi '^(Hidden|NoDisplay)=true[[:space:]]*$' "$desktop"; then
      continue
    fi
    visible_desktops+=("$desktop")
  done
done

# Compare entry Name / Exec / desktop filename to avoid creating duplicate entries.
existing_menu_entry() {
  local needle file content
  for needle in "$@"; do
    for file in "${visible_desktops[@]}"; do
      [[ "${file,,}" == *"${needle,,}"* ]] && return 0
      content="$(grep -E '^(Exec|Name|GenericName)=' "$file" 2>/dev/null || true)"
      [[ "${content,,}" == *"${needle,,}"* ]] && return 0
    done
  done
  return 1
}

binary() {
  local candidate
  for candidate in "$@"; do
    if [[ "$candidate" == */* ]]; then
      [[ -x "$candidate" && -f "$candidate" ]] && { printf '%s\n' "$candidate"; return 0; }
    elif command -v "$candidate" >/dev/null 2>&1; then
      command -v "$candidate"; return 0
    fi
  done
  return 1
}

# A launcher will only be created if no matching existing menu entry is found.
# Deliberately do not overwrite custom desktop files or existing wrappers.
add_launcher() {
  local id="$1" title="$2" icon="$3" terminal="$4" wrapper_body="$5"
  shift 5
  local target="$app_dir/kubuntu-science-${id}.desktop"
  local launcher="$wrapper_dir/${id}"
  local marker=""
  if [[ -f "$target" ]]; then
    printf 'MEVCUT (yönetilen): %-25s %s\n' "$title" "$target"
    ((existing+=1)); return 0
  fi
  if existing_menu_entry "$@"; then
    printf 'MEVCUT (sistem/Flatpak): %s\n' "$title"
    ((existing+=1)); return 0
  fi
  if [[ "$mode" == --check ]]; then
    printf 'EKLENECEK: %-25s %s\n' "$title" "$target"
    ((made+=1)); return 0
  fi

  mkdir -p "$app_dir" "$wrapper_dir"
  # Write the wrapper and .desktop file only if absent; never clobber user edits.
  if [[ ! -e "$launcher" ]]; then
    printf '#!/usr/bin/env bash\nset -e\n%s\n' "$wrapper_body" > "$launcher"
    chmod 755 "$launcher"
  fi
  cat > "$target" <<EOF
[Desktop Entry]
Type=Application
Name=$title
Comment=Bilimsel ve mühendislik uygulaması
Exec=$launcher
TryExec=$launcher
Icon=$icon
Terminal=$terminal
Categories=Science;
StartupNotify=true
X-Kubuntu-Science-Managed=true
EOF
  chmod 644 "$target"
  if command -v desktop-file-validate >/dev/null 2>&1; then
    desktop-file-validate "$target" || { printf 'Geçersiz desktop entry: %s\n' "$target" >&2; return 1; }
  fi
  visible_desktops+=("$target")
  printf 'OLUŞTURULDU: %-25s %s\n' "$title" "$target"
  ((made+=1))
}

skip_missing() { printf 'BULUNAMADI: %s (%s)\n' "$1" "$2"; ((missing+=1)); }

# launch_binary <id> <display title> <icon> <alternatives (semicolon-separated)> <menu-search strings...>
launch_binary() {
  local id="$1" title="$2" icon="$3" candidates="$4"
  shift 4
  local exe="" item="" body=""
  local -a alternatives=()
  IFS=';' read -r -a alternatives <<< "$candidates"
  if ! exe="$(binary "${alternatives[@]}")"; then
    skip_missing "$title" "$candidates"; return 0
  fi
  printf -v body 'exec %q "$@"' "$exe"
  add_launcher "$id" "$title" "$icon" false "$body" "$@"
}

printf '\nBilimsel KDE uygulama menüsü (%s)\n' "$mode"
printf 'Hedef: %s\n\n' "$app_dir"

launch_binary labplot 'LabPlot' labplot 'labplot2;labplot' 'labplot2' 'labplot'
launch_binary cantor 'Cantor' cantor 'cantor' 'cantor'
launch_binary paraview 'ParaView' paraview 'paraview' 'paraview'
launch_binary grc 'GNU Radio Companion' gnuradio 'gnuradio-companion;grc' 'gnuradio-companion' 'gnuradio.grc'
launch_binary qalculate 'Qalculate! Qt' qalculate-qt 'qalculate-qt;qalculate-gtk' 'qalculate-qt' 'qalculate-gtk'
launch_binary omedit 'OpenModelica - OMEdit' omedit 'OMEdit;/opt/openmodelica/bin/OMEdit' 'OMEdit' 'omedit'

# Flatpak normally exports a menu entry, but account for a missing export.
if command -v flatpak >/dev/null 2>&1 && flatpak info org.kde.kstars >/dev/null 2>&1; then
  add_launcher kstars 'KStars' org.kde.kstars false 'exec flatpak run org.kde.kstars "$@"' 'kstars'
else
  launch_binary kstars 'KStars' kstars 'kstars' 'kstars'
fi

# CalculiX graphical front-end, if installed.
launch_binary cgx 'CalculiX GraphiX (CGX)' applications-engineering 'cgx' 'cgx' 'CalculiX GraphiX'
# CalculiX solver is command-line-only: give it a dedicated interactive terminal.
if binary ccx ccx_2.21 ccx_2.22 >/dev/null 2>&1; then
  add_launcher calculix-terminal 'CalculiX (Terminal)' utilities-terminal true \
    $'printf "CalculiX solver ortamı. ccx komutunu kendi .inp dosyanızla çalıştırın.\\n"\nexec bash -i' \
    'CalculiX (Terminal)'
else
  skip_missing 'CalculiX terminal' 'ccx bulunamadı'
fi

# Webots official tarball can be unpacked outside PATH.
webots_path="$(binary webots || true)"
if [[ -z "$webots_path" ]]; then
  dirs=()
  for p in "$HOME/Workspaces/Scientific" "$HOME/.local/opt" "$HOME/Applications" "$HOME/opt"; do
    [[ -d "$p" ]] && dirs+=("$p")
  done
  if ((${#dirs[@]})); then
    webots_path="$(find "${dirs[@]}" -maxdepth 6 -type f -name webots -perm /111 -print -quit 2>/dev/null || true)"
  fi
fi
if [[ -n "$webots_path" ]]; then
  printf -v webots_body 'exec %q "$@"' "$webots_path"
  add_launcher webots 'Webots' applications-engineering false "$webots_body" 'webots'
else
  skip_missing 'Webots' 'webots çalıştırılabilir dosya yolu bulunamadı'
fi

# ElmerGUI needs ELMERGUI_HOME = the parent of edf/egini.xml.
elmer="$HOME/.local/opt/elmer-26.2.1"
if [[ -x "$elmer/bin/ElmerGUI" ]]; then
  add_launcher elmergui 'ElmerGUI (Elmer FEM)' applications-engineering false \
    $'ELMER_HOME="$HOME/.local/opt/elmer-26.2.1"\nini="$(find "$ELMER_HOME" -type f -path "*/edf/egini.xml" -print -quit)"\nif [[ -z "$ini" ]]; then echo "ElmerGUI: egini.xml yok" >&2; exit 1; fi\nexport ELMER_HOME ELMERGUI_HOME="${ini%/edf/egini.xml}"\nexport PATH="$ELMER_HOME/bin:$PATH"\nexport QT_QPA_PLATFORM=xcb\nexec "$ELMER_HOME/bin/ElmerGUI" "$@"' \
    'ElmerGUI' 'Elmer FEM'
else
  skip_missing 'ElmerGUI' "$elmer/bin/ElmerGUI"
fi

appcsxcad="$HOME/.local/opt/openEMS/bin/AppCSXCAD"
if [[ -x "$appcsxcad" ]]; then
  add_launcher appcsxcad 'AppCSXCAD (openEMS)' applications-engineering false \
    $'export QT_QPA_PLATFORM=xcb\nexec "$HOME/.local/opt/openEMS/bin/AppCSXCAD" "$@"' \
    'AppCSXCAD'
else
  skip_missing 'AppCSXCAD' "$appcsxcad"
fi

# SageMath / FEniCSx do not have stand-alone desktop GUIs.
# Terminal=true gives them interactive entry points in KDE Application Launcher.
conda_sh="$HOME/.local/opt/miniforge3/etc/profile.d/conda.sh"
if [[ -f "$conda_sh" && -x "$HOME/.local/opt/miniforge3/envs/sage/bin/sage" ]]; then
  add_launcher sage 'SageMath (Terminal)' utilities-terminal true \
    $'source "$HOME/.local/opt/miniforge3/etc/profile.d/conda.sh"\nconda activate sage\nexec sage' \
    'SageMath (Terminal)'
else
  skip_missing 'SageMath (Terminal)' 'sage ortamı veya conda.sh bulunamadı'
fi
if [[ -f "$conda_sh" && -x "$HOME/.local/opt/miniforge3/envs/fenicsx/bin/python" ]]; then
  add_launcher fenicsx 'FEniCSx (Python Terminal)' utilities-terminal true \
    $'source "$HOME/.local/opt/miniforge3/etc/profile.d/conda.sh"\nconda activate fenicsx\nexec python -i -c '\''import dolfinx; print("FEniCSx hazır. Python etkileşimli konsolundasınız.")'\''' \
    'FEniCSx (Python Terminal)'
else
  skip_missing 'FEniCSx (Python Terminal)' 'fenicsx ortamı veya conda.sh bulunamadı'
fi

if [[ -x "$HOME/.local/opt/openEMS/venv/bin/python" ]]; then
  add_launcher openems-python 'openEMS (Python Terminal)' utilities-terminal true \
    $'exec "$HOME/.local/opt/openEMS/venv/bin/python" -i -c '\''import openEMS, CSXCAD; print("openEMS Python ortamı hazır.")'\''' \
    'openEMS (Python Terminal)'
else
  skip_missing 'openEMS Python Terminal' 'venv/bin/python bulunamadı'
fi

if [[ "$mode" == --install ]]; then
  if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 --noincremental >/dev/null 2>&1 || printf 'UYARI: KDE menü önbelleği yenilenemedi.\n' >&2
  fi
fi
printf '\nÖzet: %s=%d, zaten menüde=%d, çalıştırılabilir bulunamadı=%d\n' \
  "$([[ "$mode" == --check ]] && printf 'eklenecek' || printf 'eklenen')" "$made" "$existing" "$missing"
