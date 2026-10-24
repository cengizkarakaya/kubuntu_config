#!/usr/bin/env bash
set -Eeuo pipefail

# Home-desktop-specific native KWin window rule. Opt-in only:
#    bash hosts/configure-alacritty-lg.sh
# Keep other KWin rules, global shortcuts, KScreen monitor layout, and theme.
# Geometry assumes Samsung 2560x1440 left, LG 3440x1440 right.
(( EUID != 0 )) || { echo '[FAIL] Run as the desktop user, not root' >&2; exit 2; }
for cmd in kreadconfig6 kwriteconfig6; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "[FAIL] Missing: $cmd" >&2; exit 1; }
done

config="${XDG_CONFIG_HOME:-$HOME/.config}/kwinrulesrc"
rule_id='6a0f76f7-a826-4eef-a335-97d1c23633ba'
readkey() {
  kreadconfig6 --file "$config" --group "$1" --key "$2" 2>/dev/null || true
}
current_class="$(readkey "$rule_id" wmclass)"
if [[ -n "$current_class" && "${current_class,,}" != alacritty ]]; then
  echo "[FAIL] Rule ID $rule_id is used by another application ($current_class)" >&2
  exit 1
fi

current_rules="$(readkey General rules)"
current_count="$(readkey General count)"
if [[ -z "$current_rules" && -n "$current_count" && "$current_count" != 0 ]]; then
  echo '[FAIL] Existing rules count is nonzero but General/rules is empty; review manually' >&2
  exit 1
fi
IFS=',' read -r -a ids <<< "$current_rules"
rules=()
found=0
for id in "${ids[@]}"; do
  id="${id//[[:space:]]/}"
  [[ -n "$id" ]] || continue
  rules+=("$id")
  [[ "$id" == "$rule_id" ]] && found=1
done
if (( ! found )); then
  rules+=("$rule_id")
fi
# Avoid touching other KWin rules and keep their order unchanged.
new_rules="$(IFS=,; echo "${rules[*]}")"
new_count="${#rules[@]}"

keys=(
  Description wmclass wmclassmatch wmclasscomplete types
  position positionrule size sizerule ignoregeometry ignoregeometryrule
)
values=(
  'Alacritty LG' 'Alacritty' 1 false 1
  '2600,40' 3 '1732,1260' 3 true 2
)
changed=0
for i in "${!keys[@]}"; do
  if [[ "$(readkey "$rule_id" "${keys[$i]}")" != "${values[$i]}" ]]; then
    changed=1
  fi
done
[[ "$current_rules" == "$new_rules" && "$current_count" == "$new_count" ]] || changed=1

if (( ! changed )); then
  echo '[OK] Alacritty LG window rule already matches the saved layout'
  exit 0
fi

backup_dir="$HOME/.local/state/kubuntu-config/backups"
mkdir -p "$backup_dir" "$(dirname -- "$config")"
if [[ -f "$config" ]]; then
  backup="$backup_dir/kwinrulesrc-before-alacritty-lg-$(date +%Y%m%d-%H%M%S)-$$.bak"
  cp -p -- "$config" "$backup"
  echo "[INFO] Backed up current rules: $backup"
fi
for i in "${!keys[@]}"; do
  kwriteconfig6 --file "$config" --group "$rule_id" --key "${keys[$i]}" "${values[$i]}"
done
kwriteconfig6 --file "$config" --group General --key rules "$new_rules"
kwriteconfig6 --file "$config" --group General --key count "$new_count"

for i in "${!keys[@]}"; do
  [[ "$(readkey "$rule_id" "${keys[$i]}")" == "${values[$i]}" ]] || {
    echo "[FAIL] Cannot verify window rule key: ${keys[$i]}" >&2; exit 1;
  }
done
[[ "$(readkey General rules)" == "$new_rules" && "$(readkey General count)" == "$new_count" ]] || {
  echo '[FAIL] Cannot verify KWin rules index' >&2; exit 1;
}

if command -v qdbus6 >/dev/null 2>&1; then
  qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 ||
    echo '[WARN] Live KWin reload unavailable; re-login if needed'
else
  echo '[INFO] Re-login if KWin does not pick up the new rule'
fi
echo '[OK] Alacritty LG initial layout saved: (2600,40) / 1732x1260'
echo '[INFO] This is Apply Initially, not dynamic last-position memory'
