export PATH="$HOME/.cache:$PATH"  # for dein
export XDG_CONFIG_HOME=~/.config  # for neovim
export EDITOR=/opt/homebrew/bin/nvim # for crontab
export PATH="/opt/homebrew/bin:$PATH" # for brew

# for fzf
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
export FZF_DEFAULT_OPTS="--ansi --preview-window 'right:60%' --preview 'if [[ -d {} ]]; then tree -C -L 3 {}; else bat --color=always --style=header,grid --line-range :300 {}; fi' --height 40% --reverse --border --cycle"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="$FZF_DEFAULT_OPTS"

# for git-fuzzy
export PATH="$HOME/dev/git-fuzzy/bin:$PATH"

# for haskell (ghcup)
[ -f "/Users/kotapiku/.ghcup/env" ] && source "/Users/kotapiku/.ghcup/env" # ghcup-env

#envのpathの重複自動削除
export PATH=`echo $PATH | tr ':' '\n' | sort -u | paste -d: -s -`;

# for poetry
export PATH="$HOME/.poetry/bin:$PATH"
. "$HOME/.cargo/env"
