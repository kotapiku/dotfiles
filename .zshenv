export MALLOC_CHECK_=0
export PYTHONPATH="$HOME/Library/Python/3.7/lib/python/site-packages"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cache:$PATH"

export XDG_CONFIG_HOME=~/.config  # for neovim

# for fzf
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
export FZF_DEFAULT_OPTS='--preview "bat --color=always --style=header, --height 40% --reverse --border'

#envのpathの重複自動削除
export PATH=`echo $PATH | tr ':' '\n' | sort -u | paste -d: -s -`;
