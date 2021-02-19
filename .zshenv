# export PYTHONPATH="/usr/local/lib/python3.9/site-packages"
export PATH="$HOME/.cache:$PATH"  # for dein
export XDG_CONFIG_HOME=~/.config  # for neovim

# for fzf
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
export FZF_DEFAULT_OPTS="--ansi --preview-window 'right:60%' --preview 'if [[ -d {} ]]; then tree -C -L 3 {}; else bat --color=always --style=header,grid --line-range :300 {}; fi' --height 40% --reverse --border --cycle"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="$FZF_DEFAULT_OPTS"

# for git-fuzzy
export PATH="$HOME/dev/git-fuzzy/bin:$PATH"

#envのpathの重複自動削除
export PATH=`echo $PATH | tr ':' '\n' | sort -u | paste -d: -s -`;
