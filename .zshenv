# XDG
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Editor
export EDITOR="nvim"

# Homebrew (preserve an existing prefix, otherwise detect the installation).
if [[ -z "${HOMEBREW_PREFIX:-}" ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    export HOMEBREW_PREFIX="/opt/homebrew"
  elif [[ -x /usr/local/bin/brew ]]; then
    export HOMEBREW_PREFIX="/usr/local"
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
  fi
fi

# PATH (zsh配列で管理 + 重複削除)
typeset -U path PATH

path=(
  "$HOME/.cache"              # dein
  "$HOME/go/bin"              # golang
  "$HOME/dev/git-fuzzy/bin"
  "$HOME/.poetry/bin"
  $path
)
if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" $path)
fi

# fzf
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'

export FZF_DEFAULT_OPTS="\
--ansi \
--height 40% \
--reverse \
--border \
--cycle \
--preview-window 'right:60%' \
--preview 'if [[ -d {} ]]; then eza -T -L 2 -a --icons --group-directories-first {}; else bat --color=always --style=header,grid --line-range :300 {}; fi'"

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="$FZF_DEFAULT_OPTS"

# pager
export PAGER=less
export LESS='-R'
