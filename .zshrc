# Zplug
if [ -e "${HOME}/.zplug" ]; then
	source ~/.zplug/init.zsh
	zplug "zsh-users/zsh-completions"
	zplug "zsh-users/zsh-syntax-highlighting", defer:2
	zplug "zsh-users/zsh-autosuggestions"
	zplug "zsh-users/zsh-completions"
	zplug "zsh-users/zsh-history-substring-search"

	if ! zplug check --verbose; then
	    printf 'Install? [y/N]: '
        if read -q; then
		    echo; zplug install
		fi
	fi
	zplug load
fi

# zplug setting
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=30'

# Character encoding
export LANG=ja_JP.UTF-8

# History
HISTFILE=~/.zsh_history
HISTSIZE=100000    #メモリ上に保存される件数
SAVEHIST=100000    #ファイルに保存される件数
setopt hist_ignore_dups    #重複した履歴を保存しない
setopt hist_ignore_space    #半角スペースを入れたコマンドは履歴に残さない
setopt hist_ignore_all_dups    # 同じコマンドをヒストリに残さない
setopt hist_reduce_blanks    # ヒストリに保存するときに余分なスペースを削除する

# Color
autoload -Uz colors
colors

# Prompt
PROMPT="%{${fg[yellow]}%}[%n@%m]%{${reset_color}%} %~
%# "

autoload -Uz vcs_info
autoload -Uz add-zsh-hook

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{red}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{red}+"
zstyle ':vcs_info:*' formats '%F{yellow}%c%u[%b]%f'
zstyle ':vcs_info:*' actionformats '%F{red}[%b|%a]%f'

function _update_vcs_info_msg() {
    LANG=en_US.UTF-8 vcs_info
    RPROMPT="${vcs_info_msg_0_}"
}
add-zsh-hook precmd _update_vcs_info_msg

# Completion
autoload -Uz compinit
compinit

zstyle ':completion:*:default' menu select=2    #completion select
setopt print_eight_bit    #日本語ファイル名表示可能
setopt interactive_comments    #'#' 以降をコメントとして扱う
setopt auto_cd    #ディレクトリ名だけでcdする
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'    # 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*' ignore-parents parent pwd ..    # ../ の後は今いるディレクトリを補完しない


# Options
setopt no_beep    # beep を無効にする
setopt no_flow_control    # フローコントロールを無効にする
setopt ignore_eof    # Ctrl+Dでzshを終了しない
setopt auto_pushd    # cd したら自動的にpushdする
setopt pushd_ignore_dups    # 重複したディレクトリを追加しない
setopt extended_glob    # 高機能なワイルドカード展開を使用する

# Alias
alias cdd="cd .."
alias ls='ls -G -F' # 色付けして表示, 名前の末尾に記号(種類)を表示
alias la='ls -a'
alias ll='ls -l'
alias cp='cp -i'    # コピー先に同名のファイルが存在したとき確認
alias mv='mv -i'    # 上書き前に確認
alias mkdir='mkdir -p'
alias sudo='sudo '    # sudo の後のコマンドでエイリアスを有効にする
function mkcd () { mkdir -p $1 && cd $1 }

alias ocaml="rlwrap ocaml"  # ocamlでカーソル有効
alias vi='nvim'

alias -s py=python
alias -s cpp=g++ -Wall -o

alias zshrc='vi ~/.zshrc'
alias vimrc='vi ~/.vimrc'
alias tmuxrc='vi ~/.tmux.conf'
alias deintoml='vi ~/dotfiles/config/nvim/dein/toml/dein.toml'

alias g='cd $(ghq list -p | peco)'
alias gh='hub browse $(ghq list | peco | cut -d "/" -f 2,3)'
function git(){hub "$@"}

case ${OSTYPE} in
    darwin*)
        alias fcp='(){ cat $1 | pbcopy }'
        alias ctags="`brew --prefix`/bin/ctags"
        ;;
    linux*)
        alias fcp='(){cat $1 | xsel --clipboard --input}'
        #OPAM configuration
        . ~/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true
        ;;
esac

alias acedit="~/.pyenv/shims/versions/3.5.4/bin/acedit"

# extract
function extract() {
	case $1 in
		*.tar.gz|*.tgz) tar xzvf $1;;
		*.tar.xz) tar Jxvf $1;;
		*.zip) unzip $1;;
		*.lzh) lha e $1;;
		*.tar.bz2|*.tbz) tar xjvf $1;;
		*.tar.Z) tar zxvf $1;;
		*.gz) gzip -d $1;;
		*.bz2) bzip2 -dc $1;;
		*.Z) uncompress $1;;
		*.tar) tar xvf $1;;
		*.arj) unarj $1;;
	esac
}

# tmux
if [[ ! -n $TMUX && $- == *l* ]]; then
  # get the IDs
  ID="`tmux list-sessions`"
  if [[ -z "$ID" ]]; then
    tmux new-session
  fi
  create_new_session="Create New Session"
  ID="$ID\n${create_new_session}:"
  ID="`echo $ID | peco | cut -d: -f1`"
  if [[ "$ID" = "${create_new_session}" ]]; then
    tmux new-session
  elif [[ -n "$ID" ]]; then
    tmux attach-session -t "$ID"
  else
    :  # Start terminal normally
  fi
fi

# vi mode
bindkey -v
bindkey -M viins 'jk' vi-cmd-mode   # jkでvi-modeへ

#pathの追加・削除のための関数
path_append ()  { path_remove $1; export PATH="$PATH:$1"; }
path_prepend () { path_remove $1; export PATH="$1:$PATH"; }
path_remove ()  { export PATH=`echo -n $PATH | awk -v RS=: -v ORS=: '$0 != "'$1'"' | sed 's/:$//'`; }

# Export
if type pyenv > /dev/null 2>&1; then
        eval "$(pyenv init -)"
fi
export PATH="$PYENV_ROOT/shims:$PATH"
export PATH="$HOME/Dropbox:$PATH"
export XDG_CONFIG_HOME=~/.config
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cache:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PYENV_ROOT="$HOME/.pyenv/shims"
export PATH="/usr/local/bin:$PATH"

#brewとpyenvの共存のため
alias brew="env PATH=${PATH/\/Users\/kotapiku\/\.pyenv\/shims:/} brew"
#envのpathの重複自動削除
export PATH=`echo $PATH | tr ':' '\n' | sort -u | paste -d: -s -`;

#再起動
alias relogin='exec $SHELL -l'
