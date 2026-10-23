#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
temp="$(mktemp -d)"
trap 'rm -rf -- "$temp"' EXIT
export HOME="$temp/home"
mkdir -p "$HOME" "$temp/mock-bin"
cat > "$temp/mock-bin/zoxide" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == init && "${2:-}" == bash ]]; then
  cat <<'SH'
__zoxide_hook() { :; }
PROMPT_COMMAND="__zoxide_hook; ${PROMPT_COMMAND:-}"
z() { :; }
zi() { :; }
SH
fi
EOF
cat > "$temp/mock-bin/starship" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == init && "${2:-}" == bash ]]; then
  cat <<'SH'
starship_precmd() { :; }
PROMPT_COMMAND="starship_precmd"
SH
fi
EOF
for cmd in eza fzf; do
  printf '#!/usr/bin/env bash\nexit 0\n' > "$temp/mock-bin/$cmd"
done
chmod +x "$temp/mock-bin/"*
export PATH="$temp/mock-bin:$PATH"
bash "$ROOT/scripts/setup-shell.sh"
bash "$ROOT/scripts/setup-shell.sh"
hook='[ -r "$HOME/.config/kubuntu-config/interactive.bash" ] && source "$HOME/.config/kubuntu-config/interactive.bash"'
[[ "$(grep -Fxc -- "$hook" "$HOME/.bashrc")" == 1 ]]
cmp -s "$ROOT/shell/interactive.bash" "$HOME/.config/kubuntu-config/interactive.bash"
bash --noprofile --rcfile "$HOME/.bashrc" -ic '
  for name in ls ll la lt tree; do alias "$name" >/dev/null || exit 11; done
  [[ "$(type -t z)" == function && "$(type -t zi)" == function ]] || exit 12
  [[ "$EDITOR" == hx && "$VISUAL" == hx && "$SUDO_EDITOR" == hx ]] || exit 13
  [[ "$FZF_DEFAULT_OPTS" == *"--info=inline"* && "$FZF_DEFAULT_OPTS" == *"--prompt="* && "$FZF_DEFAULT_OPTS" == *"--pointer="* ]] || exit 14
  shopt -q histappend && shopt -q cmdhist || exit 15
  [[ "$(declare -p PROMPT_COMMAND)" == *"__zoxide_hook"* ]] || exit 16
' </dev/null
python3 - "$ROOT/dotfiles/alacritty/.config/alacritty/alacritty.toml" <<'PY'
import sys,tomllib
with open(sys.argv[1],"rb") as f: c=tomllib.load(f)
assert c["font"]["normal"]["family"] == "FiraCode Nerd Font Mono"
assert c["colors"]["primary"]["background"] == "#20242C"
assert c["cursor"]["style"]["shape"] == "Beam"
PY
echo '[PASS] Bash entry idempotent, eza aliases, zoxide hook survives Starship init, Nord fzf and Alacritty TOML'
