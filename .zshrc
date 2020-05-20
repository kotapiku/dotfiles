# Zplug
export ZPLUG_HOME=/usr/local/opt/zplug
source $ZPLUG_HOME/init.zsh

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

# Zplug setting
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

autoload -Uz vcs_info
autoload -Uz add-zsh-hook

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{red}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{red}+"
zstyle ':vcs_info:*' formats '%F{253}%c%u%b%f'
zstyle ':vcs_info:*' actionformats '%F{red}%b|%a%f'

function _update_vcs_info_msg() {
    LANG=en_US.UTF-8 vcs_info
    if [ -z ${vcs_info_msg_0_} ]; then
        PROMPT=$'\n%F{159} %~ %F{159}> '
    else
        PROMPT=$'\n%F{159} %~ '"${vcs_info_msg_0_} %F{159}> "
    fi
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
alias cat='bat'
function mkcd () { mkdir -p $1 && cd $1 }

alias ocaml="rlwrap ocaml"  # ocamlでカーソル有効
alias vi='nvim'
alias fvi='{ tmp=$(fzf); if [ "$tmp" = "" ]; then return 1; else nvim $tmp; fi }'  # fzfでファイルを探して開く

alias -s py=python3
alias -s cpp=g++ -Wall -o

alias zshrc='nvim ~/.zshrc'
alias vimrc='nvim ~/.vimrc'
alias tmuxconf='nvim ~/.tmux.conf'
alias deintoml='nvim ~/dotfiles/.config/nvim/dein/toml/dein.toml'
alias deintoml_lazy='nvim ~/dotfiles/.config/nvim/dein/toml/dein_lazy.toml'

alias g='{ tmp=$(ghq list -p | fzf); if [ "$tmp" = "" ]; then return 1; else cd $tmp; fi }'
alias gh='hub browse $(ghq list | peco | cut -d "/" -f 2,3)'

function mktar () { tar cvzf $1.tar.gz $1 }

# for yugen
alias ip-add-yugen='curl ifconfig.me | xargs -I {} curl http://49.212.25.77/cgi-bin/ssh.cgi --data network={}'

# for atcoder
function oj-d () { rm -rf test && oj d https://beta.atcoder.jp/contests/$1/tasks/$1_$2 }
function oj-url-d () { rm -rf test && oj d $1 }

function ru () { rustc $1 -o a.out || return 1 ; oj test -i }

case ${OSTYPE} in
    darwin*)
        function fcp () { cat $1 | pbcopy }
        alias ctags="`brew --prefix`/bin/ctags"
        function git(){hub "$@"}
        alias noti='terminal-notifier -message "おわった！"'
        export PATH="/usr/local/bin:$PATH"  # for brew
        ;;
    linux*)
        alias fcp='(){cat $1 | xsel --clipboard --input}'
        alias noti='notify-send "おわった！"'
        export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"  # for brew
        #OPAM configuration
        . ~/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true
        ;;
esac

function extract() {
	case $1 in
		*.tar.gz|*.tgz) tar xzvf $1;;
		*.tar.xz) tar Jxvf $1;;
		# *.zip) unzip $1;;
		*.zip) unar $1;;
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

#再起動
alias relogin='exec $SHELL -l'
