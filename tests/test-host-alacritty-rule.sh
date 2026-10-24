#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/bin" "$work/home/.config"
export HOME="$work/home"
export XDG_CONFIG_HOME="$HOME/.config"
cat > "$work/bin/kconfig_mock" <<'PY'
#!/usr/bin/env python3
import configparser
import os
import sys

args = sys.argv[1:]
def arg(name):
    index = args.index(name)
    return args[index + 1]

path = arg("--file")
group = arg("--group")
key = arg("--key")
conf = configparser.ConfigParser(interpolation=None)
conf.optionxform = str
conf.read(path, encoding="utf-8")
if os.path.basename(sys.argv[0]) == "kreadconfig6":
    print(conf.get(group, key, fallback=""))
else:
    value = args[args.index("--key") + 2]
    if not conf.has_section(group):
        conf.add_section(group)
    conf.set(group, key, value)
    with open(path, "w", encoding="utf-8") as fp:
        conf.write(fp)
PY
chmod +x "$work/bin/kconfig_mock"
ln -s kconfig_mock "$work/bin/kreadconfig6"
ln -s kconfig_mock "$work/bin/kwriteconfig6"
cat > "$work/bin/qdbus6" <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod +x "$work/bin/qdbus6"
export PATH="$work/bin:$PATH"

cat > "$XDG_CONFIG_HOME/kwinrulesrc" <<'INI'
[unrelated]
Description=Other Window
wmclass=Firefox

[General]
count=1
rules=unrelated
INI

bash "$ROOT/hosts/configure-alacritty-lg.sh"
config="$XDG_CONFIG_HOME/kwinrulesrc"
grep -Eq '^rules[[:space:]]*=[[:space:]]*unrelated,6a0f76f7-a826-4eef-a335-97d1c23633ba
grep -Eq '^count[[:space:]]*=[[:space:]]*2
grep -Eq '^position[[:space:]]*=[[:space:]]*2600,40
grep -Eq '^size[[:space:]]*=[[:space:]]*1732,1260
grep -Eq '^wmclass[[:space:]]*=[[:space:]]*Firefox

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -Eq '^count[[:space:]]*=[[:space:]]*1
grep -Eq '^rules[[:space:]]*=[[:space:]]*6a0f76f7-a826-4eef-a335-97d1c23633ba

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
 "$config"
grep -qx 'count=2' "$config"
grep -qx 'position=2600,40' "$config"
grep -qx 'size=1732,1260' "$config"
grep -qx 'wmclass=Firefox' "$config"

before="$(sha256sum "$config" | cut -d' ' -f1)"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
after="$(sha256sum "$config" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || {
  echo '[FAIL] Re-running rule script changed config' >&2
  exit 1
}

export HOME="$work/fresh"
export XDG_CONFIG_HOME="$HOME/.config"
bash "$ROOT/hosts/configure-alacritty-lg.sh"
fresh="$XDG_CONFIG_HOME/kwinrulesrc"
grep -qx 'count=1' "$fresh"
grep -qx 'rules=6a0f76f7-a826-4eef-a335-97d1c23633ba' "$fresh"

echo '[PASS] Alacritty LG rule is idempotent and preserves unrelated KWin rules'
