# Zplug
if [ -e "${HOME}/.zplug" ]; then
	source ~/.zplug/init.zsh
	zplug "zsh-users/zsh-completions"
	zplug "b4b4r07/enhancd", use:enhancd.sh
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


# Character encoding
export LANG=ja_JP.UTF-8

# Color
autoload -Uz colors
colors

# History
HISTFILE=~/.zsh_history
HISTSIZE=100000    #メモリ上に保存される件数
SAVEHIST=100000    #ファイルに保存される件数
setopt hist_ignore_dups    #重複した履歴を保存しない
setopt hist_ignore_space    #半角スペースを入れたコマンドは履歴に残さない
setopt hist_ignore_all_dups    # 同じコマンドをヒストリに残さない
setopt hist_reduce_blanks    # ヒストリに保存するときに余分なスペースを削除する

# Prompt
PROMPT="%{${fg[green]}%}[%n@%m]%{${reset_color}%} %~
%# "

# Completion
autoload -Uz compinit
compinit

zstyle ':completion:*:default' menu select=2    #completion select
setopt print_eight_bit    #日本語ファイル名表示可能
setopt interactive_comments    #'#' 以降をコメントとして扱う
setopt auto_cd    #ディレクトリ名だけでcdする
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'    # 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*' ignore-parents parent pwd ..    # ../ の後は今いるディレクトリを補完しない

# vcs_info
autoload -Uz vcs_info
autoload -Uz add-zsh-hook

zstyle ':vcs_info:*' formats '%F{green}(%s)-[%b]%f'
zstyle ':vcs_info:*' actionformats '%F{red}(%s)-[%b|%a]%f'

function _update_vcs_info_msg() {
    LANG=en_US.UTF-8 vcs_info
    RPROMPT="${vcs_info_msg_0_}"
}
add-zsh-hook precmd _update_vcs_info_msg


setopt no_beep    # beep を無効にする
setopt no_flow_control    # フローコントロールを無効にする
setopt ignore_eof    # Ctrl+Dでzshを終了しない
setopt auto_pushd    # cd したら自動的にpushdする
setopt pushd_ignore_dups    # 重複したディレクトリを追加しない
setopt extended_glob    # 高機能なワイルドカード展開を使用する

bindkey -v

# History search
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^n" history-beginning-search-forward-end

# Alias
alias la='ls -a'    #ファイル全表示
alias ll='ls -l'    #詳細表示
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'
alias vi='nvim'
alias -s py=python
alias -s cpp=g++ -Wall -o 
alias ctags="`brew --prefix`/bin/ctags"
alias sudo='sudo '    # sudo の後のコマンドでエイリアスを有効にする

# Global alias
alias -g L='| less'    #閲覧
alias -g G='| grep'    #検索

export CLICOLOR=1
alias ls='ls -G -F'

# vi mode
bindkey -M viins 'jk' vi-cmd-mode

#pathの追加・削除のための関数
path_append ()  { path_remove $1; export PATH="$PATH:$1"; }
path_prepend () { path_remove $1; export PATH="$1:$PATH"; }
path_remove ()  { export PATH=`echo -n $PATH | awk -v RS=: -v ORS=: '$0 != "'$1'"' | sed 's/:$//'`; }

# Export
if type pyenv > /dev/null 2>&1; then
        eval "$(pyenv init -)"
fi
export PYENV_ROOT="$HOME/.pyenv/shims"
export PATH="$PYENV_ROOT/versions/3.6.4/bin:$PATH"
export PATH="$HOME/Dropbox:$PATH"
export PATH="/usr/local/bin:$PATH"
export XDG_CONFIG_HOME=~/.config
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/dev/egison/.cabal-sandbox/bin:$PATH"
export PATH="$HOME/.cache:$PATH"

#brewとpyenvの共存のため
alias brew="env PATH=${PATH/\/Users\/kotapiku\/\.pyenv\/shims:/} brew"
#envのpathの重複自動削除
export PATH=`echo $PATH | tr ':' '\n' | sort -u | paste -d: -s -`;

#再起動
alias relogin='exec $SHELL -l'
