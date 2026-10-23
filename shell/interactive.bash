# Portable Arch shell preferences, without overwriting Ubuntu .bashrc.
case "$-" in *i*) ;; *) return ;; esac
export EDITOR=hx VISUAL=hx SUDO_EDITOR=hx PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
HISTSIZE=10000 HISTFILESIZE=20000 HISTCONTROL=erasedups:ignorespace
HISTTIMEFORMAT='%F %T '
shopt -s histappend cmdhist
alias grep='grep --color=auto'
if command -v eza >/dev/null; then
  alias ls='eza --icons=auto --group-directories-first'
  alias ll='eza -lah --icons=auto --group-directories-first --git'
  alias la='eza -a --icons=auto --group-directories-first'
  alias lt='eza --tree --level=2 --icons=auto --group-directories-first'
  alias tree='eza --tree --icons=auto --group-directories-first'
fi
command -v zoxide >/dev/null && eval "$(zoxide init bash)"
export FZF_DEFAULT_OPTS="\
--height=40% \
--layout=reverse \
--border=rounded \
--info=inline \
--prompt='  ' \
--pointer='❯' \
--marker='✓' \
--color=bg:#20242c,bg+:#434c5e,fg:#d8dee9,fg+:#eceff4 \
--color=hl:#88c0d0,hl+:#8fbcbb \
--color=info:#81a1c1,prompt:#88c0d0,pointer:#a3be8c \
--color=marker:#b48ead,spinner:#81a1c1,header:#5e81ac \
--color=border:#4c566a,gutter:#20242c"
command -v fzf >/dev/null && eval "$(fzf --bash 2>/dev/null)" || true
command -v starship >/dev/null && eval "$(starship init bash)"
command -v hx >/dev/null || alias hx='helix'
y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return
  yazi "$@" --cwd-file="$tmp"
  cwd="$(cat "$tmp")"; rm -f -- "$tmp"
  [[ -d "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd" || true
}
yc() { y "$@"; }
