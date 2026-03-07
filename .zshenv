# XDG
export XDG_CONFIG_HOME="$HOME/.config"

# Editor
export EDITOR="/opt/homebrew/bin/nvim"

# PATH (zsh配列で管理 + 重複削除)
typeset -U path PATH

path=(
  "$HOME/.cache"              # dein
  "/opt/homebrew/bin"         # homebrew
  "$HOME/go/bin"              # golang
  "$HOME/dev/git-fuzzy/bin"
  "$HOME/.poetry/bin"
  $path
)

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

export HOMEBREW_PREFIX="/opt/homebrew"

# pager
export PAGER=less
export LESS='-R'
