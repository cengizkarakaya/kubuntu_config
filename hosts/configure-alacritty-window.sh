#!/usr/bin/env bash
set -Eeuo pipefail

# Explicit native KWin placement. No default host coordinates or rule ID.
# Run only after reviewing the monitor layout in KDE System Settings.
if [[ "${1:-}" == --help ]]; then
  echo 'Usage: bash hosts/configure-alacritty-window.sh --apply RULE_UUID X,Y WIDTH,HEIGHT'
  exit 0
fi
if [[ $# != 4 || "${1:-}" != --apply ]]; then
  echo 'Usage: bash hosts/configure-alacritty-window.sh --apply RULE_UUID X,Y WIDTH,HEIGHT' >&2
  exit 2
fi
rule_id="$2"
position="$3"
size="$4"
if [[ ! "$rule_id" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ||
      ! "$position" =~ ^-?[0-9]{1,6},-?[0-9]{1,6}$ ||
      ! "$size" =~ ^[1-9][0-9]{0,5},[1-9][0-9]{0,5}$ ]]; then
  echo '[FAIL] Invalid UUID, position or positive window size.' >&2
  exit 2
fi
(( EUID != 0 )) || { echo '[FAIL] Run as the desktop user, not root' >&2; exit 2; }
for cmd in kreadconfig6 kwriteconfig6; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "[FAIL] Missing: $cmd" >&2; exit 1; }
done

config="${XDG_CONFIG_HOME:-$HOME/.config}/kwinrulesrc"
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
  'Alacritty initial placement' 'Alacritty' 1 false 1
  "$position" 3 "$size" 3 true 2
)
changed=0
for i in "${!keys[@]}"; do
  if [[ "$(readkey "$rule_id" "${keys[$i]}")" != "${values[$i]}" ]]; then
    changed=1
  fi
done
[[ "$current_rules" == "$new_rules" && "$current_count" == "$new_count" ]] || changed=1

if (( ! changed )); then
  echo '[OK] Alacritty window rule already matches the saved layout'
  exit 0
fi

umask 077
backup_dir="${XDG_STATE_HOME:-$HOME/.local/state}/kubuntu-config/backups"
mkdir -p "$backup_dir" "$(dirname -- "$config")"
if [[ -f "$config" ]]; then
  backup="$backup_dir/kwinrulesrc-before-alacritty-$(date +%Y%m%d-%H%M%S)-$$.bak"
  cp -- "$config" "$backup"
  chmod 600 "$backup"
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
printf '[OK] Alacritty initial layout saved: %s / %s\n' "$position" "$size"
echo '[INFO] This is Apply Initially, not dynamic last-position memory'
