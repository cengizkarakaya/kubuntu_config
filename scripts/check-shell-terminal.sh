#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
PASS=0; WARN=0; FAIL=0
ok()   { printf 'PASS  %-24s %s\n' "$1" "$2"; ((PASS+=1)); }
warn() { printf 'WARN  %-24s %s\n' "$1" "$2"; ((WARN+=1)); }
fail() { printf 'FAIL  %-24s %s\n' "$1" "$2"; ((FAIL+=1)); }
hook='[ -r "$HOME/.config/kubuntu-config/interactive.bash" ] && source "$HOME/.config/kubuntu-config/interactive.bash"'
rc="$HOME/.bashrc"
source_file="$HOME/.config/kubuntu-config/interactive.bash"
echo '=== Bash, eza, zoxide and Alacritty: read-only checks ==='
if [[ -f "$rc" && "$(grep -Fxc -- "$hook" "$rc" || true)" == 1 ]]; then
  ok bashrc 'Repository integration sourced exactly once'
else
  fail bashrc 'Integration absent or duplicated; run bash scripts/setup-shell.sh'
fi
if [[ -r "$source_file" ]] && cmp -s "$ROOT/shell/interactive.bash" "$source_file"; then
  ok bashrc 'Installed shell integration matches the current repository'
else
  fail bashrc 'Shell integration is outdated; run bash scripts/setup-shell.sh'
fi
for cmd in eza zoxide fzf starship alacritty; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok command "$cmd present"
  else
    fail command "$cmd missing"
  fi
done
if [[ -f "$rc" ]]; then
  if bash --noprofile --rcfile "$rc" -ic '
    for name in ls ll la lt tree; do alias "$name" >/dev/null || exit 11; done
    [[ "$(type -t z)" == function && "$(type -t zi)" == function ]] || exit 12
    [[ "$EDITOR" == hx && "$VISUAL" == hx && "$SUDO_EDITOR" == hx ]] || exit 13
    [[ "$PATH" == *"$HOME/.local/bin"* && "$PATH" == *"$HOME/.cargo/bin"* ]] || exit 14
    [[ "$FZF_DEFAULT_OPTS" == *"--info=inline"* ]] || exit 15
    shopt -q histappend && shopt -q cmdhist || exit 16
  ' >/dev/null 2>&1; then
    ok bash 'Interactive .bashrc loads eza aliases, zoxide z/zi and full fzf options'
  else
    fail bash 'Interactive Bash test failed; check .bashrc or zoxide initialization'
  fi
fi
conf="$HOME/.config/alacritty/alacritty.toml"
ref="$ROOT/dotfiles/alacritty/.config/alacritty/alacritty.toml"
if [[ -L "$conf" && "$(readlink -f "$conf")" == "$(readlink -f "$ref")" ]]; then
  ok alacritty 'Nord configuration linked to repository'
else
  fail alacritty 'TOML config not Stow-linked to repository'
fi
if command -v python3 >/dev/null 2>&1 &&
  python3 - "$conf" <<'PY'
import sys, tomllib
with open(sys.argv[1], "rb") as fh:
    d = tomllib.load(fh)
assert d["font"]["normal"]["family"] == "FiraCode Nerd Font Mono"
assert d["colors"]["primary"]["background"] == "#20242C"
assert d["cursor"]["style"]["shape"] == "Beam"
assert d["window"]["decorations"] == "None"
PY
then
  ok alacritty 'Valid TOML with Arch Nord colors, font and cursor'
else
  fail alacritty 'Invalid TOML or expected Arch Nord settings missing'
fi
if command -v fc-match >/dev/null 2>&1 &&
  [[ "$(fc-match -f '%{family}' 'FiraCode Nerd Font Mono' 2>/dev/null)" == *"FiraCode Nerd Font"* ]]; then
  ok font 'FiraCode Nerd Font Mono available in fontconfig'
else
  fail font 'Nerd Font Mono not resolved by fontconfig'
fi
launcher="$HOME/.local/share/applications/kubuntu-alacritty.desktop"
if [[ -r "$launcher" ]] &&
  grep -Fxq 'Exec=alacritty' "$launcher" &&
  grep -Fxq 'X-KDE-GlobalAccel-CommandShortcut=true' "$launcher"; then
  ok launcher 'Kubuntu Alacritty application shortcut launcher exists'
else
  fail launcher 'Alacritty launcher absent; run bash plasma/shortcuts.sh'
fi
if command -v kreadconfig6 >/dev/null 2>&1; then
  mapping="$(kreadconfig6 --file kglobalshortcutsrc --group services --group kubuntu-alacritty.desktop --key _launch 2>/dev/null || true)"
  if [[ "$mapping" == Meta+Return,* ]]; then
    ok shortcut 'KDE config requests Meta+Return'
  else
    warn shortcut 'Meta+Return not stored for Alacritty; bind in KDE System Settings'
  fi
fi
warn shortcut 'Live Wayland global shortcut requires physical Meta+Enter test'
printf '\nSUMMARY PASS=%d WARN=%d FAIL=%d\n' "$PASS" "$WARN" "$FAIL"
((FAIL==0))
